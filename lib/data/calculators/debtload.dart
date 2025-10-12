import 'dart:math' as math;
import '../models.dart';
import 'allocation.dart';
import 'liquidity.dart';
import '../../core/constants/scoring_constants.dart';
import '../../core/debug/debug_log.dart';

enum DebtLoadBand { red, yellow, green }

class DebtLoadResult {
  final double weightedApr;
  final double creditUtilization;
  final DebtLoadBand band;
  final String description;
  final List<Liability> highAprDebts;
  final double mortgageToNetWorthRatio;
  final double score; // Continuous score 0-100
  final double totalDebt;
  final double totalAssets;
  final double monthlyDebtService;
  final double leverageScore; // component from leverage
  final double dscrScore; // component from DSCR

  const DebtLoadResult({
    required this.weightedApr,
    required this.creditUtilization,
    required this.band,
    required this.description,
    required this.highAprDebts,
    required this.mortgageToNetWorthRatio,
    required this.score,
    required this.totalDebt,
    required this.totalAssets,
    required this.monthlyDebtService,
    required this.leverageScore,
    required this.dscrScore,
  });
}

class DebtLoadCalculator {
  // Holds last debug snapshot of internal debt scoring components (debug mode only)
  static Map<String, double>? lastDebug;
  static DebtLoadResult calculateDebtLoad(
    List<Account> accounts,
    List<Liability> liabilities,
    double monthlyEssentials,
    Settings settings,
  ) {
    // Filter out paid-off debts (balance = 0)
    final activeDebts = liabilities.where((debt) => debt.balance > 0).toList();

    final netWorth =
        AllocationCalculator.calculateNetWorth(accounts, liabilities);

    // Calculate total monthly debt payments
    final totalMonthlyDebtPayments = activeDebts.fold<double>(
      0.0,
      (sum, debt) => sum + debt.minPayment,
    );

    // Calculate DTI ratio with explicit income handling
    final income = settings.monthlyIncome ??
        monthlyEssentials * settings.incomeMultiplierFallback;
    final debtToIncomeRatio =
        income > 0 ? totalMonthlyDebtPayments / income : 0.0;

    // Calculate weighted average APR
    final weightedApr = _calculateWeightedApr(activeDebts);

    // Calculate credit utilization
    final creditUtilization = _calculateCreditUtilization(activeDebts);

    // Find high APR debts (> threshold)
    final highAprDebts = activeDebts
        .where((debt) => debt.apr > ScoringConstants.highAprThreshold)
        .toList();

    // Calculate mortgage to net worth ratio
    final mortgageToNetWorthRatio =
        _calculateMortgageToNetWorthRatio(activeDebts, netWorth);

    // Check liquidity for mortgage debt evaluation
    final liquidityResult = LiquidityCalculator.calculateLiquidity(
      accounts,
      monthlyEssentials,
      settings,
    );

    // Calculate continuous score using leverage and DSCR
    final assetsTotal = AllocationCalculator.calculateAssetsTotal(accounts);
    final totalDebt =
        activeDebts.fold<double>(0.0, (sum, debt) => sum + debt.balance);
    final leverageScoreVal = _newLeverageScore(totalDebt, assetsTotal);
    final dscrScoreVal = _newDscrScore(
      income,
      monthlyEssentials,
      totalMonthlyDebtPayments,
    );
    final score = _computeNewDebtScore(
      totalDebt: totalDebt,
      assets: assetsTotal,
      income: income,
      essentials: monthlyEssentials,
      monthlyDebtService: totalMonthlyDebtPayments,
      creditUtilization: creditUtilization,
      hasHighAprDebt: highAprDebts.isNotEmpty,
      mortgageToAssets: assetsTotal > 0
          ? _calculateMortgageBalance(activeDebts) / assetsTotal
          : 0.0,
      monthsOfEssentials: liquidityResult.monthsOfEssentials,
    );

    final band = _getBandWithDTI(
      debtToIncomeRatio,
      creditUtilization,
      highAprDebts.isNotEmpty,
      mortgageToNetWorthRatio,
      liquidityResult.monthsOfEssentials,
    );

    final description = _getDescription(
      weightedApr,
      creditUtilization,
      highAprDebts,
      mortgageToNetWorthRatio,
      liquidityResult.monthsOfEssentials,
      band,
    );

    return DebtLoadResult(
      weightedApr: weightedApr,
      creditUtilization: creditUtilization,
      band: band,
      description: description,
      highAprDebts: highAprDebts,
      mortgageToNetWorthRatio: mortgageToNetWorthRatio,
      score: score,
      totalDebt: totalDebt,
      totalAssets: assetsTotal,
      monthlyDebtService: totalMonthlyDebtPayments,
      leverageScore: leverageScoreVal,
      dscrScore: dscrScoreVal,
    );
  }

