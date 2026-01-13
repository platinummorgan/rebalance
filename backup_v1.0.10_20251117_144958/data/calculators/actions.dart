import '../models.dart';
import 'allocation.dart';
import 'liquidity.dart';
import 'concentration.dart';
import 'homebias.dart';
import 'fixedincome.dart';
import 'debtload.dart';
import 'package:intl/intl.dart';

class ActionCardGenerator {
  static List<ActionCard> generateActionCards(
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
  ) {
    final cards = <ActionCard>[];
    final currency = NumberFormat.simpleCurrency();

    // 1. Build Cushion Card
    final liquidityResult = LiquidityCalculator.calculateLiquidity(
      accounts,
      settings.monthlyEssentials,
      settings,
    );
    if (liquidityResult.band == LiquidityBand.red ||
        liquidityResult.band == LiquidityBand.yellow) {
      final targetMonths =
          liquidityResult.band == LiquidityBand.red ? 3.0 : 6.0;
      final monthlyMove = LiquidityCalculator.suggestMonthlySavings(
        accounts,
        settings.monthlyEssentials,
        targetMonths,
        settings,
      );
      final targetCash = settings.monthlyEssentials * targetMonths;

      cards.add(
        ActionCard(
          id: 'build_cushion_${DateTime.now().millisecondsSinceEpoch}',
          type: 'buildCushion',
          title: 'Build Emergency Cushion',
          description:
              'You have ${liquidityResult.monthsOfEssentials.toStringAsFixed(1)} months of essentials. Target $targetMonths–6. Move ${currency.format(monthlyMove)} / mo to cash until you reach ${currency.format(targetCash)}.',
          createdAt: DateTime.now(),
          data: {
            'currentMonths': liquidityResult.monthsOfEssentials,
            'targetMonths': targetMonths,
            'monthlyMove': monthlyMove,
            'targetAmount': targetCash,
          },
        ),
      );
    }

    // 2. Reduce Concentration Card
    final concentrationResult =
        ConcentrationCalculator.calculateConcentration(accounts, settings);
    if (concentrationResult.band == ConcentrationBand.red ||
        concentrationResult.band == ConcentrationBand.yellow) {
      final monthlyRebalance = ConcentrationCalculator.suggestMonthlyRebalance(
        accounts,
        0.15,
        settings,
      ); // 15% max

      if (concentrationResult.hasEmployerStockRisk) {
        cards.add(
          ActionCard(
            id: 'employer_stock_${DateTime.now().millisecondsSinceEpoch}',
            type: 'reduceConcentration',
            title: 'Reduce Employer Stock Risk',
            description:
                'Employer stock is ${(concentrationResult.employerStockPct * 100).toStringAsFixed(1)}% of portfolio. Diversify ${currency.format(monthlyRebalance)} / mo to reduce career/investment correlation.',
            createdAt: DateTime.now(),
            data: {
              'currentPct': concentrationResult.employerStockPct,
              'targetPct': 0.10,
              'monthlyMove': monthlyRebalance,
              'bucket': 'Employer Stock',
            },
          ),
        );
      } else {
        cards.add(
          ActionCard(
            id: 'concentration_${DateTime.now().millisecondsSinceEpoch}',
            type: 'reduceConcentration',
            title: 'Reduce Concentration Risk',
            description:
                'Largest bucket is ${concentrationResult.largestBucket} at ${(concentrationResult.largestBucketPct * 100).toStringAsFixed(1)}%. Cap at 10%–20%. Shift ${currency.format(monthlyRebalance)} over 6 months.',
            createdAt: DateTime.now(),
            data: {
              'currentPct': concentrationResult.largestBucketPct,
              'targetPct': 0.15,
              'monthlyMove': monthlyRebalance,
              'bucket': concentrationResult.largestBucket,
            },
          ),
        );
      }
    }

    // 3. Home Bias Card
    final homeBiasResult =
        HomeBiasCalculator.calculateHomeBias(accounts, settings);
    if (homeBiasResult.band == HomeBiasBand.red ||
        homeBiasResult.band == HomeBiasBand.yellow) {
      final monthlyMove =
          HomeBiasCalculator.suggestMonthlyAllocation(accounts, settings);
      final shouldFavorIntl =
          HomeBiasCalculator.shouldFavorInternational(accounts, settings);

      if (shouldFavorIntl && monthlyMove > 0) {
        cards.add(
          ActionCard(
            id: 'home_bias_${DateTime.now().millisecondsSinceEpoch}',
            type: 'homeBias',
            title: 'Reduce Home Country Bias',
            description:
                'Intl equities are ${(homeBiasResult.intlEquityPct * 100).toStringAsFixed(1)}% of equities. Aim for ${(homeBiasResult.targetIntlPct * 100).toStringAsFixed(0)}%. Redirect ${currency.format(monthlyMove)} / mo to Intl funds.',
            createdAt: DateTime.now(),
            data: {
              'currentIntlPct': homeBiasResult.intlEquityPct,
              'targetIntlPct': homeBiasResult.targetIntlPct,
              'monthlyMove': monthlyMove,
            },
          ),
        );
      }
    }

    // 4. Add Bonds Card
    final fixedIncomeResult =
        FixedIncomeCalculator.calculateFixedIncomeAllocation(
      accounts,
      settings,
    );
    if (fixedIncomeResult.band == FixedIncomeBand.red ||
        fixedIncomeResult.band == FixedIncomeBand.yellow) {
      final monthlyBonds = FixedIncomeCalculator.suggestMonthlyBondAllocation(
        accounts,
        settings,
      );

      if (fixedIncomeResult.bondPct < fixedIncomeResult.targetBondPct &&
          monthlyBonds > 0) {
        final riskBandText = _getRiskBandText(settings.riskBand);

        cards.add(
          ActionCard(
            id: 'add_bonds_${DateTime.now().millisecondsSinceEpoch}',
            type: 'addBonds',
            title: 'Increase Fixed Income Ballast',
            description:
                'Fixed income is ${(fixedIncomeResult.bondPct * 100).toStringAsFixed(1)}%; target for $riskBandText is ${(fixedIncomeResult.targetBondPct * 100).toStringAsFixed(0)}%. Top up ${currency.format(monthlyBonds)} / mo.',
            createdAt: DateTime.now(),
            data: {
              'currentBondPct': fixedIncomeResult.bondPct,
              'targetBondPct': fixedIncomeResult.targetBondPct,
              'monthlyMove': monthlyBonds,
              'riskBand': riskBandText,
            },
          ),
        );
      }
    }

    // 5. High APR Debt Card
    final debtLoadResult = DebtLoadCalculator.calculateDebtLoad(
      accounts,
      liabilities,
      settings.monthlyEssentials,
      settings,
    );
    if (debtLoadResult.highAprDebts.isNotEmpty) {
      final avalancheOrder =
          DebtLoadCalculator.getAvalancheOrder(debtLoadResult.highAprDebts);
      final topDebt = avalancheOrder.first;
      final extraPayment =
          DebtLoadCalculator.calculateExtraPayment(topDebt, 24); // 2 years

      cards.add(
        ActionCard(
          id: 'high_apr_${DateTime.now().millisecondsSinceEpoch}',
          type: 'highApr',
          title: 'Eliminate High-Cost Debt',
          description:
              'You have revolving debt at ${(topDebt.apr * 100).toStringAsFixed(1)}%. Prioritize ${currency.format(extraPayment)} / mo using the avalanche method.',
          createdAt: DateTime.now(),
          data: {
            'debtName': topDebt.name,
            'apr': topDebt.apr,
            'balance': topDebt.balance,
            'extraPayment': extraPayment,
            'targetMonths': 24,
          },
        ),
      );
    }

    // Sort cards by priority (debt first, then liquidity, etc.)
    cards.sort(
      (a, b) => _getCardPriority(a.type).compareTo(_getCardPriority(b.type)),
    );

    // Return top 3 cards
    return cards.take(3).toList();
  }

