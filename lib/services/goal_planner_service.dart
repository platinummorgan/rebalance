import 'dart:math';

import '../data/models.dart';

class GoalPlannerInput {
  final double currentAmount;
  final double targetAmount;
  final double monthlyContribution;
  final DateTime targetDate;
  final double expectedAnnualReturn;
  final double annualVolatility;
  final int simulations;
  final int seed;
  final double desiredConfidence;

  const GoalPlannerInput({
    required this.currentAmount,
    required this.targetAmount,
    required this.monthlyContribution,
    required this.targetDate,
    this.expectedAnnualReturn = 0.07,
    this.annualVolatility = 0.15,
    this.simulations = 1000,
    this.seed = 42,
    this.desiredConfidence = 0.75,
  });
}

class GoalPlannerResult {
  final double targetAmount;
  final double assumedMonthlyContribution;
  final double successProbability;
  final double medianEndingValue;
  final double p10EndingValue;
  final double p90EndingValue;
  final double requiredMonthlyContribution;
  final int monthsToGoal;
  final int simulations;
  final double desiredConfidence;

  const GoalPlannerResult({
    required this.targetAmount,
    required this.assumedMonthlyContribution,
    required this.successProbability,
    required this.medianEndingValue,
    required this.p10EndingValue,
    required this.p90EndingValue,
    required this.requiredMonthlyContribution,
    required this.monthsToGoal,
    required this.simulations,
    required this.desiredConfidence,
  });

  bool get isOnTrack => successProbability >= desiredConfidence;
  double get medianShortfall => max(0, targetAmount - medianEndingValue);
}

class GoalPlannerService {
  static GoalPlannerResult calculate({
    required GoalPlannerInput input,
    DateTime? asOf,
  }) {
    _validateInput(input);
    final now = asOf ?? DateTime.now();
    final monthsToGoal = _monthsUntil(now, input.targetDate);
    if (monthsToGoal <= 0) {
      throw ArgumentError('targetDate must be in the future.');
    }

    final run = _runProjection(
      startingBalance: input.currentAmount,
      monthlyContribution: input.monthlyContribution,
      targetAmount: input.targetAmount,
      expectedAnnualReturn: input.expectedAnnualReturn,
      annualVolatility: input.annualVolatility,
      months: monthsToGoal,
      simulations: input.simulations,
      seed: input.seed,
    );

    final requiredContribution = _requiredMonthlyContribution(
      input: input,
      monthsToGoal: monthsToGoal,
      currentProbability: run.successProbability,
    );

    return GoalPlannerResult(
      targetAmount: input.targetAmount,
      assumedMonthlyContribution: input.monthlyContribution,
      successProbability: run.successProbability,
      medianEndingValue: run.medianEnding,
      p10EndingValue: run.p10Ending,
      p90EndingValue: run.p90Ending,
      requiredMonthlyContribution: requiredContribution,
      monthsToGoal: monthsToGoal,
      simulations: input.simulations,
      desiredConfidence: input.desiredConfidence,
    );
  }

  static GoalPlannerResult calculateForHouseholdGoal({
    required HouseholdGoal goal,
    required double monthlyContribution,
    DateTime? asOf,
    DateTime? targetDate,
    double expectedAnnualReturn = 0.07,
    double annualVolatility = 0.15,
    int simulations = 1000,
    int seed = 42,
    double desiredConfidence = 0.75,
  }) {
    final effectiveTargetDate =
        targetDate ?? DateTime((asOf ?? DateTime.now()).year + 10);
    return calculate(
      input: GoalPlannerInput(
        currentAmount: goal.currentAmount,
        targetAmount: goal.targetAmount,
        monthlyContribution: monthlyContribution,
        targetDate: effectiveTargetDate,
        expectedAnnualReturn: expectedAnnualReturn,
        annualVolatility: annualVolatility,
        simulations: simulations,
        seed: seed,
        desiredConfidence: desiredConfidence,
      ),
      asOf: asOf,
    );
  }

