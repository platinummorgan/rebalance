import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/calculators/debtload.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/core/constants/scoring_constants.dart';

void main() {
  final baseSettings = Settings(
    riskBand: RiskBand.balanced,
    monthlyEssentials: 5000.0,
    monthlyIncome: 15000.0,
    incomeMultiplierFallback: 3.0,
  );

  Account acct(double balance) => Account(
        id: 'a',
        name: 'Acct',
        kind: 'brokerage',
        balance: balance,
        pctCash: 0.10,
        pctBonds: 0.10,
        pctUsEq: 0.60,
        pctIntlEq: 0.10,
        pctRealEstate: 0.05,
        pctAlt: 0.05,
        updatedAt: DateTime.now(),
      );

  group('DebtLoad edge cases', () {
    test('Zero debt and zero assets yields perfect score', () {
      final settings = baseSettings;
      final result = DebtLoadCalculator.calculateDebtLoad(
        [acct(0)],
        const [],
        5000,
        settings,
      );
      expect(result.totalDebt, equals(0));
      expect(result.totalAssets, equals(0));
      expect(result.score, equals(100));
      expect(result.leverageScore, equals(100));
      expect(result.dscrScore, equals(100));
    });
    test('High APR debt caps score', () {
      final liabilities = [
        Liability(
          id: 'l1',
          name: 'Card',
          kind: 'creditCard',
          balance: 3000,
          apr: ScoringConstants.highAprThreshold + 0.05,
          minPayment: 80,
          creditLimit: 10000,
          updatedAt: DateTime.now(),
        ),
      ];
      final result = DebtLoadCalculator.calculateDebtLoad(
        [acct(50000)],
        liabilities,
        5000,
        baseSettings,
      );
      expect(
        result.score,
        lessThanOrEqualTo(ScoringConstants.highAprDebtScoreCap),
      );
    });

    test('Severe utilization caps score', () {
      final liabilities = [
        Liability(
          id: 'l1',
          name: 'Card',
          kind: 'creditCard',
          balance: 9100,
          apr: 0.10,
          minPayment: 120,
          creditLimit: 10000,
          updatedAt: DateTime.now(),
        ),
      ];
      final result = DebtLoadCalculator.calculateDebtLoad(
        [acct(50000)],
        liabilities,
        5000,
        baseSettings,
      );
      expect(
        result.score,
        lessThanOrEqualTo(ScoringConstants.severeUtilizationDebtScoreCap),
      );
    });

    test('DSCR worst and best boundaries', () {
      // Construct liabilities so debt service is sizable relative to income.
      final liabilities = [
        Liability(
          id: 'l1',
          name: 'Loan',
          kind: 'personal',
          balance: 10000,
          apr: 0.08,
          minPayment: 400, // debt service
          updatedAt: DateTime.now(),
        ),
      ];
      // Income tuned so discretionary/debtService toggles around thresholds
      final lowSettings = Settings(
        riskBand: baseSettings.riskBand,
        monthlyEssentials: baseSettings.monthlyEssentials,
        monthlyIncome: 7000,
        incomeMultiplierFallback: baseSettings.incomeMultiplierFallback,
        liquidityBondHaircut: baseSettings.liquidityBondHaircut,
        bucketCap: baseSettings.bucketCap,
        employerStockThreshold: baseSettings.employerStockThreshold,
        darkModeEnabled: baseSettings.darkModeEnabled,
        isPro: baseSettings.isPro,
        biometricLockEnabled: baseSettings.biometricLockEnabled,
        notificationsEnabled: baseSettings.notificationsEnabled,
        usEquityTargetPct: baseSettings.usEquityTargetPct,
        colorTheme: baseSettings.colorTheme,
        driftThresholdPct: baseSettings.driftThresholdPct,
      );
      final highSettings = Settings(
        riskBand: baseSettings.riskBand,
        monthlyEssentials: baseSettings.monthlyEssentials,
        monthlyIncome: 7500,
        incomeMultiplierFallback: baseSettings.incomeMultiplierFallback,
        liquidityBondHaircut: baseSettings.liquidityBondHaircut,
        bucketCap: baseSettings.bucketCap,
        employerStockThreshold: baseSettings.employerStockThreshold,
        darkModeEnabled: baseSettings.darkModeEnabled,
        isPro: baseSettings.isPro,
        biometricLockEnabled: baseSettings.biometricLockEnabled,
        notificationsEnabled: baseSettings.notificationsEnabled,
        usEquityTargetPct: baseSettings.usEquityTargetPct,
        colorTheme: baseSettings.colorTheme,
        driftThresholdPct: baseSettings.driftThresholdPct,
      );

      final resultLow = DebtLoadCalculator.calculateDebtLoad(
        [acct(50000)],
        liabilities,
        5000,
        lowSettings,
      );
      final resultHigh = DebtLoadCalculator.calculateDebtLoad(
        [acct(50000)],
        liabilities,
        5000,
        highSettings,
      );
      // Both should produce max DSCR component so composite difference small
      expect(resultHigh.score, closeTo(resultLow.score, 5));
    });
  });
}
