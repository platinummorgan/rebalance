import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../widgets/currency_text.dart';
import '../../utils/currency_formatter.dart';
import '../../generated/app_localizations.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expensesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.monthlyExpenses),
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(loc.errorLoadingDataWithError(error.toString())),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(expensesProvider.notifier).reload(),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
        data: (expenses) => settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text(loc.errorWithMessage(error.toString()))),
          data: (settings) {
            if (expenses.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildExpensesList(context, ref, expenses, settings);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/expenses/add'),
        tooltip: loc.addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            loc.noExpensesTracked,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            loc.trackMonthlyBills,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/expenses/add'),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(loc.addYourFirstExpense),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    WidgetRef ref,
    List<MonthlyExpense> expenses,
    Settings settings,
  ) {
    final loc = AppLocalizations.of(context)!;
    final totalMonthly = expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final weeklyTotal = totalMonthly / 4.33;

    return Column(
      children: [
        // Summary header
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                loc.totalMonthlyExpenses,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              CurrencyText(
                totalMonthly,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${CurrencyFormatter.format(weeklyTotal, settings.currency)}${loc.perWeekFull}',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Expense list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return _buildExpenseCard(context, ref, expense, settings);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    WidgetRef ref,
    MonthlyExpense expense,
    Settings settings,
  ) {
    final loc = AppLocalizations.of(context)!;
    final iconData = _getIconForCategory(expense.category);
    final weeklyAmount = expense.amount / 4.33;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            iconData,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          expense.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: expense.dueDay != null
            ? Text(loc.dueOnDay(expense.dueDay.toString()))
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CurrencyText(
              expense.amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              '${CurrencyFormatter.format(weeklyAmount, settings.currency)}${loc.perWeekShort}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onTap: () => context.push('/expenses/edit/${expense.id}'),
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category) {
      case 'rent':
        return Icons.home;
      case 'utilities':
        return Icons.bolt;
      case 'insurance':
        return Icons.shield;
      case 'subscription':
        return Icons.subscriptions;
      default:
        return Icons.receipt_long;
    }
  }
}
