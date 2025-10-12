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
    if (newValue.text.isEmpty) return newValue;

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

class LiabilityDetailScreen extends ConsumerStatefulWidget {
  final String? liabilityId;

  const LiabilityDetailScreen({super.key, this.liabilityId});

  @override
  ConsumerState<LiabilityDetailScreen> createState() =>
      _LiabilityDetailScreenState();
}

// Formatter for APR percent input: allows up to 2 decimal places and normalizes the text
class PercentInputFormatter extends TextInputFormatter {
  final int decimalRange;
  PercentInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.isEmpty) return newValue;

    // Normalize comma as decimal separator
    text = text.replaceAll(',', '.');

    // Remove any non-digit/non-dot chars
    text = text.replaceAll(RegExp(r'[^\d.]'), '');

    // Ensure only one dot
    final parts = text.split('.');
    if (parts.length > 2) {
      text = '${parts[0]}.${parts.sublist(1).join()}';
    }

    // Limit decimal places
    final split = text.split('.');
    if (split.length == 2 && split[1].length > decimalRange) {
      text = '${split[0]}.${split[1].substring(0, decimalRange)}';
    }

    // Avoid leading zeros like 03.75 -> 3.75 (but keep '0' for values < 1)
    final integerPart = text.split('.').first;
    if (integerPart.length > 1 &&
        integerPart.startsWith('0') &&
        !integerPart.startsWith('0.')) {
      final trimmedInt = integerPart.replaceFirst(RegExp(r'^0+'), '');
      text =
          text.replaceFirst(integerPart, trimmedInt.isEmpty ? '0' : trimmedInt);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Helper to format APR percent for display: up to 2 decimals, trim trailing zeros
String formatAprPercent(double aprFraction) {
  final pct = aprFraction * 100.0;
  // Always show two decimals for APR display (e.g. 0.00, 3.75)
  return pct.toStringAsFixed(2);
}

class _LiabilityDetailScreenState extends ConsumerState<LiabilityDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _aprController = TextEditingController();
  final _minPaymentController = TextEditingController();
  final _creditLimitController = TextEditingController();

  String _selectedLiabilityType = 'creditCard';
  bool _isLoading = false;
  Liability? _existingLiability;
  DateTime? _selectedDueDate;
  int _selectedDayOfMonth = 15;

  final Map<String, String> _liabilityTypes = {
    'creditCard': 'Credit Card',
    'mortgage': 'Mortgage',
    'autoLoan': 'Auto Loan',
    'personalLoan': 'Personal Loan',
    'studentLoan': 'Student Loan',
    'lineOfCredit': 'Line of Credit',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    if (widget.liabilityId != null) {
      _loadExistingLiability();
    }
    // For new liabilities show 0.00 by default in the APR field for clarity
    else {
      _aprController.text = '0.00';
    }
  }

  Future<void> _loadExistingLiability() async {
    try {
      final liabilities = await RepositoryService.getLiabilities();
      _existingLiability =
          liabilities.firstWhere((l) => l.id == widget.liabilityId);

      if (_existingLiability != null) {
        _nameController.text = _existingLiability!.name;
        _balanceController.text = _existingLiability!.balance.toString();
        // Format APR for display (e.g. 3.75, not 3.759999999999999)
        _aprController.text = formatAprPercent(_existingLiability!.apr);
        _minPaymentController.text = _existingLiability!.minPayment.toString();
        _selectedLiabilityType = _existingLiability!.kind;
        _selectedDueDate = _existingLiability!.nextPaymentDate;
        _selectedDayOfMonth = _existingLiability!.dayOfMonth ?? 15;
        // Clamp to valid range (1-31) in case older records stored 29-31 but UI previously limited to 28
        if (_selectedDayOfMonth < 1) _selectedDayOfMonth = 1;
        if (_selectedDayOfMonth > 31) _selectedDayOfMonth = 31;

        if (_existingLiability!.creditLimit != null) {
          _creditLimitController.text =
              _existingLiability!.creditLimit.toString();
        }

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading liability: $e')),
        );
      }
    }
  }

  Future<void> _saveLiability() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use selected due date or set default for new liabilities
      final now = DateTime.now();
      final dueDate = _selectedDueDate ??
          DateTime(now.year, now.month + 1, _selectedDayOfMonth);

      final liability = Liability(
        id: widget.liabilityId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        kind: _selectedLiabilityType,
        balance: double.parse(_balanceController.text.replaceAll(',', '')),
        apr: double.parse(_aprController.text) / 100,
        minPayment:
            double.parse(_minPaymentController.text.replaceAll(',', '')),
        creditLimit: _selectedLiabilityType == 'creditCard' &&
                _creditLimitController.text.isNotEmpty
            ? double.parse(_creditLimitController.text.replaceAll(',', ''))
            : null,
        nextPaymentDate: dueDate,
        paymentFrequencyDays: 30, // Monthly payments by default
        dayOfMonth: _selectedDayOfMonth,
        updatedAt: DateTime.now(),
      );

      await ref.read(liabilitiesProvider.notifier).addLiability(liability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liability saved successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving liability: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _aprController.dispose();
    _minPaymentController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.liabilityId != null;
    final isCreditCard = _selectedLiabilityType == 'creditCard';

    // Guard: ensure selected day is valid & represented in dropdown items.
    // (Previously list limited to 28 days; if a stored value 29-31 existed it triggered assertion.)
    if (_selectedDayOfMonth < 1 || _selectedDayOfMonth > 31) {
      _selectedDayOfMonth = _selectedDayOfMonth.clamp(1, 31);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Liability' : 'Add Liability'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveLiability,
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
                        'Liability Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'e.g., Chase Freedom Credit Card',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name for this liability';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLiabilityType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _liabilityTypes.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLiabilityType = value);
                          }
                        },
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
                            return 'Please enter the current balance';
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
                      if (isCreditCard) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _creditLimitController,
                          decoration: const InputDecoration(
                            labelText: 'Credit Limit',
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
                              return null; // Credit limit is optional
                            }
                            // Remove commas before parsing
                            final cleanValue = value.replaceAll(',', '');
                            final limit = double.tryParse(cleanValue);
                            if (limit == null || limit < 0) {
                              return 'Please enter a valid credit limit';
                            }
                            // Remove commas from balance before comparing
                            final cleanBalance =
                                _balanceController.text.replaceAll(',', '');
                            final balance = double.tryParse(cleanBalance) ?? 0;
                            if (limit < balance) {
                              return 'Credit limit cannot be less than current balance';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _aprController,
                              decoration: const InputDecoration(
                                labelText: 'APR',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                suffixText: '%',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                PercentInputFormatter(decimalRange: 2),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the APR';
                                }
                                final apr = double.tryParse(value);
                                if (apr == null || apr < 0 || apr > 100) {
                                  return 'Please enter a valid APR (0-100%)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _minPaymentController,
                              decoration: const InputDecoration(
                                labelText: 'Minimum Payment',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                prefixText: '\$',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                ThousandsSeparatorInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter min payment';
                                }
                                // Remove commas before parsing
                                final cleanValue = value.replaceAll(',', '');
                                final payment = double.tryParse(cleanValue);
                                if (payment == null || payment < 0) {
                                  return 'Enter valid payment';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Payment Schedule',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDueDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            helpText: 'Select next payment due date',
                          );
                          if (selectedDate != null) {
                            setState(() {
                              _selectedDueDate = selectedDate;
                              _selectedDayOfMonth = selectedDate.day;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next Payment Due Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedDueDate != null
                                          ? '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}'
                                          : 'Tap to select date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedDueDate != null
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                          'day-of-month-$_selectedDayOfMonth',
                        ), // force rebuild if value adjusted
                        initialValue:
                            _selectedDayOfMonth > 31 ? 31 : _selectedDayOfMonth,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Payment Day',
                          border: OutlineInputBorder(),
                          helperText: 'Day of each month when payment is due',
                        ),
                        // Support full month range (1-31)
                        items: List.generate(31, (index) => index + 1)
                            .map(
                              (day) => DropdownMenuItem(
                                value: day,
                                child: Text(
                                  '$day${_getOrdinalSuffix(day)} of each month',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedDayOfMonth = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_aprController.text.isNotEmpty &&
                  _balanceController.text.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Stats',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(
                          'Monthly Interest',
                          _calculateMonthlyInterest(),
                        ),
                        _buildStatRow(
                          'Annual Interest Cost',
                          _calculateAnnualInterest(),
                        ),
                        if (isCreditCard &&
                            _creditLimitController.text.isNotEmpty)
                          _buildStatRow(
                            'Credit Utilization',
                            _calculateCreditUtilization(),
                          ),
                      ],
                    ),
                  ),
                ),

              // Payment History Section (only show when editing)
              if (isEditing && _existingLiability != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Payment History',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentHistoryContent(),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveLiability,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Update Liability' : 'Add Liability'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _calculateMonthlyInterest() {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final apr = double.tryParse(_aprController.text) ?? 0;
    final monthlyInterest = balance * (apr / 100) / 12;
    return '\$${monthlyInterest.toStringAsFixed(2)}';
  }

  String _calculateAnnualInterest() {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final apr = double.tryParse(_aprController.text) ?? 0;
    final annualInterest = balance * (apr / 100);
    return '\$${annualInterest.toStringAsFixed(2)}';
  }

  String _calculateCreditUtilization() {
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final limit = double.tryParse(_creditLimitController.text) ?? 0;
    if (limit == 0) return '0%';
    final utilization = (balance / limit) * 100;
    return '${utilization.toStringAsFixed(1)}%';
  }

  Widget _buildPaymentHistoryContent() {
    return FutureBuilder<List<Payment>>(
      future: RepositoryService.getPaymentsForLiability(_existingLiability!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading payment history: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade600),
            ),
          );
        }

        final payments = snapshot.data ?? [];

        if (payments.isEmpty) {
          return Column(
            children: [
              Icon(
                Icons.payment,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No payments recorded yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Payments made through the dashboard will appear here',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return Column(
          children: [
            // Summary stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPaymentStat(
                      'Total Payments',
                      payments.length.toString(),
                      Icons.payments,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.blue.shade200,
                  ),
                  Expanded(
                    child: _buildPaymentStat(
                      'Total Paid',
                      '\$${payments.map((p) => p.amount).reduce((a, b) => a + b).toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.blue.shade200,
                  ),
                  Expanded(
                    child: _buildPaymentStat(
                      'Last Payment',
                      payments.isNotEmpty
                          ? '${payments.first.paidDate.day}/${payments.first.paidDate.month}'
                          : 'None',
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount:
                  payments.length > 5 ? 5 : payments.length, // Show max 5
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentListItem(payment);
              },
            ),

            if (payments.length > 5) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _showAllPaymentsDialog(payments),
                child: Text('View All ${payments.length} Payments'),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPaymentStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentListItem(Payment payment) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.payment,
          color: Colors.green.shade600,
          size: 20,
        ),
      ),
      title: Text(
        payment.formattedAmount,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(payment.paymentDescription),
          if (payment.notes != null && payment.notes!.isNotEmpty)
            Text(
              payment.notes!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${payment.paidDate.day}/${payment.paidDate.month}/${payment.paidDate.year}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (payment.newBalance != null)
            Text(
              'Balance: \$${payment.newBalance!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  void _showAllPaymentsDialog(List<Payment> payments) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 500,
          height: 600,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 8),
                  const Text(
                    'All Payments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: payments.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentListItem(payment);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
