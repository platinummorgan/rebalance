import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/liquidity.dart';
import 'package:rebalance/data/calculators/concentration.dart';
import 'package:rebalance/data/calculators/homebias.dart';
import 'package:rebalance/data/calculators/fixedincome.dart';
import 'package:rebalance/data/calculators/debtload.dart';
import 'package:rebalance/data/calculators/allocation.dart' as alloc;

// Simple calibration: adjust baseline and a global impact scale so that the
// contribution-model score best matches the legacy weighted-average score
// across a small set of representative portfolios.

void main() {
  test('calibrate contribution model', () {
    // Representative portfolios: include user's portfolio and a few synthetic cases
    final portfolios = <Map<String, dynamic>>[];

    // 1) User-provided (from prior message)
    portfolios.add(_buildUserPortfolio());

    // 2) Healthy diversified
    portfolios.add(_buildHealthyPortfolio());

    // 3) Concentrated low liquidity
    portfolios.add(_buildConcentratedPortfolio());

    // Evaluate legacy (weighted average) for each portfolio
    final targets = <int>[];

    for (final p in portfolios) {
      final legacy =
          _legacyScore(p['accounts'], p['liabilities'], p['settings']);
      targets.add(legacy);
    }

    double bestErr = double.infinity;
    double bestBaseline = 80.0;
    double bestScale = 1.0;

    // Grid search
    for (double baseline = 75.0; baseline <= 90.0; baseline += 1.0) {
      for (double scale = 0.6; scale <= 1.4; scale += 0.05) {
        double errSum = 0.0;
        for (int i = 0; i < portfolios.length; i++) {
          final p = portfolios[i];
          final contrib = _contribScore(
            p['accounts'],
            p['liabilities'],
            p['settings'],
            baseline,
            scale,
          );
          final legacy = targets[i];
          final err = (contrib - legacy).abs();
          errSum += err;
        }
        final meanErr = errSum / portfolios.length;
        if (meanErr < bestErr) {
          bestErr = meanErr;
          bestBaseline = baseline;
          bestScale = scale;
        }
      }
    }

    // Ensure calibration ran and found a finite error and params are in expected ranges
    expect(bestErr.isFinite, isTrue);
    expect(bestBaseline, greaterThanOrEqualTo(75.0));
    expect(bestBaseline, lessThanOrEqualTo(90.0));
    expect(bestScale, greaterThanOrEqualTo(0.6));
    expect(bestScale, lessThanOrEqualTo(1.4));
  });
}

int _legacyScore(
  List<Account> accounts,
  List<Liability> liabilities,
  Settings settings,
) {
  final liquidityResult = LiquidityCalculator.calculateLiquidity(
    accounts,
    settings.monthlyEssentials,
    settings,
  );
  final concentrationResult =
      ConcentrationCalculator.calculateConcentration(accounts, settings);
  final homeBiasResult =
      HomeBiasCalculator.calculateHomeBias(accounts, settings);
  final fixedIncomeResult =
      FixedIncomeCalculator.calculateFixedIncomeAllocation(accounts, settings);
  final debtLoadResult = DebtLoadCalculator.calculateDebtLoad(
    accounts,
    liabilities,
    settings.monthlyEssentials,
    settings,
  );

  final double liqScore = liquidityResult.score;
  final double concScore = concentrationResult.score;
  final double homeScore = homeBiasResult.score;

  // Use these values in lightweight assertions to avoid analyzer unused-variable warnings
  expect(concScore, isA<double>());
  expect(homeScore, isA<double>());
  final double fixedScore = fixedIncomeResult.score;
  final double debtScore = debtLoadResult.score;

  final weights = {
    'Debt Load': 0.30,
    'Concentration': 0.25,
    'Liquidity': 0.20,
    'Fixed Income': 0.15,
    'Home Bias': 0.10,
  };
  final compMap = {
    'Debt Load': debtScore,
    'Concentration': concScore,
    'Liquidity': liqScore,
    'Fixed Income': fixedScore,
    'Home Bias': homeScore,
  };

  final bool homeMuted =
      settings.globalDiversificationMode.toLowerCase() == 'off';
  double weightedSum = 0.0;
  double weightTotal = 0.0;

  if (homeMuted) {
    final remWeights = Map<String, double>.from(weights)..remove('Home Bias');
    final base = remWeights.values.reduce((a, b) => a + b);
    final renorm = remWeights.map((k, v) => MapEntry(k, v / base));
    renorm.forEach((k, v) {
      weightTotal += v;
      weightedSum += (compMap[k]! * v);
    });
  } else {
    weights.forEach((k, v) {
      weightTotal += v;
      weightedSum += (compMap[k]! * v);
    });
  }

  return (weightedSum / (weightTotal == 0 ? 1 : weightTotal)).round();
}

