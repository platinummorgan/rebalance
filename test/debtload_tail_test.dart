import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/calculators/debtload.dart';
import 'package:rebalance/data/models.dart';

void main() {
  group('DebtLoad leverage linear scoring (v1.1)', () {
    final settings = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 5000.0,
      monthlyIncome: 15000.0,
      incomeMultiplierFallback: 3.0,
    );

    test('leverage score is 0 beyond 90% and rises linearly into band', () {
      final accounts = [
        Account(
          id: 'a1',
          name: 'Brokerage',
          kind: 'brokerage',
          balance: 53000.0, // assets constant
          pctCash: 0.10,
          pctBonds: 0.10,
          pctUsEq: 0.60,
          pctIntlEq: 0.10,
          pctRealEstate: 0.05,
          pctAlt: 0.05,
          updatedAt: DateTime.now(),
        ),
      ];

      // Scenario 1: very high leverage (≈4.55x)
      final liabilitiesHigh = [
        Liability(
          id: 'l1',
          name: 'Mortgage',
          kind: 'mortgage',
          balance: 241000.0,
          apr: 0.065,
          minPayment: 1500.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final resultHigh = DebtLoadCalculator.calculateDebtLoad(
        accounts,
        liabilitiesHigh,
        5000.0,
        settings,
      );
      final leverageScoreHigh = resultHigh.leverageScore;
      expect(leverageScoreHigh, equals(0)); // >90% leverage maps to 0

      // Scenario 2: reduced debt (≈4.1x) still >90% leverage so score remains 0
      final liabilitiesLower = [
        Liability(
          id: 'l1',
          name: 'Mortgage',
          kind: 'mortgage',
          balance: 217500.0,
          apr: 0.065,
          minPayment: 1500.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final resultLower = DebtLoadCalculator.calculateDebtLoad(
        accounts,
        liabilitiesLower,
        5000.0,
        settings,
      );
      final leverageScoreLower = resultLower.leverageScore;
      expect(leverageScoreLower, equals(0));

      // Scenario 3: leverage inside band (<90%), expect positive score
      final liabilitiesBand = [
        Liability(
          id: 'l1',
          name: 'Mortgage',
          kind: 'mortgage',
          balance: 40000.0, // leverage ≈0.75 -> should yield >0
          apr: 0.065,
          minPayment: 500.0,
          updatedAt: DateTime.now(),
        ),
      ];
      final resultBand = DebtLoadCalculator.calculateDebtLoad(
        accounts,
        liabilitiesBand,
        5000.0,
        settings,
      );
      final leverageScoreBand = resultBand.leverageScore;
      expect(leverageScoreBand, greaterThan(0));
      // Composite score should now exceed the previous high leverage case
      expect(resultBand.score, greaterThan(resultHigh.score));
    });
  });
}
