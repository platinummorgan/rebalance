import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../services/csv_importer_service.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../generated/app_localizations.dart';

/// CSV Import screen allowing users to import Accounts, Liabilities, and Income
class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  bool _isLoading = false;
  CsvImportResult? _importResult;
  String? _selectedFilePath;

  Future<void> _pickAndImportFile() async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      setState(() {
        _isLoading = true;
        _importResult = null;
        _selectedFilePath = result.files.single.name;
      });

      // Read file content
      final file = File(result.files.single.path!);
      final csvContent = await file.readAsString();

      // Parse CSV
      final importResult = await CsvImporterService.parseCSV(csvContent);

      setState(() {
        _importResult = importResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _importResult = CsvImportResult.error('Error reading file: $e');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_importResult == null || !_importResult!.success) return;

    setState(() => _isLoading = true);

    try {
      final accountsNotifier = ref.read(accountsProvider.notifier);
      final liabilitiesNotifier = ref.read(liabilitiesProvider.notifier);
      final incomesNotifier = ref.read(incomesProvider.notifier);

      int successCount = 0;

      // Import based on type
      if (_importResult!.accounts != null) {
        for (final account in _importResult!.accounts!) {
          await accountsNotifier.addAccount(account);
          successCount++;
        }
      }

      if (_importResult!.liabilities != null) {
        for (final liability in _importResult!.liabilities!) {
          await liabilitiesNotifier.addLiability(liability);
          successCount++;
        }
      }

      if (_importResult!.incomes != null) {
        for (final income in _importResult!.incomes!) {
          await incomesNotifier.addIncome(income);
          successCount++;
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported $successCount ${_importResult!.typeDisplay}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.importFromCSV),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _importResult == null
              ? _buildInitialState()
              : _importResult!.success
                  ? _buildPreview()
                  : _buildError(),
    );
  }

  // ==================== INITIAL STATE ====================

  Widget _buildInitialState() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_upload,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              loc.importDataFromCSV,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              loc.selectCSVFileDescription,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickAndImportFile,
              icon: const Icon(Icons.folder_open),
              label: Text(loc.selectCSVFile),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 48),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.csvFormatRequirements,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              loc.accountsLabel,
              loc.accountsCSVFormat,
            ),
            const Divider(height: 24),
            _buildInstructionItem(
              loc.liabilitiesLabel,
              loc.liabilitiesCSVFormat,
            ),
            const Divider(height: 24),
            _buildInstructionItem(
              loc.incomeLabel,
              loc.incomeCSVFormat,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ==================== PREVIEW STATE ====================

  Widget _buildPreview() {
    final loc = AppLocalizations.of(context)!;
    final result = _importResult!;

    return Column(
      children: [
        // Header with file info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.readyToImport,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                        ),
                        if (_selectedFilePath != null)
                          Text(
                            _selectedFilePath!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Found ${result.itemCount} ${result.typeDisplay}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (result.errors != null && result.errors!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ ${result.errors!.length} ${loc.rowsHadErrors}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Preview list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (result.accounts != null)
                ...result.accounts!
                    .map((account) => _buildAccountPreview(account)),
              if (result.liabilities != null)
                ...result.liabilities!
                    .map((liability) => _buildLiabilityPreview(liability)),
              if (result.incomes != null)
                ...result.incomes!.map((income) => _buildIncomePreview(income)),

              // Show errors if any
              if (result.errors != null && result.errors!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Errors',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...result.errors!.map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $error',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _importResult = null;
                      _selectedFilePath = null;
                    });
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmImport,
                  icon: const Icon(Icons.check),
                  label:
                      Text('Import ${result.itemCount} ${result.typeDisplay}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountPreview(Account account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.account_balance, color: Colors.white, size: 20),
        ),
        title: Text(account.name),
        subtitle:
            Text('${account.kind} • \$${account.balance.toStringAsFixed(2)}'),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildLiabilityPreview(Liability liability) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.credit_card, color: Colors.white, size: 20),
        ),
        title: Text(liability.name),
        subtitle: Text(
          '${liability.kind} • \$${liability.balance.toStringAsFixed(2)} @ ${liability.apr.toStringAsFixed(2)}% APR',
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget _buildIncomePreview(Income income) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.attach_money, color: Colors.white, size: 20),
        ),
        title: Text(income.name),
        subtitle: Text(
          '${income.kind} • \$${income.grossAmount.toStringAsFixed(2)} ${income.frequency}',
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  // ==================== ERROR STATE ====================

  Widget _buildError() {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              loc.importError,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _importResult!.errorMessage ?? loc.unknownError,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickAndImportFile,
                  icon: const Icon(Icons.refresh),
                  label: Text(loc.tryAgain),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
