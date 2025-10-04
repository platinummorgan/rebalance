import '../models.dart';
import 'liquidity.dart';
import 'concentration.dart';
import 'homebias.dart';
import 'fixedincome.dart';
import 'debtload.dart';

enum HealthGrade { F, D, C, B, A }

class FinancialHealthResult {
  final int score;
  final HealthGrade grade;
  final String description;
  final String summary;
  final Map<String, int> componentScores;

  const FinancialHealthResult({
    required this.score,
    required this.grade,
    required this.description,
    required this.summary,
    required this.componentScores,
  });
}

class FinancialHealthCalculator {
  // Public weights used when composing the overall score. Kept here so UI
  // and tests can reference the exact values used by the algorithm.
  // Keys match the entries returned in FinancialHealthResult.componentScores.
  static const Map<String, double> componentWeights = {
    'Debt Load': 0.30,
    'Concentration': 0.25,
    'Liquidity': 0.20,
    'Fixed Income': 0.15,
    'Home Bias': 0.10,
  };

  static FinancialHealthResult calculateOverallHealth(
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
  ) {
    // Calculate all component results
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
        FixedIncomeCalculator.calculateFixedIncomeAllocation(
      accounts,
      settings,
    );

    final debtLoadResult = DebtLoadCalculator.calculateDebtLoad(
      accounts,
      liabilities,
      settings.monthlyEssentials,
      settings,
    );

    // Preserve continuous (double) component scores for sensitivity
    final double liquidityScore = liquidityResult.score;
    final double concentrationScore = concentrationResult.score;
    final double homeBiasScore = homeBiasResult.score;
    final double fixedIncomeScore = fixedIncomeResult.score;
    final double debtScore = debtLoadResult.score;

    // Weighted scoring (debt and concentration are most critical)
    // If Home Bias is muted by user preference, renormalize remaining weights
    final bool homeMuted =
        settings.globalDiversificationMode.toLowerCase() == 'off';

    double weightedScoreRaw;
    if (homeMuted) {
      // Sum of remaining weights = 1 - 0.10 = 0.90; divide each by 0.90 to renormalize
      weightedScoreRaw = (debtScore * (0.30 / 0.90) +
          concentrationScore * (0.25 / 0.90) +
          liquidityScore * (0.20 / 0.90) +
          fixedIncomeScore * (0.15 / 0.90));
    } else {
      weightedScoreRaw = (debtScore * 0.30 + // 30% - Debt is critical
              concentrationScore * 0.25 + // 25% - Risk concentration
              liquidityScore * 0.20 + // 20% - Emergency fund
              fixedIncomeScore * 0.15 + // 15% - Asset allocation
              homeBiasScore * 0.10 // 10% - Geographic diversity
          );
    }
    final int weightedScore = weightedScoreRaw.round();

    // Debug: raw component scores
    // ignore: avoid_print
    print(
      '[OverallHealth] debt=${debtScore.toStringAsFixed(2)} conc=${concentrationScore.toStringAsFixed(2)} liq=${liquidityScore.toStringAsFixed(2)} fixed=${fixedIncomeScore.toStringAsFixed(2)} home=${homeBiasScore.toStringAsFixed(2)} => raw=${weightedScoreRaw.toStringAsFixed(2)} disp=$weightedScore',
    );

    final grade = _scoreToGrade(weightedScore);
    final description = _getDescription(grade, weightedScore);
    final summary = _getSummary(grade);

    // Store integer component scores for display. If Home Bias is muted, mark as -1
    final componentScores = {
      'Debt Load': debtScore.round(),
      'Concentration': concentrationScore.round(),
      'Liquidity': liquidityScore.round(),
      'Fixed Income': fixedIncomeScore.round(),
      'Home Bias': homeMuted ? -1 : homeBiasScore.round(),
    };

    return FinancialHealthResult(
      score: weightedScore,
      grade: grade,
      description: description,
      summary: summary,
      componentScores: componentScores,
    );
  }

  static HealthGrade _scoreToGrade(int score) {
    if (score >= 90) return HealthGrade.A;
    if (score >= 80) return HealthGrade.B;
    if (score >= 70) return HealthGrade.C;
    if (score >= 50) return HealthGrade.D;
    return HealthGrade.F;
  }

  static String _getDescription(HealthGrade grade, int score) {
    switch (grade) {
      case HealthGrade.A:
        return 'Excellent financial health! Your portfolio is well-diversified with strong fundamentals.';
      case HealthGrade.B:
        return 'Good financial position with minor areas for improvement.';
      case HealthGrade.C:
        return 'Fair financial health. Focus on the orange and red areas for improvement.';
      case HealthGrade.D:
        return 'Several important areas need attention. Prioritize debt and concentration issues.';
      case HealthGrade.F:
        return 'Critical financial issues require immediate attention. Start with debt and emergency fund.';
    }
  }

  static String _getSummary(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return 'Excellent';
      case HealthGrade.B:
        return 'Good';
      case HealthGrade.C:
        return 'Fair';
      case HealthGrade.D:
        return 'Needs Work';
      case HealthGrade.F:
        return 'Critical';
    }
  }
}
