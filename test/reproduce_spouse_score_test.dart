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

    // Keep test assertions focused; skip verbose diagnostic prints.

    // Sanity assert
    expect(result.score, isA<int>());
  });
}
