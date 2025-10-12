import 'dart:math' as math;
import '../models.dart';
import 'allocation.dart';

enum ConcentrationBand { red, yellow, green }

class ConcentrationResult {
  final double largestBucketPct;
  final String largestBucket;
  final ConcentrationBand band;
  final String description;
  final double employerStockPct;
  final bool hasEmployerStockRisk;
  final double score; // Continuous score 0-100 using HHI

  const ConcentrationResult({
    required this.largestBucketPct,
    required this.largestBucket,
    required this.band,
    required this.description,
    required this.employerStockPct,
    required this.hasEmployerStockRisk,
    required this.score,
  });
}

class ConcentrationCalculator {
  static ConcentrationResult calculateConcentration(
    List<Account> accounts,
    Settings settings,
  ) {
    final percentages = AllocationCalculator.calculatePercentages(accounts);

    // Find largest allocation bucket
    String largestBucket = 'cash';
    double largestPct = 0.0;

    final bucketNames = {
      'cash': 'Cash',
      'bonds': 'Bonds',
      'usEq': 'US Equity',
      'intlEq': 'International Equity',
      'realEstate': 'Real Estate',
      'alt': 'Alternatives',
    };

    percentages.forEach((bucket, pct) {
      if (pct > largestPct) {
        largestPct = pct;
        largestBucket = bucket;
      }
    });

    // Calculate employer stock concentration
    double employerStockTotal = 0.0;
    double assetsTotal = AllocationCalculator.calculateAssetsTotal(accounts);

    for (final account in accounts) {
      employerStockTotal +=
          account.balance * (account.employerStockPct / 100.0);
    }

    final employerStockPct =
        assetsTotal > 0 ? employerStockTotal / assetsTotal : 0.0;

    // Calculate HHI-based score with cap penalty
    final score = _calculateHHIScore(percentages, settings);

    // Determine overall concentration risk
    final band = _getBand(largestPct, employerStockPct, settings);
    final description = _getDescription(
      largestPct,
      bucketNames[largestBucket]!,
      employerStockPct,
      band,
    );

    return ConcentrationResult(
      largestBucketPct: largestPct,
      largestBucket: bucketNames[largestBucket]!,
      band: band,
      description: description,
      employerStockPct: employerStockPct,
      hasEmployerStockRisk: employerStockPct > settings.employerStockThreshold,
      score: score,
    );
  }

  static double _calculateHHIScore(
    Map<String, double> percentages,
    Settings settings,
  ) {
    final weights = percentages;
    final score =
        (_hhiScore(weights) - _capPenalty(weights, cap: settings.bucketCap))
            .clamp(0.0, 100.0);
    return score;
  }

  static double _hhiScore(Map<String, double> weights) {
    // weights values sum ≈ 1
    final hhi = weights.values.fold<double>(0, (s, w) => s + w * w);
    // With ~6 buckets, best ≈ 1/6 ≈ 0.167, worst = 1.0
    const best = 0.17, worst = 1.0;
    final t = ((worst - hhi) / (worst - best)).clamp(0.0, 1.0);
    return 100 * t;
  }

  static double _capPenalty(
    Map<String, double> weights, {
    required double cap,
  }) {
    final breach =
        weights.values.fold<double>(0, (m, w) => math.max(m, w - cap));
    return 30.0 * (breach <= 0 ? 0 : breach / (1 - cap)); // up to −30
  }

  static ConcentrationBand _getBand(
    double largestPct,
    double employerStockPct,
    Settings settings,
  ) {
    // Employer stock over threshold is problematic
    final redThreshold = settings.employerStockThreshold * 1.5;
    if (employerStockPct > redThreshold - 0.001) {
      return ConcentrationBand.red; // Use small tolerance for floating point
    }
    if (employerStockPct > settings.employerStockThreshold) {
      return ConcentrationBand.yellow;
    }

    // Industry-standard concentration thresholds based on professional portfolios
    if (largestPct > 0.80) {
      return ConcentrationBand.red; // >80% is extreme concentration
    }
    if (largestPct > 0.70) {
      return ConcentrationBand.yellow; // 70-80% needs some diversification
    }
    return ConcentrationBand
        .green; // <70% is well-diversified (60/40 portfolios are normal)
  }

  static String _getDescription(
    double largestPct,
    String largestBucket,
    double employerStockPct,
    ConcentrationBand band,
  ) {
    final largestPctText = '${(largestPct * 100).toStringAsFixed(1)}%';

    if (employerStockPct > 0.20) {
      final empPctText = '${(employerStockPct * 100).toStringAsFixed(1)}%';
      return 'High Risk: $empPctText in employer stock. Reduce to below 20% for better diversification.';
    }

    if (employerStockPct > 0.10) {
      final empPctText = '${(employerStockPct * 100).toStringAsFixed(1)}%';
      return 'Moderate Risk: $empPctText in employer stock. Consider reducing to below 10%.';
    }

    switch (band) {
      case ConcentrationBand.red:
        return 'High Concentration: $largestPctText in $largestBucket. Consider reducing to below 80%.';
      case ConcentrationBand.yellow:
        return 'Moderate Concentration: $largestPctText in $largestBucket. Good diversification for most portfolios.';
      case ConcentrationBand.green:
        return 'Well Diversified: $largestPctText in $largestBucket. Excellent portfolio balance.';
    }
  }

  // Calculate how much to move to reduce concentration
  static double calculateRebalanceAmount(
    List<Account> accounts,
    double targetMaxPct,
    Settings settings,
  ) {
    final result = calculateConcentration(accounts, settings);
    if (result.largestBucketPct <= targetMaxPct) return 0.0;

    final assetsTotal = AllocationCalculator.calculateAssetsTotal(accounts);
    final currentAmount = assetsTotal * result.largestBucketPct;
    final targetAmount = assetsTotal * targetMaxPct;

    return currentAmount - targetAmount;
  }

  // Suggest monthly rebalancing amount
  static double suggestMonthlyRebalance(
    List<Account> accounts,
    double targetMaxPct,
    Settings settings, {
    int monthsToRebalance = 6,
  }) {
    final rebalanceAmount =
        calculateRebalanceAmount(accounts, targetMaxPct, settings);
    if (rebalanceAmount <= 0) return 0;

    return rebalanceAmount / monthsToRebalance;
  }
}
