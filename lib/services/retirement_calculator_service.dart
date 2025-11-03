import 'dart:math';

/// Service for retirement planning calculations using Monte Carlo simulation
class RetirementCalculatorService {
  static const int _simulationCount = 1000;
  static const double _defaultReturnMean = 0.07; // 7% average return
  static const double _defaultReturnStdDev = 0.15; // 15% volatility
  static const double _defaultInflation = 0.03; // 3% inflation

  /// Calculate retirement projections using Monte Carlo simulation
  ///
  /// Returns a [RetirementResult] with probability of success and outcome ranges
  static RetirementResult calculate({
    required double currentSavings,
    required double monthlyContribution,
    required int yearsUntilRetirement,
    required double desiredMonthlyIncome,
    required int retirementDuration,
    double annualReturnMean = _defaultReturnMean,
    double annualReturnStdDev = _defaultReturnStdDev,
    double inflationRate = _defaultInflation,
  }) {
    final random = Random();
    final results = <double>[];

    // Run Monte Carlo simulations
    for (int i = 0; i < _simulationCount; i++) {
      results.add(_runSingleSimulation(
        currentSavings: currentSavings,
        monthlyContribution: monthlyContribution,
        yearsUntilRetirement: yearsUntilRetirement,
        desiredMonthlyIncome: desiredMonthlyIncome,
        retirementDuration: retirementDuration,
        annualReturnMean: annualReturnMean,
        annualReturnStdDev: annualReturnStdDev,
        inflationRate: inflationRate,
        random: random,
      ));
    }

    // Sort results for percentile analysis
    results.sort();

    // Calculate statistics
    final successCount = results.where((r) => r >= 0).length;
    final probabilityOfSuccess = successCount / _simulationCount;

    final medianIndex = (_simulationCount / 2).floor();
    final percentile10Index = (_simulationCount * 0.1).floor();
    final percentile90Index = (_simulationCount * 0.9).floor();

    return RetirementResult(
      probabilityOfSuccess: probabilityOfSuccess,
      medianFinalBalance: results[medianIndex],
      percentile10Balance: results[percentile10Index],
      percentile90Balance: results[percentile90Index],
      totalContributions:
          currentSavings + (monthlyContribution * 12 * yearsUntilRetirement),
      projectedAtRetirement: _calculateAccumulationPhase(
        currentSavings: currentSavings,
        monthlyContribution: monthlyContribution,
        years: yearsUntilRetirement,
        annualReturn: annualReturnMean,
      ),
    );
  }

  /// Run a single simulation scenario
  static double _runSingleSimulation({
    required double currentSavings,
    required double monthlyContribution,
    required int yearsUntilRetirement,
    required double desiredMonthlyIncome,
    required int retirementDuration,
    required double annualReturnMean,
    required double annualReturnStdDev,
    required double inflationRate,
    required Random random,
  }) {
    // Phase 1: Accumulation (before retirement)
    double balance = currentSavings;
    for (int month = 0; month < yearsUntilRetirement * 12; month++) {
      // Generate random monthly return using normal distribution
      final monthlyReturn = _generateNormalReturn(
        annualReturnMean,
        annualReturnStdDev,
        random,
      );

      // Apply return and add contribution
      balance = balance * (1 + monthlyReturn) + monthlyContribution;
    }

    // Phase 2: Withdrawal (during retirement)
    double inflationAdjustedIncome = desiredMonthlyIncome;
    for (int month = 0; month < retirementDuration * 12; month++) {
      // Generate random monthly return
      final monthlyReturn = _generateNormalReturn(
        annualReturnMean,
        annualReturnStdDev,
        random,
      );

      // Adjust income for inflation annually
      if (month > 0 && month % 12 == 0) {
        inflationAdjustedIncome *= (1 + inflationRate);
      }

      // Apply return and withdraw income
      balance = balance * (1 + monthlyReturn) - inflationAdjustedIncome;

      // Stop if balance goes negative
      if (balance < 0) {
        return balance; // Failed scenario
      }
    }

    return balance; // Final balance after retirement period
  }

