import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../data/repositories.dart';
import '../../services/file_saver_service.dart';
import '../../services/backup_service.dart';
import '../../generated/app_localizations.dart';

class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importExportTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupRestoreSectionTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.download),
                title: Text(l10n.exportToCsvTitle),
                subtitle: Text(
                  l10n.exportToCsvSubtitle,
                ),
                onTap: () => _showExportOptions(context, ref),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup),
                title: Text(l10n.createCompleteBackupTitle),
                subtitle: Text(
                  l10n.createCompleteBackupSubtitle,
                ),
                onTap: () => _createBackup(context, ref),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.enhanced_encryption),
                title: Text(l10n.createEncryptedBackupTitle),
                subtitle: Text(
                  l10n.createEncryptedBackupSubtitle,
                ),
                onTap: () => _createEncryptedBackup(context, ref),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.restoreFromBackupTitle),
                subtitle: Text(
                  l10n.restoreFromBackupSubtitle,
                ),
                onTap: () => _restoreBackup(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportOptions(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportCsvDialogTitle),
        content: Text(
          l10n.exportCsvDialogDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'export'),
            child: Text(l10n.exportButtonLabel),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (result == 'export') {
      await _exportToCSV(context, ref);
    }
  }

  Future<String> _generateCSV(WidgetRef ref) async {
    debugPrint('[Export] Fetching accounts and liabilities...');
    final accounts = await RepositoryService.getAccounts();
    final liabilities = await RepositoryService.getLiabilities();
    debugPrint(
      '[Export] Found ${accounts.length} accounts and ${liabilities.length} liabilities',
    );

    final List<List<dynamic>> rows = [];
    rows.add([
      'Type',
      'Name',
      'Balance',
      'Cash %',
      'Bonds %',
      'US Equity %',
      'Intl Equity %',
      'Real Estate %',
      'Alternatives %',
      'Employer Stock %',
    ]);

    for (final account in accounts) {
      rows.add([
        'Account',
        account.name,
        account.balance,
        account.pctCash,
        account.pctBonds,
        account.pctUsEq,
        account.pctIntlEq,
        account.pctRealEstate,
        account.pctAlt,
        account.employerStockPct,
      ]);
    }

    for (final liability in liabilities) {
      rows.add([
        'Liability',
        liability.name,
        -liability.balance,
        '',
        '',
        '',
        '',
        '',
        '',
        '',
      ]);
    }

    debugPrint('[Export] Converting to CSV...');
    final csvString = const ListToCsvConverter().convert(rows);
    debugPrint('[Export] CSV size: ${csvString.length} bytes');

    return csvString;
  }

  Future<void> _exportToCSV(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    NavigatorState? rootNavigator;
    var dialogVisible = false;

    void dismissDialog() {
      final navigator = rootNavigator;
      if (dialogVisible && navigator != null && navigator.mounted) {
        navigator.pop();
        dialogVisible = false;
      }
    }

    try {
      debugPrint('[Export] Starting CSV export (share mode)...');

      if (!context.mounted) return;
      rootNavigator = Navigator.of(context, rootNavigator: true);
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      dialogVisible = true;

      final csvString = await _generateCSV(ref);
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileBaseName = 'rebalance_export_$timestamp';
      debugPrint('[Export] Saving file: $fileBaseName.csv');

      final filePath = await FileSaverService.saveToDownloads(
        fileName: '$fileBaseName.csv',
        content: csvString,
      );

      dismissDialog();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.csvSavedToDownloads('$fileBaseName.csv'),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.ok,
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );

      debugPrint('[Export] CSV export completed: $filePath');
    } catch (e, stackTrace) {
      debugPrint('[Export] Error during export: $e');
      debugPrint('[Export] Stack trace: $stackTrace');
      dismissDialog();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportFailedWithError(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      dismissDialog();
    }
  }

  Future<String?> _promptBackupPassphrase(
    BuildContext context, {
    required bool confirm,
    String? initialError,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final passController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorText = initialError;
    var obscurePassphrase = true;
    var obscureConfirm = true;

    final passphrase = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title:
                Text(
                  confirm
                      ? l10n.encryptedBackupDialogTitle
                      : l10n.backupPassphraseDialogTitle,
                ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  confirm
                      ? l10n.newBackupPassphraseDescription
                      : l10n.existingBackupPassphraseDescription,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passController,
                  obscureText: obscurePassphrase,
                  decoration: InputDecoration(
                    labelText: l10n.passphraseLabel,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setDialogState(() {
                          obscurePassphrase = !obscurePassphrase;
                        });
                      },
                      icon: Icon(
                        obscurePassphrase
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                if (confirm) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassphraseLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () {
                  final pass = passController.text.trim();
                  final confirmPass = confirmController.text.trim();
                  if (pass.isEmpty) {
                    setDialogState(() {
                      errorText = l10n.passphraseRequiredError;
                    });
                    return;
                  }
                  if (confirm) {
                    final validationError = _validateNewPassphrase(pass, l10n);
                    if (validationError != null) {
                      setDialogState(() {
                        errorText = validationError;
                      });
                      return;
                    }
                  }
                  if (confirm && pass != confirmPass) {
                    setDialogState(() {
                      errorText = l10n.passphrasesDoNotMatchError;
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, pass);
                },
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        );
      },
    );

    passController.dispose();
    confirmController.dispose();
    return passphrase;
  }

  String? _validateNewPassphrase(String passphrase, AppLocalizations l10n) {
    if (passphrase.length < 12) {
      return l10n.passphraseMinLengthError;
    }
    final hasUpper = passphrase.contains(RegExp(r'[A-Z]'));
    final hasLower = passphrase.contains(RegExp(r'[a-z]'));
    final hasDigit = passphrase.contains(RegExp(r'[0-9]'));
    final hasSymbol = passphrase.contains(RegExp(r'[^A-Za-z0-9]'));
    if (!hasUpper || !hasLower || !hasDigit || !hasSymbol) {
      return l10n.passphraseComplexityError;
    }
    return null;
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    bool dialogShowing = false;
    try {
      debugPrint('[Backup] Starting backup creation...');

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShowing = true;

      final filePath = await BackupService.createBackup();

      debugPrint('[Backup] Got filePath: $filePath');

      // Dismiss loading dialog
      if (context.mounted && dialogShowing) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShowing = false;
      }

      if (!context.mounted) return;

      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createBackupFailed),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show success with file location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupSavedToDownloads(filePath)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l10n.ok,
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('[Backup] Error creating backup: $e');
      debugPrint('[Backup] Stack trace: $stack');

      if (context.mounted && dialogShowing) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShowing = false;
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupFailedWithError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createEncryptedBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final passphrase = await _promptBackupPassphrase(context, confirm: true);
    if (passphrase == null || !context.mounted) return;

    bool dialogShowing = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      dialogShowing = true;

      final filePath = await BackupService.createBackup(passphrase: passphrase);

      if (context.mounted && dialogShowing) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogShowing = false;
      }
      if (!context.mounted) return;

      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.createEncryptedBackupFailed),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.encryptedBackupSavedToDownloads(filePath)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (context.mounted && dialogShowing) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.encryptedBackupFailedWithError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    const maxPassphraseAttempts = 5;

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Text(
          l10n.restoreConfirmWarning,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.restoreButtonLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    var loadingVisible = false;
    void showLoading() {
      if (!context.mounted || loadingVisible) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingVisible = true;
    }

    void dismissLoading() {
      if (!loadingVisible || !context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      loadingVisible = false;
    }

    try {
      debugPrint('[Backup] Starting restore...');

      if (!context.mounted) return;
      showLoading();

      var result = await BackupService.restoreFromFile();
      dismissLoading();

      var attemptCount = 0;
      while (result.needsPassphrase && result.selectedFilePath != null) {
        if (attemptCount >= maxPassphraseAttempts) {
          result = RestoreResult(
            success: false,
            error: l10n.restoreTooManyPassphraseAttempts,
          );
          break;
        }
        if (!context.mounted) return;
        final passphrase = await _promptBackupPassphrase(
          context,
          confirm: false,
          initialError: result.error,
        );
        if (passphrase == null || !context.mounted) return;
        attemptCount++;
        showLoading();
        result = await BackupService.restoreFromFilePath(
          result.selectedFilePath!,
          passphrase: passphrase,
        );
        dismissLoading();
      }

      if (!context.mounted) return;

      if (result.success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.restoreSuccessfulTitle),
            content: Text(result.summary),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to settings
                },
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.restoreFailedWithError(result.error ?? l10n.unknownError),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[Backup] Error restoring backup: $e');
      debugPrint('[Backup] Stack trace: $stack');

      dismissLoading();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restoreFailedWithError(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