  static double _calculateWeightedApr(List<Liability> liabilities) {
    if (liabilities.isEmpty) return 0.0;

    double totalBalance = 0.0;
    double weightedAprSum = 0.0;

    for (final liability in liabilities) {
      totalBalance += liability.balance;
      weightedAprSum += liability.balance * liability.apr;
    }

    return totalBalance > 0 ? weightedAprSum / totalBalance : 0.0;
  }

  static double _calculateCreditUtilization(List<Liability> liabilities) {
    final creditCards = liabilities.where(
      (debt) =>
          debt.kind == 'creditCard' &&
          debt.creditLimit != null &&
          debt.creditLimit! > 0,
    );

    if (creditCards.isEmpty) return 0.0;

    double totalBalance = 0.0;
    double totalLimit = 0.0;

    for (final card in creditCards) {
      totalBalance += card.balance;
      totalLimit += card.creditLimit!;
    }

    return totalLimit > 0 ? totalBalance / totalLimit : 0.0;
  }

  static double _calculateMortgageToNetWorthRatio(
    List<Liability> liabilities,
    double netWorth,
  ) {
    // Guard rail: return worst case (1.0) when net worth is zero/negative
    if (netWorth <= 0) return 1.0;

    final mortgageBalance = liabilities
        .where((debt) => debt.kind == 'mortgage')
        .fold(0.0, (sum, mortgage) => sum + mortgage.balance);

    return mortgageBalance / netWorth;
  }

  static double _calculateDebtScore(
    double totalDebt,
    double assets,
    double income,
    double monthlyEssentials,
    double debtService,
    bool hasHighAprDebt,
    double creditUtilization,
  ) {
    // Legacy path now delegates to new unified scoring
    return _computeNewDebtScore(
      totalDebt: totalDebt,
      assets: assets,
      income: income,
      essentials: monthlyEssentials,
      monthlyDebtService: debtService,
      creditUtilization: creditUtilization,
      hasHighAprDebt: hasHighAprDebt,
    );
  }

  // ===== New scoring model helpers (v1.1) =====
  static double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

  static double _newLeverageScore(double totalDebt, double assets) {
    // Edge cases: no debt => perfect, debt with no assets => worst
    if (totalDebt <= 0) return 100;
    if (assets <= 0) return 0;
    final L = (totalDebt / assets).clamp(0.0, 1.5);
    return _clamp01((0.90 - L) / (0.90 - 0.20)) * 100.0;
  }

  static double _newDscrScore(
    double income,
    double essentials,
    double monthlyDebtService,
  ) {
    if (monthlyDebtService <= 0) return 100;
    final dscr = (income - essentials) / monthlyDebtService;
    if (dscr <= 0.8) return 0;
    if (dscr >= 1.5) return 100;
    return ((dscr - 0.8) / (1.5 - 0.8)) * 100.0;
  }

