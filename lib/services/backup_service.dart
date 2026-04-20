import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cryptography/cryptography.dart';
import '../data/repositories.dart';
import 'file_saver_service.dart';
import 'backup_crypto_service.dart';

/// Service for creating and restoring complete app backups
///
/// Creates a single JSON file containing:
/// - All core financial entities (accounts, liabilities, income, expenses)
/// - Settings
/// - Historical/auxiliary data (snapshots, action cards, payments, notifications)
class BackupService {
  static const String _backupVersion = '1.1';

  /// Creates a complete backup of all user data and saves to Downloads
  /// Returns the file path if successful, null otherwise
  static Future<String?> createBackup({String? passphrase}) async {
    try {
      debugPrint('[Backup] Creating complete backup...');
      final backupData = await RepositoryService.exportData();
      backupData['version'] = _backupVersion;
      backupData['timestamp'] ??= DateTime.now().toIso8601String();

      debugPrint('[Backup] Data collected:');
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'accounts')} accounts',
      );
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'liabilities')} liabilities',
      );
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'incomes')} incomes',
      );
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'expenses')} expenses',
      );
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'payments')} payments',
      );
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'notifications')} notifications',
      );
      debugPrint(
        '[Backup]   - ${_countEntries(backupData, 'householdGoals')} household goals',
      );

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final normalizedPassphrase = passphrase?.trim();
      final useEncryption =
          normalizedPassphrase != null && normalizedPassphrase.isNotEmpty;
      final outputContent = useEncryption
          ? await BackupCryptoService.encryptJson(
              plaintextJson: jsonString,
              passphrase: normalizedPassphrase,
            )
          : jsonString;

      // Save directly to Downloads folder using native Android API
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = useEncryption
          ? 'wealth_dial_backup_$timestamp.encrypted.json'
          : 'wealth_dial_backup_$timestamp.json';

      final filePath = await FileSaverService.saveToDownloads(
        fileName: fileName,
        content: outputContent,
      );

      debugPrint('[Backup] Backup saved to Downloads: $filePath');
      debugPrint(
        '[Backup] File size: ${(outputContent.length / 1024).toStringAsFixed(2)} KB',
      );
      debugPrint('[Backup] Encryption enabled: $useEncryption');

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
  static Future<RestoreResult> restoreFromFilePath(
    String filePath, {
    String? passphrase,
  }) async {
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

      final fileContent = await file.readAsString();
      final decoded = jsonDecode(fileContent) as Map<String, dynamic>;
      final normalizedPassphrase = passphrase?.trim();

      late final Map<String, dynamic> backupData;
      if (BackupCryptoService.isEncryptedEnvelope(decoded)) {
        if (normalizedPassphrase == null || normalizedPassphrase.isEmpty) {
          return RestoreResult(
            success: false,
            needsPassphrase: true,
            selectedFilePath: filePath,
            error: 'This backup is encrypted. Enter the backup passphrase.',
          );
        }
        final decryptedJson = await BackupCryptoService.decryptJson(
          encryptedEnvelope: decoded,
          passphrase: normalizedPassphrase,
        );
        backupData = jsonDecode(decryptedJson) as Map<String, dynamic>;
      } else {
        backupData = decoded;
      }

      final version = backupData['version']?.toString() ?? 'legacy';
      debugPrint('[Backup] Restoring from backup version: $version');
      debugPrint('[Backup] Backup timestamp: ${backupData['timestamp']}');

      final accountsRestored = _countEntries(backupData, 'accounts');
      final liabilitiesRestored = _countEntries(backupData, 'liabilities');
      final incomesRestored = _countEntries(backupData, 'incomes');
      final expensesRestored = _countEntries(backupData, 'expenses');
      final snapshotsRestored = _countEntries(backupData, 'snapshots');
      final actionCardsRestored = _countEntries(backupData, 'actionCards');
      final paymentsRestored = _countEntries(backupData, 'payments');
      final notificationsRestored = _countEntries(backupData, 'notifications');
      final householdProfilesRestored =
          _countEntries(backupData, 'householdProfiles');
      final householdGoalsRestored = _countEntries(backupData, 'householdGoals');

      debugPrint('[Backup] Found:');
      debugPrint('[Backup]   - $accountsRestored accounts');
      debugPrint('[Backup]   - $liabilitiesRestored liabilities');
      debugPrint('[Backup]   - $incomesRestored incomes');
      debugPrint('[Backup]   - $expensesRestored expenses');
      debugPrint('[Backup]   - $snapshotsRestored snapshots');
      debugPrint('[Backup]   - $actionCardsRestored action cards');
      debugPrint('[Backup]   - $paymentsRestored payments');
      debugPrint('[Backup]   - $notificationsRestored notifications');
      debugPrint('[Backup]   - $householdProfilesRestored household profiles');
      debugPrint('[Backup]   - $householdGoalsRestored household goals');

      await RepositoryService.importData(backupData);
      debugPrint('[Backup] Existing data replaced and restore applied');

      debugPrint('[Backup] Restore complete:');
      debugPrint('[Backup]   - $accountsRestored accounts restored');
      debugPrint('[Backup]   - $liabilitiesRestored liabilities restored');
      debugPrint('[Backup]   - $incomesRestored incomes restored');
      debugPrint('[Backup]   - $expensesRestored expenses restored');
      debugPrint('[Backup]   - $snapshotsRestored snapshots restored');
      debugPrint('[Backup]   - $actionCardsRestored action cards restored');
      debugPrint('[Backup]   - $paymentsRestored payments restored');
      debugPrint('[Backup]   - $notificationsRestored notifications restored');
      debugPrint(
        '[Backup]   - $householdProfilesRestored household profiles restored',
      );
      debugPrint('[Backup]   - $householdGoalsRestored household goals restored');

      return RestoreResult(
        success: true,
        accountsRestored: accountsRestored,
        liabilitiesRestored: liabilitiesRestored,
        incomesRestored: incomesRestored,
        expensesRestored: expensesRestored,
        snapshotsRestored: snapshotsRestored,
        actionCardsRestored: actionCardsRestored,
        paymentsRestored: paymentsRestored,
        notificationsRestored: notificationsRestored,
        householdProfilesRestored: householdProfilesRestored,
        householdGoalsRestored: householdGoalsRestored,
      );
    } on SecretBoxAuthenticationError catch (e, stack) {
      debugPrint('[Backup] Restore failed: $e');
      debugPrint('[Backup] Stack trace: $stack');
      return RestoreResult(
        success: false,
        needsPassphrase: true,
        selectedFilePath: filePath,
        error:
            'Incorrect passphrase or integrity check failed. Please try again.',
      );
    } on FormatException catch (e, stack) {
      debugPrint('[Backup] Restore failed: $e');
      debugPrint('[Backup] Stack trace: $stack');
      return RestoreResult(
        success: false,
        error: e.message,
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

  static int _countEntries(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is List) return value.length;
    return 0;
  }
}

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final String? error;
  final bool needsPassphrase;
  final String? selectedFilePath;
  final int accountsRestored;
  final int liabilitiesRestored;
  final int incomesRestored;
  final int expensesRestored;
  final int snapshotsRestored;
  final int actionCardsRestored;
  final int paymentsRestored;
  final int notificationsRestored;
  final int householdProfilesRestored;
  final int householdGoalsRestored;

  RestoreResult({
    required this.success,
    this.error,
    this.needsPassphrase = false,
    this.selectedFilePath,
    this.accountsRestored = 0,
    this.liabilitiesRestored = 0,
    this.incomesRestored = 0,
    this.expensesRestored = 0,
    this.snapshotsRestored = 0,
    this.actionCardsRestored = 0,
    this.paymentsRestored = 0,
    this.notificationsRestored = 0,
    this.householdProfilesRestored = 0,
    this.householdGoalsRestored = 0,
  });

  String get summary {
    if (!success) return error ?? 'Restore failed';
    return 'Restored: $accountsRestored accounts, $liabilitiesRestored liabilities, '
        '$incomesRestored incomes, $expensesRestored expenses, '
        '$snapshotsRestored snapshots, $actionCardsRestored action cards, '
        '$paymentsRestored payments, $notificationsRestored notifications, '
        '$householdProfilesRestored household profiles, '
        '$householdGoalsRestored household goals';
  }
}
