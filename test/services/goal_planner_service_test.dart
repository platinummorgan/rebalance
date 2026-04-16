import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/services/goal_planner_service.dart';

void main() {
  group('GoalPlannerService', () {
    test('higher monthly contribution increases success probability', () {
      final asOf = DateTime(2026, 1, 1);
      final targetDate = DateTime(2036, 1, 1);

      final low = GoalPlannerService.calculate(
        input: GoalPlannerInput(
          currentAmount: 10000,
          targetAmount: 250000,
          monthlyContribution: 250,
          targetDate: targetDate,
          simulations: 800,
          seed: 7,
          desiredConfidence: 0.75,
        ),
        asOf: asOf,
      );

      final high = GoalPlannerService.calculate(
        input: GoalPlannerInput(
          currentAmount: 10000,
          targetAmount: 250000,
          monthlyContribution: 1200,
          targetDate: targetDate,
          simulations: 800,
          seed: 7,
          desiredConfidence: 0.75,
        ),
        asOf: asOf,
      );

      expect(high.successProbability, greaterThan(low.successProbability));
    });

    test('required monthly contribution achieves desired confidence', () {
      final asOf = DateTime(2026, 1, 1);
      final targetDate = DateTime(2034, 1, 1);

      final baseline = GoalPlannerService.calculate(
        input: GoalPlannerInput(
          currentAmount: 15000,
          targetAmount: 200000,
          monthlyContribution: 300,
          targetDate: targetDate,
          simulations: 1000,
          seed: 99,
          desiredConfidence: 0.8,
        ),
        asOf: asOf,
      );

      final withRequiredContribution = GoalPlannerService.calculate(
        input: GoalPlannerInput(
          currentAmount: 15000,
          targetAmount: 200000,
          monthlyContribution: baseline.requiredMonthlyContribution,
          targetDate: targetDate,
          simulations: 1000,
          seed: 99,
          desiredConfidence: 0.8,
        ),
        asOf: asOf,
      );

      expect(
        withRequiredContribution.successProbability,
        greaterThanOrEqualTo(0.78),
      );
      expect(
        withRequiredContribution.requiredMonthlyContribution,
        closeTo(baseline.requiredMonthlyContribution, 1.0),
      );
    });

    test('throws when target date is not in the future', () {
      final asOf = DateTime(2026, 1, 1);
      final targetDate = DateTime(2026, 1, 1);

      expect(
        () => GoalPlannerService.calculate(
          input: GoalPlannerInput(
            currentAmount: 1000,
            targetAmount: 10000,
            monthlyContribution: 100,
            targetDate: targetDate,
          ),
          asOf: asOf,
        ),
        throwsArgumentError,
      );
    });
  });
}