  static double _computeNewDebtScore({
    required double totalDebt,
    required double assets,
    required double income,
    required double essentials,
    required double monthlyDebtService,
    required double creditUtilization,
    required bool hasHighAprDebt,
    double? mortgageToAssets,
    double? monthsOfEssentials,
  }) {
    var score = 0.60 * _newLeverageScore(totalDebt, assets) +
        0.40 * _newDscrScore(income, essentials, monthlyDebtService);

    if (hasHighAprDebt) {
      score = score.clamp(0, 30);
    } else if (creditUtilization > 0.90) {
      score = score.clamp(0, 20);
    } else if (creditUtilization > 0.70) {
      score = score.clamp(0, 50);
    }

    if ((mortgageToAssets ?? 0) > 0.60 && (monthsOfEssentials ?? 99) < 1) {
      score = score.clamp(0, 50);
    }

    assert(() {
      lastDebug ??= {};
      lastDebug!.addAll({
        'modelVersion': 1.1,
        'totalDebt': totalDebt,
        'assets': assets,
        'income': income,
        'essentials': essentials,
        'monthlyDebtService': monthlyDebtService,
        'creditUtilization': creditUtilization,
        'hasHighAprDebt': hasHighAprDebt ? 1.0 : 0.0,
        'leverageScore_v1_1': _newLeverageScore(totalDebt, assets),
        'dscrScore_v1_1': _newDscrScore(income, essentials, monthlyDebtService),
        'debtScore_v1_1': score,
      });
      DebugLog.log(
        'DebtCalc',
        '[v1.1] debt=${totalDebt.toStringAsFixed(0)} assets=${assets.toStringAsFixed(0)} levScore=${_newLeverageScore(totalDebt, assets).toStringAsFixed(1)} dscr=${_newDscrScore(income, essentials, monthlyDebtService).toStringAsFixed(1)} util=${(creditUtilization * 100).toStringAsFixed(0)}% final=${score.toStringAsFixed(1)}',
      );
      return true;
    }());

    return score.clamp(0, 100);
  }

  static double _scoreLeverage(double debt, double assets) {
    if (assets <= 0) return 0;
    final Lraw = debt / assets; // leverage multiple
    // Normal sensitivity region
    if (Lraw <= ScoringConstants.leverageWorst) {
      final L = Lraw.clamp(
        ScoringConstants.leverageBest,
        ScoringConstants.leverageWorst,
      );
      final t = ((ScoringConstants.leverageWorst - L) /
              (ScoringConstants.leverageWorst - ScoringConstants.leverageBest))
          .clamp(0.0, 1.0);
      return 100 * t;
    }
    // Distress tail provides gradual improvement
    final Lt = Lraw.clamp(
      ScoringConstants.leverageWorst,
      ScoringConstants.leverageTailMax,
    );
    final tTail = ((ScoringConstants.leverageTailMax - Lt) /
            (ScoringConstants.leverageTailMax - ScoringConstants.leverageWorst))
        .clamp(0.0, 1.0);
    return ScoringConstants.leverageTailCeiling * tTail;
  }

  static double _scoreDSCR(
    double income,
    double monthlyEssentials,
    double debtService,
  ) {
    final discretionaryIncome = income - monthlyEssentials;
    if (discretionaryIncome <= 0 || debtService <= 0) return 0;

    final dscr = discretionaryIncome / debtService;
    // Map DSCR linearly inside configured bounds
    if (dscr <= ScoringConstants.dscrWorst) return 0;
    if (dscr >= ScoringConstants.dscrBest) return 100;
    return 100 *
        (dscr - ScoringConstants.dscrWorst) /
        (ScoringConstants.dscrBest - ScoringConstants.dscrWorst);
  }

  static double _calculateMortgageBalance(List<Liability> liabilities) {
    return liabilities
        .where((d) => d.kind == 'mortgage')
        .fold(0.0, (s, d) => s + d.balance);
  }

  static DebtLoadBand _getBandWithDTI(
    double debtToIncomeRatio,
    double creditUtilization,
    bool hasHighAprDebt,
    double mortgageToNetWorthRatio,
    double monthsOfEssentials,
  ) {
    // High APR debt (>20%) is always red
    if (hasHighAprDebt) return DebtLoadBand.red;

    // Industry standard DTI thresholds
    if (debtToIncomeRatio > 0.43) return DebtLoadBand.red; // DTI > 43%
    if (debtToIncomeRatio > 0.36) return DebtLoadBand.yellow; // DTI 36-43%

    // Very high credit utilization (>90%) is red
    if (creditUtilization > 0.90) return DebtLoadBand.red;

    // High credit utilization (>70%) is yellow
    if (creditUtilization > 0.70) return DebtLoadBand.yellow;

    // High mortgage ratio + low liquidity is concerning
    if (mortgageToNetWorthRatio > 0.60 && monthsOfEssentials < 1) {
      return DebtLoadBand.yellow;
    }

    // Excellent debt management: DTI < 36%
    return DebtLoadBand.green;
  }

