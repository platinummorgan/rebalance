import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/financial_health.dart';
// import 'package:rebalance/data/calculators/homebias.dart';

void main() {
  test('debug score diff', () {
    // Build accounts per user's numbers
    final accounts = <Account>[];

    accounts.add(
      Account(
        id: 'a1',
        name: '401k',
        kind: 'retirement',
        balance: 15000,
        pctCash: 0.0,
        pctBonds: 0.0,
        pctUsEq: 1.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
        isLocked: true,
      ),
    );

    accounts.add(
      Account(
        id: 'a2',
        name: 'Checking',
        kind: 'cash',
        balance: 5000,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    accounts.add(
      Account(
        id: 'a3',
        name: 'Brokerage',
        kind: 'brokerage',
        balance: 25000,
        pctCash: 0.0,
        pctBonds: 0.0,
        pctUsEq: 1.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    accounts.add(
      Account(
        id: 'a4',
        name: 'Savings',
        kind: 'savings',
        balance: 80000,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    final liabilities = <Liability>[];

    final settingsStandard = Settings(
      riskBand: RiskBand.growth,
      monthlyEssentials: 3000,
    );

    final settingsMuted = Settings(
      riskBand: RiskBand.growth,
      monthlyEssentials: 3000,
      globalDiversificationMode: 'off',
    );

    final resStandard = FinancialHealthCalculator.calculateOverallHealth(
      accounts,
      liabilities,
      settingsStandard,
    );

    final resMuted = FinancialHealthCalculator.calculateOverallHealth(
      accounts,
      liabilities,
      settingsMuted,
    );

    // Ensure results are valid and used by the test
    expect(resStandard.score, isA<int>());
    expect(resMuted.score, isA<int>());
  });
}
