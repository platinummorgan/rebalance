import 'dart:math' as math;

import '../models.dart';
import 'allocation.dart';

enum HomeBiasBand { red, yellow, green }

class HomeBiasResult {
  final double intlEquityPct;
  final HomeBiasBand band;
  final String description;
  final double targetIntlPct;
  final double currentIntlPct;
  final double score; // Continuous score 0-100

  const HomeBiasResult({
    required this.intlEquityPct,
    required this.band,
    required this.description,
    required this.targetIntlPct,
    required this.currentIntlPct,
    required this.score,
  });
}

class HomeBiasCalculator {
  static HomeBiasResult calculateHomeBias(
    List<Account> accounts,
    Settings settings,
  ) {
    final equityAllocation =
        AllocationCalculator.calculateEquityAllocation(accounts);

    // Check for zero equity case early
    final totalEquity =
        (equityAllocation['usEq'] ?? 0.0) + (equityAllocation['intlEq'] ?? 0.0);
    if (totalEquity == 0.0) {
      return HomeBiasResult(
        intlEquityPct: 0.0,
        band: HomeBiasBand.red,
        description:
            'No Equity Holdings: Add equity investments to enable geographic diversification analysis.',
        targetIntlPct: 1.0 - settings.usEquityTargetPct,
        currentIntlPct: 0.0,
        score: 0.0,
      );
    }

    final intlEquityPct = equityAllocation['intlEq'] ?? 0.0;

    // Target is inverse of US equity target (if US = 80%, then Intl = 20%)
    final targetIntlPct = 1.0 - settings.usEquityTargetPct;

    // Calculate continuous score using new implementation
    final score = scoreHomeBias(
        settings: settings,
        currentIntlPct: intlEquityPct,
        targetIntlPct: targetIntlPct);

    final band = _getBand(intlEquityPct, targetIntlPct);
    final description = _getDescription(intlEquityPct, targetIntlPct, band);

    return HomeBiasResult(
      intlEquityPct: intlEquityPct,
      band: band,
      description: description,
      targetIntlPct: targetIntlPct,
      currentIntlPct: intlEquityPct,
      score: score,
    );
  }

  // New implementation supporting floor, tolerance, soft-penalty and off mode.
  static double scoreHomeBias({
    required Settings settings,
    required double currentIntlPct,
    required double targetIntlPct,
  }) {
    // Mode can be 'standard', 'light', 'off'
    final mode = settings.globalDiversificationMode.toLowerCase();

    if (mode == 'off') {
      // Muted by user preference: aggregator should renormalize weights and
      // ignore this component. Return neutral (100) so callers that don't
      // renormalize don't penalize accidentally.
      return 100.0;
    }

    // Determine parameters: use overrides or defaults
    final tol = settings.intlTolerancePct;
    final floor = settings.intlFloorPct; // e.g., 60.0
    final penaltyScale = settings.intlPenaltyScale; // e.g., 60.0

    // Compute difference between actual and target
    final diff = (currentIntlPct - targetIntlPct).abs();

    // Within tolerance -> full score
    if (diff <= tol) return 100.0;

    // Outside tolerance, compute a soft penalty that approaches floor.
    final effectivePenaltyScale =
        mode == 'light' ? penaltyScale * 2.0 : penaltyScale;

    // Normalized diff (0..1+) relative to a reasonable maxDiff (0.5)
    const maxDiff = 0.5;
    final normalized = ((diff - tol) / (maxDiff - tol)).clamp(0.0, 1.0);

    // Use a smooth step: score = floor + (100 - floor) * (1 - normalized^(1/scale))
    final exponent = 1.0 + (effectivePenaltyScale / 100.0);
    final smooth = 1 - math.pow(normalized, exponent).toDouble();
    final score = floor + (100.0 - floor) * smooth;
    return score.clamp(floor, 100.0);
  }

  static HomeBiasBand _getBand(double currentIntlPct, double targetIntlPct) {
    final difference = (targetIntlPct - currentIntlPct).abs();

    // Within 5% of target is green
    if (difference <= 0.05) return HomeBiasBand.green;

    // Within 10% of target is yellow
    if (difference <= 0.10) return HomeBiasBand.yellow;

    // More than 10% off target is red
    return HomeBiasBand.red;
  }

  static String _getDescription(
    double currentIntlPct,
    double targetIntlPct,
    HomeBiasBand band,
  ) {
    final currentPctText = '${(currentIntlPct * 100).toStringAsFixed(1)}%';
    final targetPctText = '${(targetIntlPct * 100).toStringAsFixed(1)}%';

    switch (band) {
      case HomeBiasBand.red:
        if (currentIntlPct < targetIntlPct) {
          return 'High Home Bias: Only $currentPctText international. Target $targetPctText for global diversification.';
        } else {
          return 'Low Home Bias: $currentPctText international exceeds target $targetPctText. Consider rebalancing.';
        }
      case HomeBiasBand.yellow:
        return 'Moderate Bias: $currentPctText international, target $targetPctText. Close to optimal mix.';
      case HomeBiasBand.green:
        return 'Well Balanced: $currentPctText international equities, near target $targetPctText.';
    }
  }

  // Calculate dollar amount to rebalance to target
  static double calculateRebalanceAmount(
    List<Account> accounts,
    Settings settings,
  ) {
    final totals = AllocationCalculator.calculateTotals(accounts);
    final equityTotal = totals['usEq']! + totals['intlEq']!;

    if (equityTotal == 0) return 0.0;

    final currentIntlAmount = totals['intlEq']!;
    final targetIntlAmount = equityTotal * (1.0 - settings.usEquityTargetPct);

    return targetIntlAmount - currentIntlAmount;
  }

  // Suggest monthly allocation to fix home bias
  static double suggestMonthlyAllocation(
    List<Account> accounts,
    Settings settings, {
    int monthsToRebalance = 6,
  }) {
    final rebalanceAmount = calculateRebalanceAmount(accounts, settings);

    // If we need more international exposure
    if (rebalanceAmount > 0) {
      return rebalanceAmount / monthsToRebalance;
    }

    // If we have too much international exposure, suggest reducing
    if (rebalanceAmount < 0) {
      return rebalanceAmount.abs() / monthsToRebalance;
    }

    return 0.0;
  }

  // Check if new contributions should go to international
  static bool shouldFavorInternational(
    List<Account> accounts,
    Settings settings,
  ) {
    final rebalanceAmount = calculateRebalanceAmount(accounts, settings);
    return rebalanceAmount > 0; // Need more international
  }
}