  static String _getDescription(
    double weightedApr,
    double creditUtilization,
    List<Liability> highAprDebts,
    double mortgageToNetWorthRatio,
    double monthsOfEssentials,
    DebtLoadBand band,
  ) {
    if (highAprDebts.isNotEmpty) {
      final highAprText =
          '${(highAprDebts.first.apr * 100).toStringAsFixed(1)}%';
      return 'High Cost Debt: Revolving debt at $highAprText APR. Prioritize payoff using avalanche method.';
    }

    if (creditUtilization > 0.90) {
      final utilText = '${(creditUtilization * 100).toStringAsFixed(0)}%';
      return 'Maxed Credit: $utilText credit utilization. Pay down cards to improve credit score.';
    }

    if (mortgageToNetWorthRatio > 0.60 && monthsOfEssentials < 1) {
      final mortgageText =
          '${(mortgageToNetWorthRatio * 100).toStringAsFixed(0)}%';
      return 'Liquidity Risk: Mortgage is $mortgageText of net worth with low emergency fund.';
    }

    if (creditUtilization > 0.70) {
      final utilText = '${(creditUtilization * 100).toStringAsFixed(0)}%';
      return 'High Utilization: $utilText credit usage. Consider paying down for better credit score.';
    }

    final avgAprText = '${(weightedApr * 100).toStringAsFixed(1)}%';
    return 'Manageable Debt: Average APR $avgAprText. Continue regular payments and focus on investing.';
  }

  // Calculate debt avalanche order (highest APR first)
  static List<Liability> getAvalancheOrder(List<Liability> liabilities) {
    final sortedDebts = List<Liability>.from(liabilities);
    sortedDebts.sort((a, b) => b.apr.compareTo(a.apr)); // Descending APR
    return sortedDebts;
  }

  // Calculate debt snowball order (smallest balance first)
  static List<Liability> getSnowballOrder(List<Liability> liabilities) {
    final sortedDebts = List<Liability>.from(liabilities);
    sortedDebts
        .sort((a, b) => a.balance.compareTo(b.balance)); // Ascending balance
    return sortedDebts;
  }

  // Calculate extra payment needed to eliminate high APR debt in target months
  static double calculateExtraPayment(
    Liability debt,
    int targetMonths,
  ) {
    if (debt.balance <= 0 || debt.apr <= 0 || targetMonths <= 0) return 0.0;

    final monthlyRate = debt.apr / 12;
    final numPayments = targetMonths.toDouble();

    // Fixed PMT formula using proper exponentiation
    final f = math.pow(1 + monthlyRate, numPayments);
    final totalPayment = debt.balance * (monthlyRate * f) / (f - 1);
    final extraPayment = totalPayment - debt.minPayment;

    return extraPayment > 0 ? extraPayment : 0.0;
  }

  // Calculate interest savings from paying off debt early
  static double calculateInterestSavings(
    Liability debt,
    double extraMonthlyPayment,
  ) {
    if (debt.balance <= 0 || debt.apr <= 0 || extraMonthlyPayment <= 0) {
      return 0.0;
    }

    final monthlyRate = debt.apr / 12;
    final totalPayment = debt.minPayment + extraMonthlyPayment;

    // Guard against non-amortizing payments
    if (totalPayment <= debt.balance * monthlyRate) {
      return 0.0; // Payment too small to amortize
    }

    // Calculate months to payoff with extra payment
    final monthsToPayoff =
        -math.log(1 - (debt.balance * monthlyRate / totalPayment)) /
            math.log(1 + monthlyRate);

    // Calculate total interest with extra payments
    final totalPaid = totalPayment * monthsToPayoff;
    final interestPaid = totalPaid - debt.balance;

    // Guard against non-amortizing minimum payments
    if (debt.minPayment <= debt.balance * monthlyRate) {
      return double.infinity; // Minimum payment doesn't amortize
    }

    // Calculate interest with minimum payments
    final standardMonths =
        -math.log(1 - (debt.balance * monthlyRate / debt.minPayment)) /
            math.log(1 + monthlyRate);
    final standardTotalPaid = debt.minPayment * standardMonths;
    final standardInterest = standardTotalPaid - debt.balance;

    return standardInterest - interestPaid;
  }
}
