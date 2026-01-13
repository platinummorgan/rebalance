import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/repositories.dart';
import '../data/models.dart';
import 'file_saver_service.dart';

/// Service for creating and restoring complete app backups
///
/// Creates a single JSON file containing:
/// - All accounts
/// - All liabilities
/// - All income sources
/// - All settings
class BackupService {
  static const String _backupVersion = '1.0';

  /// Creates a complete backup of all user data and saves to Downloads
  /// Returns the file path if successful, null otherwise
  static Future<String?> createBackup() async {
    try {
      debugPrint('[Backup] Creating complete backup...');

      // Gather all data
      final accounts = await RepositoryService.getAccounts();
      final liabilities = await RepositoryService.getLiabilities();
      final incomes = await RepositoryService.getIncomes();
      final settings = await RepositoryService.getSettings();

      debugPrint('[Backup] Data collected:');
      debugPrint('[Backup]   - ${accounts.length} accounts');
      debugPrint('[Backup]   - ${liabilities.length} liabilities');
      debugPrint('[Backup]   - ${incomes.length} incomes');

      // Create backup data structure
      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'appVersion': '1.0.11',
        'accounts': accounts.map((a) => _accountToJson(a)).toList(),
        'liabilities': liabilities.map((l) => _liabilityToJson(l)).toList(),
        'incomes': incomes.map((i) => _incomeToJson(i)).toList(),
        'settings': _settingsToJson(settings),
      };

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save directly to Downloads folder using native Android API
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'wealth_dial_backup_$timestamp.json';

      final filePath = await FileSaverService.saveToDownloads(
        fileName: fileName,
        content: jsonString,
      );

      debugPrint('[Backup] Backup saved to Downloads: $filePath');
      debugPrint(
        '[Backup] File size: ${(jsonString.length / 1024).toStringAsFixed(2)} KB',
      );

      return filePath;
    } catch (e, stack) {
      debugPrint('[Backup] Failed to create backup: $e');
      debugPrint('[Backup] Stack trace: $stack');
      return null;
    }
  }

  /// Shares the backup file with the user (via email, cloud storage, etc.)
  static Future<bool> shareBackup(File backupFile) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(backupFile.path)],
        subject: 'Wealth Dial Backup',
        text:
            'Your Wealth Dial data backup from ${DateTime.now().toString().split(' ')[0]}',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('[Backup] Failed to share backup: $e');
      return false;
    }
  }

  /// Picks a backup file and restores all data
  /// WARNING: This will clear ALL existing data before restoring
  static Future<RestoreResult> restoreFromFile() async {
    try {
      debugPrint('[Backup] Starting restore process...');

      // Pick file - allow both JSON and all files for flexibility
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return RestoreResult(
          success: false,
          error: 'No file selected',
        );
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return RestoreResult(
          success: false,
          error: 'Invalid file path',
        );
      }

      return await restoreFromFilePath(filePath);
    } catch (e, stack) {
      debugPrint('[Backup] Restore failed: $e');
      debugPrint('[Backup] Stack trace: $stack');
      return RestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Restores data from a specific file path
  /// WARNING: This will clear ALL existing data before restoring
  static Future<RestoreResult> restoreFromFilePath(String filePath) async {
    try {
      debugPrint('[Backup] Reading backup file: $filePath');

      // Read file
      final file = File(filePath);
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          error: 'File does not exist',
        );
      }

      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup version
      final version = backupData['version'] as String?;
      if (version == null) {
        return RestoreResult(
          success: false,
          error: 'Invalid backup file: missing version',
        );
      }

      debugPrint('[Backup] Restoring from backup version: $version');
      debugPrint('[Backup] Backup timestamp: ${backupData['timestamp']}');

      // Parse and count items
      final accountsList =
          (backupData['accounts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final liabilitiesList =
          (backupData['liabilities'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
      final incomesList =
          (backupData['incomes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      debugPrint('[Backup] Found:');
      debugPrint('[Backup]   - ${accountsList.length} accounts');
      debugPrint('[Backup]   - ${liabilitiesList.length} liabilities');
      debugPrint('[Backup]   - ${incomesList.length} incomes');

      // Clear existing data
      await RepositoryService.clearAllData();
      debugPrint('[Backup] Existing data cleared');

      // Restore accounts
      int accountsRestored = 0;
      for (final accountJson in accountsList) {
        try {
          final account = _accountFromJson(accountJson);
          await RepositoryService.saveAccount(account);
          accountsRestored++;
        } catch (e) {
          debugPrint('[Backup] Failed to restore account: $e');
        }
      }

      // Restore liabilities
      int liabilitiesRestored = 0;
      for (final liabilityJson in liabilitiesList) {
        try {
          final liability = _liabilityFromJson(liabilityJson);
          await RepositoryService.saveLiability(liability);
          liabilitiesRestored++;
        } catch (e) {
          debugPrint('[Backup] Failed to restore liability: $e');
        }
      }

      // Restore incomes
      int incomesRestored = 0;
      for (final incomeJson in incomesList) {
        try {
          final income = _incomeFromJson(incomeJson);
          await RepositoryService.saveIncome(income);
          incomesRestored++;
        } catch (e) {
          debugPrint('[Backup] Failed to restore income: $e');
        }
      }

      // Restore settings
      if (backupData['settings'] != null) {
        try {
          final settings =
              _settingsFromJson(backupData['settings'] as Map<String, dynamic>);
          await RepositoryService.saveSettings(settings);
          debugPrint('[Backup] Settings restored');
        } catch (e) {
          debugPrint('[Backup] Failed to restore settings: $e');
        }
      }

      debugPrint('[Backup] Restore complete:');
      debugPrint('[Backup]   - $accountsRestored accounts restored');
      debugPrint('[Backup]   - $liabilitiesRestored liabilities restored');
      debugPrint('[Backup]   - $incomesRestored incomes restored');

      return RestoreResult(
        success: true,
        accountsRestored: accountsRestored,
        liabilitiesRestored: liabilitiesRestored,
        incomesRestored: incomesRestored,
      );
    } catch (e, stack) {
      debugPrint('[Backup] Restore failed: $e');
      debugPrint('[Backup] Stack trace: $stack');
      return RestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // JSON serialization methods
  static Map<String, dynamic> _accountToJson(Account account) => {
        'id': account.id,
        'name': account.name,
        'kind': account.kind,
        'balance': account.balance,
        'pctCash': account.pctCash,
        'pctBonds': account.pctBonds,
        'pctUsEq': account.pctUsEq,
        'pctIntlEq': account.pctIntlEq,
        'pctRealEstate': account.pctRealEstate,
        'pctAlt': account.pctAlt,
        'updatedAt': account.updatedAt.toIso8601String(),
        'employerStockPct': account.employerStockPct,
        'isLocked': account.isLocked,
        'originalCurrency': account.originalCurrency,
        'originalBalance': account.originalBalance,
      };

  static Account _accountFromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        balance: (json['balance'] as num).toDouble(),
        pctCash: (json['pctCash'] as num?)?.toDouble() ?? 0.0,
        pctBonds: (json['pctBonds'] as num?)?.toDouble() ?? 0.0,
        pctUsEq: (json['pctUsEq'] as num?)?.toDouble() ?? 0.0,
        pctIntlEq: (json['pctIntlEq'] as num?)?.toDouble() ?? 0.0,
        pctRealEstate: (json['pctRealEstate'] as num?)?.toDouble() ?? 0.0,
        pctAlt: (json['pctAlt'] as num?)?.toDouble() ?? 0.0,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        employerStockPct: (json['employerStockPct'] as num?)?.toDouble() ?? 0.0,
        isLocked: json['isLocked'] as bool? ?? false,
        originalCurrency: json['originalCurrency'] as String?,
        originalBalance: (json['originalBalance'] as num?)?.toDouble(),
      );

  static Map<String, dynamic> _liabilityToJson(Liability liability) => {
        'id': liability.id,
        'name': liability.name,
        'kind': liability.kind,
        'balance': liability.balance,
        'apr': liability.apr,
        'minPayment': liability.minPayment,
        'creditLimit': liability.creditLimit,
        'nextPaymentDate': liability.nextPaymentDate?.toIso8601String(),
        'paymentFrequencyDays': liability.paymentFrequencyDays,
        'dayOfMonth': liability.dayOfMonth,
        'updatedAt': liability.updatedAt.toIso8601String(),
      };

  static Liability _liabilityFromJson(Map<String, dynamic> json) => Liability(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        balance: (json['balance'] as num).toDouble(),
        apr: (json['apr'] as num).toDouble(),
        minPayment: (json['minPayment'] as num).toDouble(),
        creditLimit: (json['creditLimit'] as num?)?.toDouble(),
        nextPaymentDate: json['nextPaymentDate'] != null
            ? DateTime.parse(json['nextPaymentDate'] as String)
            : null,
        paymentFrequencyDays: json['paymentFrequencyDays'] as int? ?? 30,
        dayOfMonth: json['dayOfMonth'] as int?,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  static Map<String, dynamic> _incomeToJson(Income income) => {
        'id': income.id,
        'name': income.name,
        'kind': income.kind,
        'grossAmount': income.grossAmount,
        'frequency': income.frequency,
        'updatedAt': income.updatedAt.toIso8601String(),
        'federalTax': income.federalTax,
        'stateTax': income.stateTax,
        'socialSecurityTax': income.socialSecurityTax,
        'medicareTax': income.medicareTax,
        'retirement401k': income.retirement401k,
        'healthInsurance': income.healthInsurance,
        'otherDeductions': income.otherDeductions,
        'originalCurrency': income.originalCurrency,
        'originalAmount': income.originalAmount,
      };

  static Income _incomeFromJson(Map<String, dynamic> json) => Income(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        grossAmount: (json['grossAmount'] as num).toDouble(),
        frequency: json['frequency'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        federalTax: (json['federalTax'] as num?)?.toDouble(),
        stateTax: (json['stateTax'] as num?)?.toDouble(),
        socialSecurityTax: (json['socialSecurityTax'] as num?)?.toDouble(),
        medicareTax: (json['medicareTax'] as num?)?.toDouble(),
        retirement401k: (json['retirement401k'] as num?)?.toDouble(),
        healthInsurance: (json['healthInsurance'] as num?)?.toDouble(),
        otherDeductions: (json['otherDeductions'] as num?)?.toDouble(),
        originalCurrency: json['originalCurrency'] as String?,
        originalAmount: (json['originalAmount'] as num?)?.toDouble(),
      );

  static Map<String, dynamic> _settingsToJson(Settings settings) => {
        'riskBand': settings.riskBand.toString(),
        'monthlyEssentials': settings.monthlyEssentials,
        'driftThresholdPct': settings.driftThresholdPct,
        'notificationsEnabled': settings.notificationsEnabled,
        'usEquityTargetPct': settings.usEquityTargetPct,
        'isPro': settings.isPro,
        'biometricLockEnabled': settings.biometricLockEnabled,
        'darkModeEnabled': settings.darkModeEnabled,
        'colorTheme': settings.colorTheme.toString(),
        'homeCountry': settings.homeCountry,
        'globalDiversificationMode': settings.globalDiversificationMode,
        'intlTargetOverride': settings.intlTargetOverride,
        'intlTolerancePct': settings.intlTolerancePct,
        'intlFloorPct': settings.intlFloorPct,
        'intlPenaltyScale': settings.intlPenaltyScale,
        'currency': settings.currency,
        'language': settings.language,
      };

  static Settings _settingsFromJson(Map<String, dynamic> json) => Settings(
        riskBand: RiskBand.values.firstWhere(
          (e) => e.toString() == json['riskBand'],
          orElse: () => RiskBand.balanced,
        ),
        monthlyEssentials:
            (json['monthlyEssentials'] as num?)?.toDouble() ?? 0.0,
        driftThresholdPct:
            (json['driftThresholdPct'] as num?)?.toDouble() ?? 5.0,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        usEquityTargetPct:
            (json['usEquityTargetPct'] as num?)?.toDouble() ?? 60.0,
        isPro: json['isPro'] as bool? ?? false,
        biometricLockEnabled: json['biometricLockEnabled'] as bool? ?? false,
        darkModeEnabled: json['darkModeEnabled'] as bool? ?? false,
        colorTheme: ColorTheme.values.firstWhere(
          (e) => e.toString() == (json['colorTheme'] ?? ''),
          orElse: () => ColorTheme.blue,
        ),
        homeCountry: json['homeCountry'] as String? ?? 'US',
        globalDiversificationMode:
            json['globalDiversificationMode'] as String? ?? 'moderate',
        intlTargetOverride: (json['intlTargetOverride'] as num?)?.toDouble(),
        intlTolerancePct: (json['intlTolerancePct'] as num?)?.toDouble() ?? 5.0,
        intlFloorPct: (json['intlFloorPct'] as num?)?.toDouble() ?? 10.0,
        intlPenaltyScale: (json['intlPenaltyScale'] as num?)?.toDouble() ?? 2.0,
        currency: json['currency'] as String? ?? 'USD',
        language: json['language'] as String?,
      );
}

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final String? error;
  final int accountsRestored;
  final int liabilitiesRestored;
  final int incomesRestored;

  RestoreResult({
    required this.success,
    this.error,
    this.accountsRestored = 0,
    this.liabilitiesRestored = 0,
    this.incomesRestored = 0,
  });

  String get summary {
    if (!success) return error ?? 'Restore failed';
    return 'Restored: $accountsRestored accounts, $liabilitiesRestored liabilities, $incomesRestored incomes';
  }
}
