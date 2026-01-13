import '../models.dart';
import 'allocation.dart';

enum FixedIncomeBand { red, yellow, green }

class FixedIncomeResult {
  final double bondPct;
  final double targetBondPct;
  final FixedIncomeBand band;
  final String description;
  final double investableAssets;
  final double score; // Continuous score 0-100

  const FixedIncomeResult({
    required this.bondPct,
    required this.targetBondPct,
    required this.band,
    required this.description,
    required this.investableAssets,
    required this.score,
  });
}

class FixedIncomeCalculator {
  static FixedIncomeResult calculateFixedIncomeAllocation(
    List<Account> accounts,
    Settings settings,
  ) {
    final totals = AllocationCalculator.calculateTotals(accounts);

    // Calculate investable assets (excludes cash and real estate)
    final investableAssets =
        totals['bonds']! + totals['usEq']! + totals['intlEq']! + totals['alt']!;

    // Guard against zero investable assets
    if (investableAssets == 0.0) {
      return FixedIncomeResult(
        bondPct: 0.0,
        targetBondPct: settings.targetBondPct,
        band: FixedIncomeBand.red,
        description:
            'No Investable Assets: Add investments to enable bond allocation analysis.',
        investableAssets: 0.0,
        score: 0.0,
      );
    }

    // Bond percentage within investable assets
    final bondPct = totals['bonds']! / investableAssets;
    final targetBondPct = settings.targetBondPct;

    // Calculate continuous score
    final score = _scoreFixed(bondPct, targetBondPct);

    final band = _getBand(bondPct, targetBondPct);
    final description =
        _getDescription(bondPct, targetBondPct, settings.riskBand, band);

    return FixedIncomeResult(
      bondPct: bondPct,
      targetBondPct: targetBondPct,
      band: band,
      description: description,
      investableAssets: investableAssets,
      score: score,
    );
  }

  static double _scoreFixed(double bondPct, double target,
      {double tol = 0.10,}) {
    final diff = (bondPct - target).abs();
    if (diff <= tol) return 100;
    final t = ((diff - tol) / 0.50).clamp(0.0, 1.0);
    return (100 * (1 - t));
  }

  static FixedIncomeBand _getBand(double currentBondPct, double targetBondPct) {
    final difference = (targetBondPct - currentBondPct).abs();

    // Within 5% of target is green
    if (difference <= 0.05) return FixedIncomeBand.green;

    // Within 10% of target is yellow, but prioritize being under-bonded
    if (currentBondPct < targetBondPct && difference <= 0.15) {
      return FixedIncomeBand.yellow; // More concerning to be under-bonded
    }

    if (difference <= 0.10) return FixedIncomeBand.yellow;

    return FixedIncomeBand.red;
  }

  static String _getDescription(
    double currentBondPct,
    double targetBondPct,
    RiskBand riskBand,
    FixedIncomeBand band,
  ) {
    final currentPctText = '${(currentBondPct * 100).toStringAsFixed(1)}%';
    final targetPctText = '${(targetBondPct * 100).toStringAsFixed(1)}%';
    final riskBandText = _getRiskBandText(riskBand);

    switch (band) {
      case FixedIncomeBand.red:
        if (currentBondPct < targetBondPct) {
          return 'Low Ballast: Only $currentPctText bonds. $riskBandText profile suggests $targetPctText for stability.';
        } else {
          return 'High Ballast: $currentPctText bonds exceeds $riskBandText target of $targetPctText. May limit growth.';
        }
      case FixedIncomeBand.yellow:
        return 'Moderate Gap: $currentPctText bonds, target $targetPctText for $riskBandText profile.';
      case FixedIncomeBand.green:
        return 'Well Balanced: $currentPctText bonds aligns with $riskBandText target of $targetPctText.';
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

  // Calculate dollar amount needed to reach target bond allocation
  static double calculateBondDeficit(
    List<Account> accounts,
    Settings settings,
  ) {
    final result = calculateFixedIncomeAllocation(accounts, settings);

    if (result.investableAssets == 0) return 0.0;

    final currentBondAmount = result.investableAssets * result.bondPct;
    final targetBondAmount = result.investableAssets * result.targetBondPct;

    final deficit = targetBondAmount - currentBondAmount;
    return deficit > 0 ? deficit : 0.0;
  }

  // Suggest monthly bond allocation to reach target
  static double suggestMonthlyBondAllocation(
    List<Account> accounts,
    Settings settings, {
    int monthsToRebalance = 6,
  }) {
    final deficit = calculateBondDeficit(accounts, settings);
    if (deficit <= 0) return 0.0;

    return deficit / monthsToRebalance;
  }

  // Determine if new contributions should emphasize bonds
  static bool shouldFavorBonds(
    List<Account> accounts,
    Settings settings,
  ) {
    final result = calculateFixedIncomeAllocation(accounts, settings);
    return result.bondPct < result.targetBondPct;
  }

  // Calculate the age-appropriate bond allocation using "your age in bonds" rule
  static double calculateAgeBasedBondTarget(int age) {
    // Clamp between 20% and 60% for reasonable bounds
    final ageBased = age / 100.0;
    return ageBased.clamp(0.20, 0.60);
  }

  // Alternative bond target based on years to retirement
  static double calculateRetirementBasedBondTarget(int yearsToRetirement) {
    if (yearsToRetirement > 30) return 0.20; // Growth phase
    if (yearsToRetirement > 15) return 0.30; // Balanced phase
    if (yearsToRetirement > 10) return 0.40; // Conservative phase
    return 0.50; // Pre-retirement phase
  }
}