  static int _getCardPriority(String type) {
    switch (type) {
      case 'highApr':
        return 1; // Highest priority
      case 'buildCushion':
        return 2;
      case 'reduceConcentration':
        return 3;
      case 'addBonds':
        return 4;
      case 'homeBias':
        return 5; // Lowest priority
      default:
        return 99;
    }
  }

  static String _getRiskBandText(RiskBand riskBand) {
    switch (riskBand) {
      case RiskBand.conservative:
        return 'Conservative';
      case RiskBand.balanced:
        return 'Balanced';
      case RiskBand.growth:
        return 'Growth';
    }
  }

  // Generate drift alerts when allocations deviate from targets
  static List<ActionCard> generateDriftAlerts(
    List<Account> accounts,
    Settings settings,
    Map<String, double> targetAllocation,
  ) {
    final cards = <ActionCard>[];
    final currency = NumberFormat.simpleCurrency();
    final currentAllocation =
        AllocationCalculator.calculatePercentages(accounts);
    final assetsTotal = AllocationCalculator.calculateAssetsTotal(accounts);

    targetAllocation.forEach((bucket, targetPct) {
      final currentPct = currentAllocation[bucket] ?? 0.0;
      final drift = (currentPct - targetPct).abs();

      if (drift > settings.driftThresholdPct) {
        final driftAmount = assetsTotal * drift;
        final monthlyRebalance = driftAmount / 6; // 6-month glide path

        final action = currentPct > targetPct ? 'Reduce' : 'Increase';
        final direction = currentPct > targetPct ? 'from' : 'to';

        cards.add(
          ActionCard(
            id: 'drift_${bucket}_${DateTime.now().millisecondsSinceEpoch}',
            type: 'driftAlert',
            title: '$action $bucket Allocation',
            description:
                '$bucket has drifted ${(drift * 100).toStringAsFixed(1)}% $direction target. Rebalance ${currency.format(monthlyRebalance)} / mo over 6 months.',
            createdAt: DateTime.now(),
            data: {
              'bucket': bucket,
              'currentPct': currentPct,
              'targetPct': targetPct,
              'drift': drift,
              'monthlyRebalance': monthlyRebalance,
            },
          ),
        );
      }
    });

    return cards;
  }

  // Update existing action cards based on current portfolio state
  static Future<void> updateActionCards(
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
  ) async {
    // This would be called by a background service to refresh action cards
    // For now, it's a placeholder for the notification system
  }
}