  static void _validateInput(GoalPlannerInput input) {
    if (input.currentAmount < 0) {
      throw ArgumentError('currentAmount cannot be negative.');
    }
    if (input.targetAmount <= 0) {
      throw ArgumentError('targetAmount must be greater than zero.');
    }
    if (input.monthlyContribution < 0) {
      throw ArgumentError('monthlyContribution cannot be negative.');
    }
    if (input.simulations <= 0) {
      throw ArgumentError('simulations must be greater than zero.');
    }
    if (input.annualVolatility < 0) {
      throw ArgumentError('annualVolatility cannot be negative.');
    }
    if (input.desiredConfidence <= 0 || input.desiredConfidence >= 1) {
      throw ArgumentError('desiredConfidence must be between 0 and 1.');
    }
    if (input.expectedAnnualReturn <= -1) {
      throw ArgumentError('expectedAnnualReturn must be greater than -1.');
    }
  }

  static int _monthsUntil(DateTime from, DateTime to) {
    final fromMonthStart = DateTime(from.year, from.month, 1);
    final toMonthStart = DateTime(to.year, to.month, 1);
    return (toMonthStart.year - fromMonthStart.year) * 12 +
        (toMonthStart.month - fromMonthStart.month);
  }

  static _ProjectionRun _runProjection({
    required double startingBalance,
    required double monthlyContribution,
    required double targetAmount,
    required double expectedAnnualReturn,
    required double annualVolatility,
    required int months,
    required int simulations,
    required int seed,
  }) {
    final rand = Random(seed);
    final endingValues = <double>[];
    int successCount = 0;

    final monthlyMu = pow(1 + expectedAnnualReturn, 1 / 12) - 1;
    final monthlySigma = annualVolatility / sqrt(12);

    for (int s = 0; s < simulations; s++) {
      double balance = startingBalance;
      for (int m = 0; m < months; m++) {
        balance += monthlyContribution;
        final z = _boxMuller(rand);
        final monthlyReturn = exp(
              (monthlyMu - 0.5 * monthlySigma * monthlySigma) +
                  monthlySigma * z,
            ) -
            1;
        balance *= (1 + monthlyReturn);
      }
      endingValues.add(balance);
      if (balance >= targetAmount) {
        successCount++;
      }
    }

    endingValues.sort();

    double percentile(double p) =>
        endingValues[(p * (endingValues.length - 1)).round()];

    return _ProjectionRun(
      successProbability: successCount / simulations,
      medianEnding: percentile(0.5),
      p10Ending: percentile(0.1),
      p90Ending: percentile(0.9),
    );
  }

  static double _requiredMonthlyContribution({
    required GoalPlannerInput input,
    required int monthsToGoal,
    required double currentProbability,
  }) {
    if (currentProbability >= input.desiredConfidence) {
      return input.monthlyContribution;
    }

    double low = input.monthlyContribution;
    double high = max(1, input.monthlyContribution);

    double highProbability = currentProbability;
    int guard = 0;
    while (highProbability < input.desiredConfidence &&
        high < 1e7 &&
        guard < 40) {
      high *= 2;
      highProbability = _runProjection(
        startingBalance: input.currentAmount,
        monthlyContribution: high,
        targetAmount: input.targetAmount,
        expectedAnnualReturn: input.expectedAnnualReturn,
        annualVolatility: input.annualVolatility,
        months: monthsToGoal,
        simulations: input.simulations,
        seed: input.seed,
      ).successProbability;
      guard++;
    }

    if (highProbability < input.desiredConfidence) {
      return high;
    }

    for (int i = 0; i < 25; i++) {
      final mid = (low + high) / 2;
      final probability = _runProjection(
        startingBalance: input.currentAmount,
        monthlyContribution: mid,
        targetAmount: input.targetAmount,
        expectedAnnualReturn: input.expectedAnnualReturn,
        annualVolatility: input.annualVolatility,
        months: monthsToGoal,
        simulations: input.simulations,
        seed: input.seed,
      ).successProbability;

      if (probability >= input.desiredConfidence) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return high;
  }

  static double _boxMuller(Random rand) {
    final u1 = rand.nextDouble();
    final u2 = rand.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }
}

class _ProjectionRun {
  final double successProbability;
  final double medianEnding;
  final double p10Ending;
  final double p90Ending;

  const _ProjectionRun({
    required this.successProbability,
    required this.medianEnding,
    required this.p10Ending,
    required this.p90Ending,
  });
}
