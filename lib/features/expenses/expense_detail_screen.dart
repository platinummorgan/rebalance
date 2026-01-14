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

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseDetailScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDayController = TextEditingController();

  String _selectedCategory = 'other';
  bool _isLoading = false;
  MonthlyExpense? _existingExpense;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'rent', 'label': 'Rent/Mortgage', 'icon': Icons.home},
    {'value': 'utilities', 'label': 'Utilities', 'icon': Icons.bolt},
    {'value': 'insurance', 'label': 'Insurance', 'icon': Icons.shield},
    {
      'value': 'subscription',
      'label': 'Subscriptions',
      'icon': Icons.subscriptions
    },
    {'value': 'other', 'label': 'Other', 'icon': Icons.receipt_long},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      _loadExistingExpense();
    }
  }

  Future<void> _loadExistingExpense() async {
    try {
      final expenses = await RepositoryService.getExpenses();
      _existingExpense = expenses.firstWhere((e) => e.id == widget.expenseId);

      if (_existingExpense != null) {
        final settings = await RepositoryService.getSettings();
        final displayCurrency = settings.currency;

        final double displayAmount;
        if (_existingExpense!.originalCurrency != null &&
            _existingExpense!.originalAmount != null &&
            _existingExpense!.originalCurrency == displayCurrency) {
          displayAmount = _existingExpense!.originalAmount!;
        } else {
          final exchangeService = ExchangeRateService();
          displayAmount = await exchangeService.convert(
            _existingExpense!.amount,
            'USD',
            displayCurrency,
          );
        }

        _nameController.text = _existingExpense!.name;
        _amountController.text = displayAmount.toStringAsFixed(2);
        _selectedCategory = _existingExpense!.category ?? 'other';
        if (_existingExpense!.dueDay != null) {
          _dueDayController.text = _existingExpense!.dueDay.toString();
        }

        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expense: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isEditing = widget.expenseId != null;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEditing ? 'Edit Expense' : 'Add Expense'), // TODO: localize
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: loc.delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Expense Name', // TODO: localize
                hintText: 'e.g., Electric Bill, Internet', // TODO: localize
                prefixIcon: const Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name'; // TODO: localize
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Amount field
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monthly Amount', // TODO: localize
                hintText: '150', // TODO: localize
                prefixIcon: const Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(7),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount'; // TODO: localize
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount'; // TODO: localize
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category selector
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category', // TODO: localize
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['value'] as String,
                  child: Row(
                    children: [
                      Icon(cat['icon'] as IconData, size: 20),
                      const SizedBox(width: 12),
                      Text(cat['label'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Due day (optional)
            TextFormField(
              controller: _dueDayController,
              decoration: InputDecoration(
                labelText: 'Due Day (Optional)', // TODO: localize
                hintText: 'e.g., 15 for 15th of month', // TODO: localize
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final day = int.tryParse(value);
                  if (day == null || day < 1 || day > 31) {
                    return 'Must be between 1 and 31'; // TODO: localize
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: _isLoading ? null : _saveExpense,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing
                      ? loc.saveChanges
                      : 'Add Expense'), // TODO: localize
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await RepositoryService.getSettings();
      final displayCurrency = settings.currency;
      final exchangeService = ExchangeRateService();

      // Get amounts in display currency
      final amountInDisplayCurrency = double.parse(_amountController.text);

      // Convert to USD for storage
      final amountInUSD = await exchangeService.convert(
        amountInDisplayCurrency,
        displayCurrency,
        'USD',
      );

      final int? dueDay = _dueDayController.text.isNotEmpty
          ? int.tryParse(_dueDayController.text)
          : null;

      final expense = MonthlyExpense(
        id: _existingExpense?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        amount: amountInUSD,
        updatedAt: DateTime.now(),
        dueDay: dueDay,
        category: _selectedCategory,
        originalCurrency: displayCurrency,
        originalAmount: amountInDisplayCurrency,
      );

      await RepositoryService.saveExpense(expense);
      await ref.read(expensesProvider.notifier).reload();

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _existingExpense != null
                  ? 'Expense updated' // TODO: localize
                  : 'Expense added', // TODO: localize
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Expense?'), // TODO: localize
        content: Text(
            'Are you sure you want to delete this expense?'), // TODO: localize
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await RepositoryService.deleteExpense(widget.expenseId!);
        await ref.read(expensesProvider.notifier).reload();

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Expense deleted')), // TODO: localize
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expense: $e')),
          );
        }
      }
    }
  }
}
