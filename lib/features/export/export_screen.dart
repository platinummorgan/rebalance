import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../../data/repositories.dart';
import '../../utils/csv_exporter.dart';

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
                onTap: () => _exportToCSV(context, ref),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.security),
                title: Text('Export Encrypted Backup'),
                subtitle: Text(
                  'Full backup with passphrase protection (Coming soon)',
                ),
                enabled: false,
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.upload),
                title: Text('Import Backup'),
                subtitle: Text(
                  'Restore from encrypted backup file (Coming soon)',
                ),
                enabled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, WidgetRef ref) async {
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
      debugPrint('[Export] Starting CSV export...');

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

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileBaseName = 'rebalance_export_$timestamp';
      debugPrint('[Export] Saving file: $fileBaseName.csv');

      await CsvExporter.save(
        fileName: fileBaseName,
        csvContent: csvString,
      );

      dismissDialog();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads/$fileBaseName.csv'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
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
}
