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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import & Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backup & Restore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export to CSV'),
                subtitle: const Text(
                  'Free • Export account balances for spreadsheet analysis',
                ),
                onTap: () => _showExportOptions(context, ref),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Create Complete Backup'),
                subtitle: const Text(
                  'Export all data (accounts, debts, income, settings) to a single file',
                ),
                onTap: () => _createBackup(context, ref),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from Backup'),
                subtitle: const Text(
                  'Restore all data from a backup file',
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
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export CSV'),
        content: const Text(
          'Your CSV file will be saved directly to your Downloads folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'export'),
            child: const Text('Export'),
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
          content: Text('Saved to Downloads:\n$fileBaseName.csv'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
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
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      dismissDialog();
    }
  }

  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
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
          const SnackBar(
            content: Text('Failed to create backup'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show success with file location
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to Downloads:\n$filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
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
          content: Text('Backup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup?'),
        content: const Text(
          'WARNING: This will replace ALL your current data with the data from the backup file.\n\n'
          'Your current data will be permanently deleted.\n\n'
          'Make sure you have a backup of your current data before proceeding.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      debugPrint('[Backup] Starting restore...');

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await BackupService.restoreFromFile();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading dialog

      if (result.success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Successful!'),
            content: Text(result.summary),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to settings
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('[Backup] Error restoring backup: $e');
      debugPrint('[Backup] Stack trace: $stack');

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading dialog if still showing

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
