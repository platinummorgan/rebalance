import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../app.dart';

// Custom formatter to add commas while typing
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters except decimal point
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    // Ensure only one decimal point
    final parts = digitsOnly.split('.');
    if (parts.length > 2) {
      digitsOnly = '${parts[0]}.${parts.sublist(1).join()}';
    }

    // Limit to 2 decimal places
    if (parts.length == 2 && parts[1].length > 2) {
      digitsOnly = '${parts[0]}.${parts[1].substring(0, 2)}';
    }

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format with commas
    final splitParts = digitsOnly.split('.');
    final integerPart = splitParts[0];
    final decimalPart = splitParts.length > 1 ? '.${splitParts[1]}' : '';

    final formattedInteger = _formatter.format(int.tryParse(integerPart) ?? 0);
    final formatted = '$formattedInteger$decimalPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AccountDetailScreen extends ConsumerStatefulWidget {
  final String? accountId;

  const AccountDetailScreen({super.key, this.accountId});

  @override
  ConsumerState<AccountDetailScreen> createState() =>
      _AccountDetailScreenState();
}

class _AccountDetailScreenState extends ConsumerState<AccountDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String _selectedAccountType = 'checking';
  bool _isLocked = false;
  double _pctCash = 100.0;
  double _pctBonds = 0.0;
  double _pctUsEq = 0.0;
  double _pctIntlEq = 0.0;
  double _pctRealEstate = 0.0;
  double _pctAlt = 0.0;

  bool _isLoading = false;
  Account? _existingAccount;

  final Map<String, String> _accountTypes = {
    'cash': 'Cash Account',
    'checking': 'Checking Account',
    'savings': 'Savings Account',
    'brokerage': 'Brokerage Account',
    'retirement': '401k/IRA',
    'hsa': 'Health Savings Account',
    'cd': 'Certificate of Deposit',
    'crypto': 'Cryptocurrency',
    'realestate': 'Real Estate',
    'realestateequity': 'Real Estate Equity',
    '529': '529 Education Savings',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    if (widget.accountId != null) {
      _loadExistingAccount();
    }
  }

  Future<void> _loadExistingAccount() async {
    try {
      final accounts = await RepositoryService.getAccounts();
      _existingAccount = accounts.firstWhere((a) => a.id == widget.accountId);

      if (_existingAccount != null) {
        _nameController.text = _existingAccount!.name;
        _balanceController.text = _existingAccount!.balance.toString();
        _selectedAccountType = _existingAccount!.kind;
        _isLocked = _existingAccount!.isLocked;
        _pctCash = _existingAccount!.pctCash * 100;
        _pctBonds = _existingAccount!.pctBonds * 100;
        _pctUsEq = _existingAccount!.pctUsEq * 100;
        _pctIntlEq = _existingAccount!.pctIntlEq * 100;
        _pctRealEstate = _existingAccount!.pctRealEstate * 100;
        _pctAlt = _existingAccount!.pctAlt * 100;
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading account: $e')),
        );
      }
    }
  }

  void _normalizeAllocations() {
    final total =
        _pctCash + _pctBonds + _pctUsEq + _pctIntlEq + _pctRealEstate + _pctAlt;
    if (total > 100.0) {
      final ratio = 100.0 / total;
      _pctCash *= ratio;
      _pctBonds *= ratio;
      _pctUsEq *= ratio;
      _pctIntlEq *= ratio;
      _pctRealEstate *= ratio;
      _pctAlt *= ratio;
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      _normalizeAllocations();

      final account = Account(
        id: widget.accountId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        kind: _selectedAccountType,
        balance: double.parse(_balanceController.text.replaceAll(',', '')),
        pctCash: _pctCash / 100,
        pctBonds: _pctBonds / 100,
        pctUsEq: _pctUsEq / 100,
        pctIntlEq: _pctIntlEq / 100,
        pctRealEstate: _pctRealEstate / 100,
        pctAlt: _pctAlt / 100,
        updatedAt: DateTime.now(),
        isLocked: _isLocked,
      );

      await ref.read(accountsProvider.notifier).addAccount(account);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving account: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.accountId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'Add Account'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAccount,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Account Name',
                          hintText: 'e.g., Chase Checking',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an account name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAccountType,
                        decoration: const InputDecoration(
                          labelText: 'Account Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _accountTypes.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedAccountType = value;
                              // Auto-set locked status based on account type
                              _isLocked = Account.isLockedByDefault(value);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Locked Account Toggle
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isLocked
                              ? Colors.amber.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isLocked
                                ? Colors.amber.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isLocked ? Icons.lock : Icons.lock_open,
                              color: _isLocked
                                  ? Colors.amber.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Locked Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: _isLocked
                                          ? Colors.amber.shade900
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isLocked
                                        ? 'Can\'t be rebalanced (401k, pension, restricted)'
                                        : 'Can be included in rebalancing plans',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isLocked
                                          ? Colors.amber.shade800
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isLocked,
                              onChanged: (value) {
                                setState(() => _isLocked = value);
                              },
                              activeThumbColor: Colors.amber.shade700,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _balanceController,
                        decoration: const InputDecoration(
                          labelText: 'Current Balance',
                          hintText: '0.00',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          ThousandsSeparatorInputFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a balance';
                          }
                          // Remove commas before parsing
                          final cleanValue = value.replaceAll(',', '');
                          final balance = double.tryParse(cleanValue);
                          if (balance == null || balance < 0) {
                            return 'Please enter a valid balance';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asset Allocation',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'What percentage of this account is invested in each asset class?',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildAllocationSlider(
                          'Cash & Cash Equivalents', _pctCash, (value) {
                        setState(() => _pctCash = value);
                      }),
                      _buildAllocationSlider('Bonds & Fixed Income', _pctBonds,
                          (value) {
                        setState(() => _pctBonds = value);
                      }),
                      _buildAllocationSlider('US Equity', _pctUsEq, (value) {
                        setState(() => _pctUsEq = value);
                      }),
                      _buildAllocationSlider('International Equity', _pctIntlEq,
                          (value) {
                        setState(() => _pctIntlEq = value);
                      }),
                      _buildAllocationSlider(
                          'Real Estate (REITs)', _pctRealEstate, (value) {
                        setState(() => _pctRealEstate = value);
                      }),
                      _buildAllocationSlider('Alternatives', _pctAlt, (value) {
                        setState(() => _pctAlt = value);
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Allocation:'),
                            Text(
                              '${(_pctCash + _pctBonds + _pctUsEq + _pctIntlEq + _pctRealEstate + _pctAlt).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (_pctCash +
                                            _pctBonds +
                                            _pctUsEq +
                                            _pctIntlEq +
                                            _pctRealEstate +
                                            _pctAlt >
                                        100.0)
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update Account' : 'Add Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.toStringAsFixed(1)}%'),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
