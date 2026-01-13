import '../models.dart';
import 'allocation.dart';

enum LiquidityBand { red, yellow, green, blue }

class LiquidityResult {
  final double monthsOfEssentials;
  final LiquidityBand band;
  final String description;
  final double cashEquivalent;
  final double score; // Continuous score 0-100

  const LiquidityResult({
    required this.monthsOfEssentials,
    required this.band,
    required this.description,
    required this.cashEquivalent,
    required this.score,
  });
}

class LiquidityCalculator {
  static LiquidityResult calculateLiquidity(
    List<Account> accounts,
    double monthlyEssentials,
    Settings settings,
  ) {
    if (monthlyEssentials <= 0) {
      return const LiquidityResult(
        monthsOfEssentials: 0,
        band: LiquidityBand.red,
        description: 'Set monthly essentials to calculate liquidity',
        cashEquivalent: 0,
        score: 0,
      );
    }

    final totals = AllocationCalculator.calculateTotals(accounts);

    // Use configurable bond haircut from settings
    final bondHaircut = settings.liquidityBondHaircut;
    final cashEquivalent = totals['cash']! + (totals['bonds']! * bondHaircut);

    final monthsOfEssentials = cashEquivalent / monthlyEssentials;

    final band = _getBand(monthsOfEssentials);
    final score = _scoreLiquidity(monthsOfEssentials);
    final description = _getDescription(monthsOfEssentials, band);

    return LiquidityResult(
      monthsOfEssentials: monthsOfEssentials,
      band: band,
      description: description,
      cashEquivalent: cashEquivalent,
      score: score,
    );
  }

  static LiquidityBand _getBand(double months) {
    if (months < 1) return LiquidityBand.red;
    if (months < 3) return LiquidityBand.yellow;
    if (months <= 6) return LiquidityBand.green;
    return LiquidityBand.blue;
  }

  static double _scoreLiquidity(double months) {
    if (months <= 0) return 0;
    if (months >= 6) return 100;
    if (months <= 3) return 20 * months; // 0..60
    return 60 + (months - 3) * (40 / 3); // 60..100 at 6
  }

  static String _getDescription(double months, LiquidityBand band) {
    switch (band) {
      case LiquidityBand.red:
        return 'Critical: Less than 1 month of essentials covered. Build emergency fund immediately.';
      case LiquidityBand.yellow:
        return 'Low: ${months.toStringAsFixed(1)} months covered. Aim for 3-6 months.';
      case LiquidityBand.green:
        return 'Good: ${months.toStringAsFixed(1)} months of essentials covered.';
      case LiquidityBand.blue:
        return 'Excellent: ${months.toStringAsFixed(1)} months covered. Consider investing excess cash.';
    }
  }

  // Calculate how much more cash is needed to reach target
  static double calculateCashNeeded(
    List<Account> accounts,
    double monthlyEssentials,
    double targetMonths,
    Settings settings,
  ) {
    final current = calculateLiquidity(accounts, monthlyEssentials, settings);
    final targetAmount = monthlyEssentials * targetMonths;
    final needed = targetAmount - current.cashEquivalent;

    return needed > 0 ? needed : 0;
  }

  // Suggest monthly savings to reach liquidity target
  static double suggestMonthlySavings(
    List<Account> accounts,
    double monthlyEssentials,
    double targetMonths,
    Settings settings, {
    int monthsToReach = 6,
  }) {
    final needed = calculateCashNeeded(
        accounts, monthlyEssentials, targetMonths, settings,);
    if (needed <= 0) return 0;

    return needed / monthsToReach;
  }
}