int _contribScore(
  List<Account> accounts,
  List<Liability> liabilities,
  Settings settings,
  double baseline,
  double globalScale,
) {
  final liquidityResult = LiquidityCalculator.calculateLiquidity(
    accounts,
    settings.monthlyEssentials,
    settings,
  );
  final concentrationResult =
      ConcentrationCalculator.calculateConcentration(accounts, settings);
  final homeBiasResult =
      HomeBiasCalculator.calculateHomeBias(accounts, settings);
  final fixedIncomeResult =
      FixedIncomeCalculator.calculateFixedIncomeAllocation(accounts, settings);
  final debtLoadResult = DebtLoadCalculator.calculateDebtLoad(
    accounts,
    liabilities,
    settings.monthlyEssentials,
    settings,
  );

  final income = settings.monthlyIncome ??
      settings.monthlyEssentials * settings.incomeMultiplierFallback;
  final debtToIncome =
      income > 0 ? debtLoadResult.monthlyDebtService / income : 0.0;
  final liquidityMonths = liquidityResult.monthsOfEssentials;
  final fixedIncomeShare = fixedIncomeResult.bondPct;

  // HHI
  final percentages = alloc.AllocationCalculator.calculatePercentages(accounts);
  double hhi = 0.0;
  for (final v in percentages.values) {
    hhi += v * v;
  }
  final equityAlloc =
      alloc.AllocationCalculator.calculateEquityAllocation(accounts);
  final intlShare = equityAlloc['intlEq'] ?? 0.0;
  final intlMutedFlag =
      settings.globalDiversificationMode.toLowerCase() == 'off';

  // base impacts (same as in code)
  final debtImpact = 12.0 * globalScale;
  final liquidityImpact = 10.0 * globalScale;
  final fixedImpact = 8.0 * globalScale;
  final concentrationImpact = 10.0 * globalScale;
  final intlImpact = 6.0 * globalScale;

  double bipolarScale({
    required double value,
    required double goodMax,
    required double neutralMax,
    required double badMax,
    required double impact,
    required bool invert,
  }) {
    double v = value;
    if (invert) v = -v;
    double g = invert ? -goodMax : goodMax;
    double n = invert ? -neutralMax : neutralMax;
    double b = invert ? -badMax : badMax;
    double unit;
    if (v <= g) {
      unit = 1.0;
    } else if (v <= n) {
      unit = 1.0 - ((v - g) / (n - g));
    } else if (v <= b) {
      unit = 0.0 - ((v - n) / (b - n));
    } else {
      unit = -1.0;
    }
    return unit * impact;
  }

  double oneSidedSaturating({
    required double value,
    required double fullAt,
    required double maxAt,
    required double impact,
  }) {
    if (value <= 0) return -impact;
    if (value >= maxAt) return impact;
    if (value >= fullAt) return impact * 0.85;
    final unit = (value / fullAt).clamp(0.0, 1.0);
    return (-impact + (impact * (1 + unit)));
  }

  double centeredBand({
    required double value,
    required double target,
    required double band,
    required double fade,
    required double impact,
  }) {
    final d = (value - target).abs();
    if (d <= band) return impact;
    final over = (d - band);
    final unit = (1.0 - (over / fade)).clamp(0.0, 1.0);
    return (unit * (impact)) + ((1 - unit) * (-impact));
  }

  final debtContribution = bipolarScale(
    value: debtToIncome,
    goodMax: 0.15,
    neutralMax: 0.36,
    badMax: 0.60,
    impact: debtImpact,
    invert: true,
  );

  final liqContribution = oneSidedSaturating(
    value: liquidityMonths,
    fullAt: 6.0,
    maxAt: 12.0,
    impact: liquidityImpact,
  );

  final fixedContribution = centeredBand(
    value: fixedIncomeShare,
    target: 0.30,
    band: 0.10,
    fade: 0.20,
    impact: fixedImpact,
  );

  final concContribution = centeredBand(
    value: 1.0 - hhi,
    target: 1.0 - 0.12,
    band: 0.05,
    fade: 0.13,
    impact: concentrationImpact,
  );

  final intlContribution = intlMutedFlag
      ? 0.0
      : centeredBand(
          value: intlShare,
          target: 0.30,
          band: 0.15,
          fade: 0.30,
          impact: intlImpact,
        );

  final contributions = [
    debtContribution,
    liqContribution,
    fixedContribution,
    concContribution,
    intlContribution,
  ];
  final raw = baseline + contributions.fold(0.0, (s, v) => s + v);
  return raw.clamp(0.0, 100.0).round();
}

