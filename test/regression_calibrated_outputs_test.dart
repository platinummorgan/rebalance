import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/financial_health.dart';

// Regression tests to lock calibrated outputs from contribution model.
void main() {
  test('calibrated outputs for representative portfolios', () {
    // user portfolio (from reproduce test setup)
    final userAccounts = [
      Account(
        id: 'acct1',
        name: '401k',
        kind: 'retirement',
        balance: 15000.0,
        pctCash: 0.0,
        pctBonds: 0.30,
        pctUsEq: 0.40,
        pctIntlEq: 0.30,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'acct2',
        name: 'Brokerage',
        kind: 'brokerage',
        balance: 70000.0,
        pctCash: 0.05,
        pctBonds: 0.20,
        pctUsEq: 0.45,
        pctIntlEq: 0.30,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final userLiabilities = [
      Liability(
        id: 'loan1',
        name: 'Mortgage',
        kind: 'mortgage',
        balance: 52000.0,
        apr: 3.5,
        minPayment: 1200.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final settings = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 3000.0,
      monthlyIncome: 6000.0,
      incomeMultiplierFallback: 2.0,
      globalDiversificationMode: 'standard',
    );

    final userResult = FinancialHealthCalculator.calculateOverallHealth(
      userAccounts,
      userLiabilities,
      settings,
    );

    // Expect contribution model to produce the calibrated output (locked)
    // (observed value from current calibration run)
    expect(userResult.score, closeTo(89, 1.0));

    // healthy portfolio

    final healthyAccounts = [
      Account(
        id: 'h1',
        name: 'Savings',
        kind: 'savings',
        balance: 100000.0,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];
    final healthyLiabilities = <Liability>[];

    final healthyResult = FinancialHealthCalculator.calculateOverallHealth(
      healthyAccounts,
      healthyLiabilities,
      settings,
    );

    expect(healthyResult.score, closeTo(63, 1.0));

    // concentrated portfolio
    final concAccounts = [
      Account(
        id: 'c1',
        name: 'All-in Employer',
        kind: 'brokerage',
        balance: 100000.0,
        pctCash: 0.0,
        pctBonds: 0.0,
        pctUsEq: 1.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final concResult = FinancialHealthCalculator.calculateOverallHealth(
      concAccounts,
      <Liability>[],
      settings,
    );

    expect(concResult.score, closeTo(51, 1.0));
  });

  test('muting home bias does not renormalize other contributions', () {
    final accounts = [
      Account(
        id: 'a1',
        name: 'Acct',
        kind: 'brokerage',
        balance: 50000.0,
        pctCash: 0.02,
        pctBonds: 0.08,
        pctUsEq: 0.70,
        pctIntlEq: 0.20,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final settingsOff = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 2000.0,
      monthlyIncome: 5000.0,
      incomeMultiplierFallback: 2.0,
      globalDiversificationMode: 'off',
    );

    final settingsOn = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 2000.0,
      monthlyIncome: 5000.0,
      incomeMultiplierFallback: 2.0,
      globalDiversificationMode: 'standard',
    );

    final resOff = FinancialHealthCalculator.calculateOverallHealth(
        accounts, <Liability>[], settingsOff,);
    final resOn = FinancialHealthCalculator.calculateOverallHealth(
        accounts, <Liability>[], settingsOn,);

    // Home Bias score in 'off' mode becomes 100
    expect(resOff.componentScores['Home Bias'], 100);

    // Other component scores should be identical (no renormalization)
    for (final key in resOff.componentScores.keys) {
      if (key == 'Home Bias') continue;
      expect(resOff.componentScores[key], resOn.componentScores[key]);
    }
  });
}
