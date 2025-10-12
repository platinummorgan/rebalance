import 'dart:math';

class MonteCarloResult {
  final double successProbability; // 0-1
  final double medianEnding; // 50th percentile wealth
  final double p10Ending; // 10th percentile (downside)
  final double p90Ending; // 90th percentile (upside)
  final List<double> endingValues; // raw ending values for optional charts
  final int simulations;
  final int years;

  MonteCarloResult({
    required this.successProbability,
    required this.medianEnding,
    required this.p10Ending,
    required this.p90Ending,
    required this.endingValues,
    required this.simulations,
    required this.years,
  });
}

class MonteCarloEngine {
  /// Runs a simple Monte Carlo projection.
  /// Assumptions:
  /// - Monthly contribution invested at start of month
  /// - Annual return modeled as normal distribution with [expectedReturn] mean and [stdev] std dev
  /// - Worst year drawdown influences stdev if provided (approximate mapping)
  static MonteCarloResult run({
    required double startingBalance,
    required double monthlyContribution,
    required double expectedReturn, // e.g. 0.07 for 7%
    required double stdev, // annual volatility e.g. 0.15
    required int years,
    required double goalAmount,
    int simulations = 1000,
    int seed = 42,
  }) {
    final rand = Random(seed);
    final endingValues = <double>[];
    int successCount = 0;
    final months = years * 12;
    final monthlyMu =
        pow(1 + expectedReturn, 1 / 12) - 1; // geometric approximation
    final monthlySigma = stdev / sqrt(12);

    for (int s = 0; s < simulations; s++) {
      double balance = startingBalance;
      for (int m = 0; m < months; m++) {
        // Contribution at start of month
        balance += monthlyContribution;
        // Simulate return for month
        // Using log-normal approximation: r = exp(mu - 0.5*sigma^2 + sigma*Z) - 1
        final z = _boxMuller(rand);
        final monthlyReturn = exp(
                (monthlyMu - 0.5 * monthlySigma * monthlySigma) +
                    monthlySigma * z,) -
            1;
        balance *= (1 + monthlyReturn);
      }
      endingValues.add(balance);
      if (balance >= goalAmount) successCount++;
    }

    endingValues.sort();
    double pct(double p) =>
        endingValues[(p * (endingValues.length - 1)).round()];

    return MonteCarloResult(
      successProbability: successCount / simulations,
      medianEnding: pct(0.50),
      p10Ending: pct(0.10),
      p90Ending: pct(0.90),
      endingValues: endingValues,
      simulations: simulations,
      years: years,
    );
  }

  static double _boxMuller(Random rand) {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
  }
}