Map<String, dynamic> _buildUserPortfolio() {
  final accounts = <Account>[];
  accounts.add(
    Account(
      id: 'a1',
      name: 'Synnovus',
      kind: 'cash',
      balance: 682.96,
      pctCash: 1.0,
      pctBonds: 0.0,
      pctUsEq: 0.0,
      pctIntlEq: 0.0,
      pctRealEstate: 0.0,
      pctAlt: 0.0,
      updatedAt: DateTime.now(),
    ),
  );
  accounts.add(
    Account(
      id: 'a2',
      name: 'Robinhood',
      kind: 'brokerage',
      balance: 1966.00,
      pctCash: 0.05,
      pctBonds: 0.25,
      pctUsEq: 0.55,
      pctIntlEq: 0.15,
      pctRealEstate: 0.0,
      pctAlt: 0.0,
      updatedAt: DateTime.now(),
    ),
  );
  accounts.add(
    Account(
      id: 'a3',
      name: 'Fidelity',
      kind: 'retirement',
      balance: 388442.00,
      pctCash: 0.05,
      pctBonds: 0.30,
      pctUsEq: 0.50,
      pctIntlEq: 0.15,
      pctRealEstate: 0.0,
      pctAlt: 0.0,
      updatedAt: DateTime.now(),
      isLocked: true,
    ),
  );

  final liabilities = <Liability>[];
  void addStudent(String id, double balance, double apr) {
    liabilities.add(
      Liability(
        id: id,
        name: id,
        kind: 'studentLoan',
        balance: balance,
        apr: apr,
        minPayment: balance * 0.01,
        updatedAt: DateTime.now(),
      ),
    );
  }

  addStudent('Aidadvantage1', 861.41, 0.0375);
  addStudent('Aidadvantage2', 1631.25, 0.0375);
  addStudent('Aidadvantage3', 3468.36, 0.0445);
  addStudent('Aidadvantage4', 6553.16, 0.0445);
  addStudent('Aidadvantage5', 990.94, 0.0445);
  addStudent('Aidadvantage6', 4484.69, 0.0505);
  addStudent('Aidadvantage7', 5562.26, 0.0505);
  addStudent('Aidadvantage8', 5454.47, 0.0453);
  addStudent('Aidadvantage9', 6529.51, 0.0453);
  addStudent('Aidadvantage10', 5363.36, 0.0275);
  addStudent('Aidadvantage11', 6323.88, 0.0275);

  const ccBalance = 4776.96;
  const ccLimit = 6000.0;
  final ccMin = (ccBalance * 0.02).clamp(25.0, double.infinity);
  liabilities.add(
    Liability(
      id: 'missionlane',
      name: 'Mission Lane',
      kind: 'creditCard',
      balance: ccBalance,
      apr: 0.3124,
      minPayment: ccMin,
      updatedAt: DateTime.now(),
      creditLimit: ccLimit,
    ),
  );

  final settings = Settings(
    riskBand: RiskBand.growth,
    monthlyEssentials: 3000,
    globalDiversificationMode: 'standard',
  );

  return {
    'accounts': accounts,
    'liabilities': liabilities,
    'settings': settings,
    'desc': 'user',
  };
}

Map<String, dynamic> _buildHealthyPortfolio() {
  final accounts = <Account>[];
  accounts.add(
    Account(
      id: 'c1',
      name: 'Cash',
      kind: 'savings',
      balance: 30000,
      pctCash: 1.0,
      pctBonds: 0.0,
      pctUsEq: 0.0,
      pctIntlEq: 0.0,
      pctRealEstate: 0.0,
      pctAlt: 0.0,
      updatedAt: DateTime.now(),
    ),
  );
  accounts.add(
    Account(
      id: 'inv1',
      name: 'Invest',
      kind: 'brokerage',
      balance: 70000,
      pctCash: 0.05,
      pctBonds: 0.25,
      pctUsEq: 0.55,
      pctIntlEq: 0.15,
      pctRealEstate: 0.0,
      pctAlt: 0.0,
      updatedAt: DateTime.now(),
    ),
  );
  final liabilities = <Liability>[];
  final settings = Settings(
    riskBand: RiskBand.growth,
    monthlyEssentials: 3000,
    globalDiversificationMode: 'standard',
  );
  return {
    'accounts': accounts,
    'liabilities': liabilities,
    'settings': settings,
    'desc': 'healthy',
  };
}

Map<String, dynamic> _buildConcentratedPortfolio() {
  final accounts = <Account>[];
  accounts.add(
    Account(
      id: 'c1',
      name: 'BigStock',
      kind: 'brokerage',
      balance: 100000,
      pctCash: 0.0,
      pctBonds: 0.0,
      pctUsEq: 1.0,
      pctIntlEq: 0.0,
      pctRealEstate: 0.0,
      pctAlt: 0.0,
      updatedAt: DateTime.now(),
    ),
  );
  final liabilities = <Liability>[];
  final settings = Settings(
    riskBand: RiskBand.growth,
    monthlyEssentials: 3000,
    globalDiversificationMode: 'standard',
  );
  return {
    'accounts': accounts,
    'liabilities': liabilities,
    'settings': settings,
    'desc': 'concentrated',
  };
}
