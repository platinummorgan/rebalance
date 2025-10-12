import 'dart:convert';
import '../data/models.dart';
import '../data/repositories.dart';

/// Provides JSON export of core domain objects for backup.
/// Import path intentionally omitted for MVP (only manual recovery) to avoid
/// accidental overwrites; can be added later.
class ExportService {
  static const currentSchemaVersion = 1;

  /// Returns a JSON string containing all persisted data.
  static Future<String> exportAll() async {
    final accounts = await RepositoryService.getAccounts();
    final liabilities = await RepositoryService.getLiabilities();
    final settings = await RepositoryService.getSettings();
    final snapshots = await RepositoryService.getSnapshots();

    final payload = {
      'schemaVersion': currentSchemaVersion,
      'generatedAt': DateTime.now().toIso8601String(),
      'accounts': accounts.map(_accountToMap).toList(),
      'liabilities': liabilities.map(_liabilityToMap).toList(),
      'settings': _settingsToMap(settings),
      'snapshots': snapshots.map(_snapshotToMap).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Map<String, Object?> _accountToMap(Account a) => {
        'id': a.id,
        'name': a.name,
        'kind': a.kind,
        'balance': a.balance,
        'pctCash': a.pctCash,
        'pctBonds': a.pctBonds,
        'pctUsEq': a.pctUsEq,
        'pctIntlEq': a.pctIntlEq,
        'pctRealEstate': a.pctRealEstate,
        'pctAlt': a.pctAlt,
        'employerStockPct': a.employerStockPct,
        'updatedAt': a.updatedAt.toIso8601String(),
      };

  static Map<String, Object?> _liabilityToMap(Liability l) => {
        'id': l.id,
        'name': l.name,
        'kind': l.kind,
        'balance': l.balance,
        'apr': l.apr,
        'minPayment': l.minPayment,
        'updatedAt': l.updatedAt.toIso8601String(),
        'creditLimit': l.creditLimit,
        'nextPaymentDate': l.nextPaymentDate?.toIso8601String(),
        'paymentFrequencyDays': l.paymentFrequencyDays,
        'dayOfMonth': l.dayOfMonth,
      };

  static Map<String, Object?> _settingsToMap(Settings s) => {
        'riskBand': s.riskBand.name,
        'monthlyEssentials': s.monthlyEssentials,
        'driftThresholdPct': s.driftThresholdPct,
        'notificationsEnabled': s.notificationsEnabled,
        'usEquityTargetPct': s.usEquityTargetPct,
        'isPro': s.isPro,
        'biometricLockEnabled': s.biometricLockEnabled,
        'darkModeEnabled': s.darkModeEnabled,
        'colorTheme': s.colorTheme.name,
        'liquidityBondHaircut': s.liquidityBondHaircut,
        'bucketCap': s.bucketCap,
        'employerStockThreshold': s.employerStockThreshold,
        'monthlyIncome': s.monthlyIncome,
        'incomeMultiplierFallback': s.incomeMultiplierFallback,
      };

  static Map<String, Object?> _snapshotToMap(Snapshot sn) => {
        'at': sn.at.toIso8601String(),
        'netWorth': sn.netWorth,
        'cashTotal': sn.cashTotal,
        'bondsTotal': sn.bondsTotal,
        'usEqTotal': sn.usEqTotal,
        'intlEqTotal': sn.intlEqTotal,
        'reTotal': sn.reTotal,
        'altTotal': sn.altTotal,
        'liabilitiesTotal': sn.liabilitiesTotal,
        'note': sn.note,
        'source': sn.source,
      };
}
