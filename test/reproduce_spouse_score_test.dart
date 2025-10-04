import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/financial_health.dart';

void main() {
  test('reproduce spouse example', () {
    final accounts = [
      Account(
        id: 'a_inheritance',
        name: 'Inheritance',
        kind: 'brokerage',
        balance: 500000.0,
        pctCash: 0.05,
        pctBonds: 0.25,
        pctUsEq: 0.55,
        pctIntlEq: 0.15,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'a_401k',
        name: '401k',
        kind: 'retirement',
        balance: 400000.0,
        pctCash: 0.05,
        pctBonds: 0.30,
        pctUsEq: 0.50,
        pctIntlEq: 0.15,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final liabilities = [
      Liability(
        id: 'l1',
        name: 'Loan',
        kind: 'mortgage',
        balance: 122000.0,
        apr: 0.04,
        minPayment: 700.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final settings = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 5000.0,
    );

    final result = FinancialHealthCalculator.calculateOverallHealth(
      accounts,
      liabilities,
      settings,
    );

    // Print out detailed breakdown
    print('Overall score: ${result.score}');
    print('Grade: ${result.grade}');
    print('Summary: ${result.summary}');
    print('Description: ${result.description}');
    print('Component scores:');
    result.componentScores.forEach((k, v) {
      final weight = FinancialHealthCalculator.componentWeights[k] ?? 0.0;
      final contribution = (weight * v).toStringAsFixed(2);
      print(
          ' - $k: $v (weight ${(weight * 100).toStringAsFixed(0)}% -> contribution $contribution)',);
    });

    // Sanity assert
    expect(result.score, isA<int>());
  });
}