  /// Generate a random return using normal distribution approximation
  static double _generateNormalReturn(
    double annualMean,
    double annualStdDev,
    Random random,
  ) {
    // Convert annual to monthly
    final monthlyMean = annualMean / 12;
    final monthlyStdDev = annualStdDev / sqrt(12);

    // Box-Muller transform for normal distribution
    final u1 = random.nextDouble();
    final u2 = random.nextDouble();
    final z0 = sqrt(-2 * log(u1)) * cos(2 * pi * u2);

    return monthlyMean + (z0 * monthlyStdDev);
  }

  /// Calculate simple accumulation phase projection (no randomness)
  static double _calculateAccumulationPhase({
    required double currentSavings,
    required double monthlyContribution,
    required int years,
    required double annualReturn,
  }) {
    final monthlyRate = annualReturn / 12;
    final months = years * 12;

    // Future value of current savings
    final fvSavings = currentSavings * pow(1 + monthlyRate, months);

    // Future value of monthly contributions (annuity)
    final fvContributions = monthlyContribution *
        ((pow(1 + monthlyRate, months) - 1) / monthlyRate);

    return fvSavings + fvContributions;
  }

  /// Calculate recommended monthly savings to reach goal
  static double calculateRequiredSavings({
    required double currentSavings,
    required int yearsUntilRetirement,
    required double retirementGoal,
    double annualReturn = _defaultReturnMean,
  }) {
    final monthlyRate = annualReturn / 12;
    final months = yearsUntilRetirement * 12;

    // Future value of current savings
    final fvSavings = currentSavings * pow(1 + monthlyRate, months);

    // Remaining amount needed
    final remaining = retirementGoal - fvSavings;

    if (remaining <= 0) {
      return 0; // Already have enough
    }

    // Calculate monthly payment needed (solve for PMT in annuity formula)
    final requiredMonthly =
        remaining / ((pow(1 + monthlyRate, months) - 1) / monthlyRate);

    return requiredMonthly;
  }

  /// Calculate the "4% rule" safe withdrawal amount
  static double calculateSafeWithdrawal(double portfolioValue) {
    return portfolioValue * 0.04 / 12; // 4% annually, divided by 12 months
  }

  /// Estimate how many years savings will last
  static int estimateYearsOfSavings({
    required double currentSavings,
    required double monthlyWithdrawal,
    double annualReturn = _defaultReturnMean,
  }) {
    final monthlyRate = annualReturn / 12;
    double balance = currentSavings;
    int months = 0;

    while (balance > 0 && months < 1200) {
      // Cap at 100 years
      balance = balance * (1 + monthlyRate) - monthlyWithdrawal;
      months++;
    }

    return (months / 12).floor();
  }
}

/// Result from retirement calculator simulation
class RetirementResult {
  /// Probability of not running out of money (0.0 to 1.0)
  final double probabilityOfSuccess;

  /// Median final balance across all simulations
  final double medianFinalBalance;

  /// 10th percentile balance (pessimistic scenario)
  final double percentile10Balance;

  /// 90th percentile balance (optimistic scenario)
  final double percentile90Balance;

  /// Total amount contributed (initial + monthly * years)
  final double totalContributions;

  /// Projected balance at retirement (deterministic)
  final double projectedAtRetirement;

  const RetirementResult({
    required this.probabilityOfSuccess,
    required this.medianFinalBalance,
    required this.percentile10Balance,
    required this.percentile90Balance,
    required this.totalContributions,
    required this.projectedAtRetirement,
  });

  /// Whether the plan is likely to succeed (>80% probability)
  bool get isOnTrack => probabilityOfSuccess >= 0.80;

  /// Whether the plan needs serious attention (<50% probability)
  bool get needsAttention => probabilityOfSuccess < 0.50;

  /// Get a grade for the retirement plan
  String get grade {
    if (probabilityOfSuccess >= 0.90) return 'A';
    if (probabilityOfSuccess >= 0.80) return 'B';
    if (probabilityOfSuccess >= 0.70) return 'C';
    if (probabilityOfSuccess >= 0.60) return 'D';
    return 'F';
  }

  /// Get a color-coded assessment
  String get assessment {
    if (probabilityOfSuccess >= 0.85) return 'Excellent';
    if (probabilityOfSuccess >= 0.75) return 'Good';
    if (probabilityOfSuccess >= 0.65) return 'Fair';
    if (probabilityOfSuccess >= 0.50) return 'Concerning';
    return 'Critical';
  }
}
