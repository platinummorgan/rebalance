/// Centralized scoring & threshold constants for financial health components.
/// Adjusting these values should be followed by corresponding test updates.
class ScoringConstants {
  ScoringConstants._();

  // High APR (annual) threshold beyond which debt score ceiling applies.
  static const double highAprThreshold = 0.195; // 19.5%

  // Credit utilization soft penalty starts after this level (70%)
  static const double creditUtilizationPenaltyStart = 0.70;

  // Extreme utilization ceiling threshold (>90%)
  static const double creditUtilizationSevere = 0.90;

  // Ceiling when high APR debt exists
  static const double highAprDebtScoreCap = 35.0;

  // Ceiling when utilization extremely high (> 90%)
  static const double severeUtilizationDebtScoreCap = 25.0;

  // Leverage normal region bounds (debt/assets multiple)
  static const double leverageBest = 0.20; // 20% leverage -> 100 score
  static const double leverageWorst =
      0.90; // 90% leverage -> 0 in normal region

  // Tail leverage region (extreme) where we still allow recovery points
  static const double leverageTailMax = 5.0; // 5x assets
  static const double leverageTailCeiling = 25.0; // Max points in tail

  // DSCR (Discretionary Income / Debt Service) bounds
  static const double dscrWorst = 0.8; // -> score 0
  static const double dscrBest = 1.5; // -> score 100

  // Weights inside blended debt score
  static const double leverageWeight = 0.6;
  static const double dscrWeight = 0.4;
}
