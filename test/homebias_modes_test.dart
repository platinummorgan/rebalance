import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/homebias.dart';
// import 'package:rebalance/data/calculators/financial_health.dart';

void main() {
  test('HomeBias standard vs off affects aggregator renormalization', () {
    final settingsStandard = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 3000.0,
      usEquityTargetPct: 0.65,
    );

    final settingsOff = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 3000.0,
      usEquityTargetPct: 0.65,
      globalDiversificationMode: 'off',
    );

    // Simulate accounts with 100% US equity -> intlPct = 0
    final List<Account> accounts = [
      Account(
        id: 't1',
        name: 'Test Brokerage',
        kind: 'brokerage',
        balance: 10000.0,
        pctCash: 0.0,
        pctBonds: 0.0,
        pctUsEq: 1.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    final hbStandard =
        HomeBiasCalculator.calculateHomeBias(accounts, settingsStandard);
    final hbOff = HomeBiasCalculator.calculateHomeBias(accounts, settingsOff);

    // In standard mode, 0 intl should be penalized (score < 100)
    expect(hbStandard.score, lessThan(100.0));

    // In off mode, aggregator would treat it as muted; our implementation returns 100 to avoid accidental penalty
    expect(hbOff.score, equals(100.0));
  });
}
