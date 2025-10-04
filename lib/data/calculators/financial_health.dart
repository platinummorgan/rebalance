import '../models.dart';
import 'package:flutter/foundation.dart';
import 'allocation.dart';
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
  final Map<String, double> componentContributions;

  const FinancialHealthResult({
    required this.score,
    required this.grade,
    required this.description,
    required this.summary,
    required this.componentScores,
    this.componentContributions = const {},
  });
}

/*
Developer note: Financial Health calculation

Overview:
- rawScore = baseline + sum(component contributions)
- baseline: `settings.financialHealthBaseline` (default calibrated value, see Settings)
- globalScale: `settings.financialHealthGlobalScale` (global multiplier for per-dial impacts)

Per-dial impacts (max absolute contribution per dial):
- debtImpact = 12.0 * globalScale
- liquidityImpact = 10.0 * globalScale
- fixedImpact = 8.0 * globalScale
- concentrationImpact = 10.0 * globalScale
- intlImpact = 6.0 * globalScale

Mapping functions used for contributions:
- bipolarScale(...): maps a bipolar metric (good/neutral/bad) to [-impact, +impact].
  Use `invert=true` when larger values are worse (e.g., debt-to-income).
- oneSidedSaturating(...): maps one-sided metrics (e.g., liquidity months) with
  negative contribution when value is zero, saturating to +impact at/above maxAt.
- centeredBand(...): gives full +impact when value is within target +/- band,
  then fades towards -impact across a 'fade' range.

Muting behavior:
- When a dial is muted (for example, Home Bias when `globalDiversificationMode=='off'),
  its contribution is set to 0.0. Contributions are NOT renormalized — i.e., the
  sum of remaining contributions is applied to the baseline as-is. This preserves
  the baseline semantics and avoids surprising renormalization effects.

Clamping and grading:
- rawScore is clamped to [0.0, 100.0] and then rounded to an integer `score`.
- Grade buckets: A >= 90, B >= 80, C >= 70, D >= 50, otherwise F.

Calibration:
- Baseline and globalScale were found by grid search to approximate legacy
  weighted-average outputs across representative portfolios. Typical defaults
  used in tests/settings: baseline=75.0, globalScale=0.6.

When modifying impacts or mapping functions, update the calibration/regression
tests under `test/` to avoid accidental score drift.
*/

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
    // Contribution model will respect user mute settings via intlMutedFlag.

    // ------------------------------------------------------------------
    // New contribution-based scoring model (non-renormalizing when muted)
    // Baseline + per-dial contributions. This avoids renormalization surprises.
    // ------------------------------------------------------------------

    // Compute inputs for the contribution model
    final income = settings.monthlyIncome ??
        settings.monthlyEssentials * settings.incomeMultiplierFallback;
    final debtToIncome =
        income > 0 ? debtLoadResult.monthlyDebtService / income : 0.0;
    final liquidityMonths = liquidityResult.monthsOfEssentials;
    final fixedIncomeShare = fixedIncomeResult.bondPct; // 0..1

    // Compute HHI concentration across major buckets
    final percentages = AllocationCalculator.calculatePercentages(accounts);
    double hhi = 0.0;
    for (final v in percentages.values) {
      hhi += v * v;
    }

    final equityAlloc =
        AllocationCalculator.calculateEquityAllocation(accounts);
    final intlShare = equityAlloc['intlEq'] ?? 0.0; // 0..1 (of equities)

    final intlMutedFlag =
        settings.globalDiversificationMode.toLowerCase() == 'off';

    // Score weights (max absolute contribution per dial)
    // Calibrated baseline and a global scale found by grid search.
    final baseline = settings.financialHealthBaseline;
    final double globalScale = settings.financialHealthGlobalScale;
    final debtImpact = 12.0 * globalScale;
    final liquidityImpact = 10.0 * globalScale;
    final fixedImpact = 8.0 * globalScale;
    final concentrationImpact = 10.0 * globalScale;
    final intlImpact = 6.0 * globalScale;

    // Helper mappers (ported from suggested pseudo-code)
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

    // Compute contributions
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
      value: 1.0 -
          hhi, // use diversity (1-HHI) so lower HHI -> lower contribution mapping reversed
      target: 1.0 - 0.12, // target diversity equivalent to HHI~0.12
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

    final contributions = {
      'Debt Load': debtContribution,
      'Liquidity': liqContribution,
      'Fixed Income': fixedContribution,
      'Concentration': concContribution,
      'Home Bias': intlContribution,
    };

    double rawScore =
        baseline + contributions.values.fold(0.0, (s, v) => s + v);
    final intScore = rawScore.clamp(0.0, 100.0).round();

    // Debug log only in debug builds
    if (kDebugMode) {
      debugPrint(
        '[OverallHealth(contrib)] baseline=$baseline debt=${debtContribution.toStringAsFixed(2)} conc=${concContribution.toStringAsFixed(2)} liq=${liqContribution.toStringAsFixed(2)} fixed=${fixedContribution.toStringAsFixed(2)} home=${intlContribution.toStringAsFixed(2)} => raw=${rawScore.toStringAsFixed(2)} disp=$intScore',
      );
    }

    final grade = _scoreToGrade(intScore);
    final description = _getDescription(grade, intScore);
    final summary = _getSummary(grade);

    // Keep original 0..100 per-component scores for UI, and expose signed contributions too
    final componentScores = {
      'Debt Load': debtScore.round(),
      'Concentration': concentrationScore.round(),
      'Liquidity': liquidityScore.round(),
      'Fixed Income': fixedIncomeScore.round(),
      'Home Bias': intlMutedFlag ? 100 : homeBiasScore.round(),
    };

    final componentContributions = contributions.map((k, v) => MapEntry(k, v));

    return FinancialHealthResult(
      score: intScore,
      grade: grade,
      description: description,
      summary: summary,
      componentScores: componentScores,
      componentContributions: componentContributions,
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
