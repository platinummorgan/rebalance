import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../app.dart';
import '../../utils/currency_formatter.dart';
import '../../services/exchange_rate_service.dart';
import '../../generated/app_localizations.dart';

class IncomeDetailScreen extends ConsumerStatefulWidget {
  final String? incomeId;

  const IncomeDetailScreen({super.key, this.incomeId});

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _grossAmountController = TextEditingController();
  final _federalTaxController = TextEditingController();
  final _stateTaxController = TextEditingController();
  final _socialSecurityTaxController = TextEditingController();
  final _medicareTaxController = TextEditingController();
  final _retirement401kController = TextEditingController();
  final _healthInsuranceController = TextEditingController();
  final _otherDeductionsController = TextEditingController();

  String _selectedIncomeType = 'Salary';
  String _selectedFrequency = 'Monthly';
  bool _isLoading = false;
  Income? _existingIncome;
  bool _showTaxBreakdown = false;

  final List<String> _incomeTypes = [
    'Salary',
    'Hourly Wage',
    'Bonus',
    'Commission',
    'Freelance',
    'Rental Income',
    'Investment Income',
    'Pension',
    'Social Security',
    'Other',
  ];

  final List<String> _frequencies = [
    'Hourly',
    'Daily',
    'Weekly',
    'Bi-Weekly',
    'Semi-Monthly',
    'Monthly',
    'Quarterly',
    'Annually',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.incomeId != null) {
      _loadExistingIncome();
    }
  }

  Future<void> _loadExistingIncome() async {
    try {
      final incomes = await RepositoryService.getIncomes();
      _existingIncome = incomes.firstWhere((i) => i.id == widget.incomeId);

      if (_existingIncome != null) {
        // Get user's display currency
        final settings = await RepositoryService.getSettings();
        final displayCurrency = settings.currency;

        // Use original currency/amount if available to avoid rounding errors
        // Otherwise convert from USD
        final double displayAmount;

        if (_existingIncome!.originalCurrency != null &&
            _existingIncome!.originalAmount != null &&
            _existingIncome!.originalCurrency == displayCurrency) {
          // Same currency - use original amount directly (no rounding!)
          displayAmount = _existingIncome!.originalAmount!;
        } else {
          // Different currency or no original - convert from USD
          final exchangeService = ExchangeRateService();
          displayAmount = await exchangeService.convert(
            _existingIncome!.grossAmount,
            'USD',
            displayCurrency,
          );
        }

        _nameController.text = _existingIncome!.name;
        _grossAmountController.text = displayAmount.toStringAsFixed(2);
        _selectedIncomeType = _existingIncome!.kind;
        _selectedFrequency = _existingIncome!.frequency;

        // Load tax breakdown if available
        if (_existingIncome!.federalTax != null ||
            _existingIncome!.stateTax != null ||
            _existingIncome!.socialSecurityTax != null ||
            _existingIncome!.medicareTax != null ||
            _existingIncome!.retirement401k != null ||
            _existingIncome!.healthInsurance != null ||
            _existingIncome!.otherDeductions != null) {
          _showTaxBreakdown = true;

          final exchangeService = ExchangeRateService();

          // Convert all tax/deduction amounts to display currency
          if (_existingIncome!.federalTax != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.federalTax!,
              'USD',
              displayCurrency,
            );
            _federalTaxController.text = converted.toStringAsFixed(2);
          }
          if (_existingIncome!.stateTax != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.stateTax!,
              'USD',
              displayCurrency,
            );
            _stateTaxController.text = converted.toStringAsFixed(2);
          }
          if (_existingIncome!.socialSecurityTax != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.socialSecurityTax!,
              'USD',
              displayCurrency,
            );
            _socialSecurityTaxController.text = converted.toStringAsFixed(2);
          }
          if (_existingIncome!.medicareTax != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.medicareTax!,
              'USD',
              displayCurrency,
            );
            _medicareTaxController.text = converted.toStringAsFixed(2);
          }
          if (_existingIncome!.retirement401k != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.retirement401k!,
              'USD',
              displayCurrency,
            );
            _retirement401kController.text = converted.toStringAsFixed(2);
          }
          if (_existingIncome!.healthInsurance != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.healthInsurance!,
              'USD',
              displayCurrency,
            );
            _healthInsuranceController.text = converted.toStringAsFixed(2);
          }
          if (_existingIncome!.otherDeductions != null) {
            final converted = await exchangeService.convert(
              _existingIncome!.otherDeductions!,
              'USD',
              displayCurrency,
            );
            _otherDeductionsController.text = converted.toStringAsFixed(2);
          }
        }

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading income: $e')),
        );
      }
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get user's display currency
      final settings = await RepositoryService.getSettings();
      final displayCurrency = settings.currency;
      final exchangeService = ExchangeRateService();

      // Convert all amounts from display currency to USD for storage
      final grossAmountInDisplayCurrency =
          double.parse(_grossAmountController.text);
      final grossAmountUSD = await exchangeService.convert(
        grossAmountInDisplayCurrency,
        displayCurrency,
        'USD',
      );

      double? federalTaxUSD;
      if (_showTaxBreakdown && _federalTaxController.text.isNotEmpty) {
        final amount = double.tryParse(_federalTaxController.text);
        if (amount != null) {
          federalTaxUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      double? stateTaxUSD;
      if (_showTaxBreakdown && _stateTaxController.text.isNotEmpty) {
        final amount = double.tryParse(_stateTaxController.text);
        if (amount != null) {
          stateTaxUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      double? socialSecurityTaxUSD;
      if (_showTaxBreakdown && _socialSecurityTaxController.text.isNotEmpty) {
        final amount = double.tryParse(_socialSecurityTaxController.text);
        if (amount != null) {
          socialSecurityTaxUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      double? medicareTaxUSD;
      if (_showTaxBreakdown && _medicareTaxController.text.isNotEmpty) {
        final amount = double.tryParse(_medicareTaxController.text);
        if (amount != null) {
          medicareTaxUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      double? retirement401kUSD;
      if (_showTaxBreakdown && _retirement401kController.text.isNotEmpty) {
        final amount = double.tryParse(_retirement401kController.text);
        if (amount != null) {
          retirement401kUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      double? healthInsuranceUSD;
      if (_showTaxBreakdown && _healthInsuranceController.text.isNotEmpty) {
        final amount = double.tryParse(_healthInsuranceController.text);
        if (amount != null) {
          healthInsuranceUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      double? otherDeductionsUSD;
      if (_showTaxBreakdown && _otherDeductionsController.text.isNotEmpty) {
        final amount = double.tryParse(_otherDeductionsController.text);
        if (amount != null) {
          otherDeductionsUSD =
              await exchangeService.convert(amount, displayCurrency, 'USD');
        }
      }

      final income = Income(
        id: _existingIncome?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        kind: _selectedIncomeType,
        grossAmount: grossAmountUSD,
        frequency: _selectedFrequency,
        updatedAt: DateTime.now(),
        federalTax: federalTaxUSD,
        stateTax: stateTaxUSD,
        socialSecurityTax: socialSecurityTaxUSD,
        medicareTax: medicareTaxUSD,
        retirement401k: retirement401kUSD,
        healthInsurance: healthInsuranceUSD,
        otherDeductions: otherDeductionsUSD,
        // Store original currency and amount to avoid rounding errors
        originalCurrency: displayCurrency,
        originalAmount: grossAmountInDisplayCurrency,
      );

      await RepositoryService.saveIncome(income);
      await ref.read(incomesProvider.notifier).reload();

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingIncome == null
                  ? 'Income source added successfully'
                  : 'Income source updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving income: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteIncome() async {
    if (_existingIncome == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income Source'),
        content: Text(
          'Are you sure you want to delete "${_existingIncome!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await RepositoryService.deleteIncome(_existingIncome!.id);
        await ref.read(incomesProvider.notifier).reload();

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income source deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting income: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _grossAmountController.dispose();
    _federalTaxController.dispose();
    _stateTaxController.dispose();
    _socialSecurityTaxController.dispose();
    _medicareTaxController.dispose();
    _retirement401kController.dispose();
    _healthInsuranceController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = settingsAsync.value != null
        ? CurrencyFormatter.format(0, settingsAsync.value!.currency)
            .replaceAll('0', '')
            .replaceAll('.', '')
            .replaceAll(',', '')
            .trim()
        : '\$';

    return Scaffold(
      appBar: AppBar(
        title: Text(_existingIncome == null ? 'Add Income' : 'Edit Income'),
        actions: [
          if (_existingIncome != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteIncome,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Income Source Name',
                hintText: 'e.g., Main Job, Freelance Work',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Income Type
            DropdownButtonFormField<String>(
              initialValue: _selectedIncomeType,
              decoration: const InputDecoration(
                labelText: 'Income Type',
                border: OutlineInputBorder(),
              ),
              items: _incomeTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedIncomeType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Gross Amount
            TextFormField(
              controller: _grossAmountController,
              decoration: InputDecoration(
                labelText: 'Gross Amount',
                hintText: '0.00',
                border: const OutlineInputBorder(),
                prefixText: '$currencySymbol ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Frequency
            DropdownButtonFormField<String>(
              initialValue: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: _frequencies.map((freq) {
                return DropdownMenuItem(value: freq, child: Text(freq));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFrequency = value!);
              },
            ),
            const SizedBox(height: 24),

            // Tax Breakdown Toggle
            CheckboxListTile(
              title: const Text('Add Tax & Deduction Breakdown'),
              subtitle: const Text('Track federal tax, state tax, 401k, etc.'),
              value: _showTaxBreakdown,
              onChanged: (value) {
                setState(() => _showTaxBreakdown = value ?? false);
              },
            ),

            if (_showTaxBreakdown) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Deductions (per payment period)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Federal Tax
              TextFormField(
                controller: _federalTaxController,
                decoration: InputDecoration(
                  labelText: 'Federal Tax',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),

              // State Tax
              TextFormField(
                controller: _stateTaxController,
                decoration: InputDecoration(
                  labelText: 'State Tax',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),

              // Social Security
              TextFormField(
                controller: _socialSecurityTaxController,
                decoration: InputDecoration(
                  labelText: 'Social Security Tax',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),

              // Medicare
              TextFormField(
                controller: _medicareTaxController,
                decoration: InputDecoration(
                  labelText: 'Medicare Tax',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),

              // 401k
              TextFormField(
                controller: _retirement401kController,
                decoration: InputDecoration(
                  labelText: '401(k) / Retirement Contribution',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),

              // Health Insurance
              TextFormField(
                controller: _healthInsuranceController,
                decoration: InputDecoration(
                  labelText: 'Health Insurance Premium',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 12),

              // Other Deductions
              TextFormField(
                controller: _otherDeductionsController,
                decoration: InputDecoration(
                  labelText: 'Other Deductions',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '$currencySymbol ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : _saveIncome,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _existingIncome == null ? 'Add Income' : 'Save Changes',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
