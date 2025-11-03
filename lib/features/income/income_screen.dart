import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../app.dart';
import '../../widgets/currency_text.dart';
import '../../utils/currency_formatter.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(incomesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
      ),
      body: incomesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading income: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(incomesProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (incomes) {
          if (incomes.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildIncomeList(context, incomes, ref);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/income/add'),
        tooltip: 'Add Income Source',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.attach_money,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Income Sources Yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Track your income sources including salary, bonuses, freelance work, and other income streams.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/income/add'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Your First Income Source'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeList(
    BuildContext context,
    List<Income> incomes,
    WidgetRef ref,
  ) {
    // Calculate totals
    final totalMonthlyGross =
        incomes.fold<double>(0, (sum, income) => sum + income.monthlyGross);
    final totalMonthlyNet =
        incomes.fold<double>(0, (sum, income) => sum + income.monthlyNet);
    final totalAnnualGross =
        incomes.fold<double>(0, (sum, income) => sum + income.annualGross);
    final totalAnnualNet =
        incomes.fold<double>(0, (sum, income) => sum + income.annualNet);

    return Column(
      children: [
        // Summary Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Income',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          CurrencyText(
                            totalMonthlyGross,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Net: ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              CurrencyText(
                                totalMonthlyNet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Annual',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          CurrencyText(
                            totalAnnualGross,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Net: ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                              CurrencyText(
                                totalAnnualNet,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Income Sources List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: incomes.length,
            itemBuilder: (context, index) {
              final income = incomes[index];
              return _buildIncomeCard(context, income, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeCard(BuildContext context, Income income, WidgetRef ref) {
    // Check if we should use original currency amount (to avoid rounding errors)
    final settingsAsync = ref.watch(settingsProvider);
    final shouldUseOriginal = settingsAsync.maybeWhen(
      data: (settings) {
        return income.originalCurrency != null &&
            income.originalAmount != null &&
            income.originalCurrency == settings.currency;
      },
      orElse: () => false,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/income/${income.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          income.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          income.kind,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Use original amount if currency matches to avoid rounding errors
                      if (shouldUseOriginal)
                        _buildOriginalCurrencyAmount(
                          context,
                          income,
                          ref,
                        )
                      else
                        CurrencyText(
                          income.monthlyGross,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                        ),
                      Text(
                        '/ month',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNetChip(
                      context,
                      income.monthlyNet,
                      shouldUseOriginal,
                      income,
                      ref,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      'Tax Rate',
                      '${income.effectiveTaxRate.toStringAsFixed(1)}%',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      'Frequency',
                      income.frequency,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateMonthlyAmount(double amount, String frequency) {
    switch (frequency) {
      case 'biweekly':
        return amount * 26 / 12;
      case 'weekly':
        return amount * 52 / 12;
      case 'annual':
        return amount / 12;
      case 'quarterly':
        return amount * 4 / 12;
      default: // monthly
        return amount;
    }
  }

  Widget _buildOriginalCurrencyAmount(
    BuildContext context,
    Income income,
    WidgetRef ref,
  ) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (settings) {
        final monthlyOriginal = _calculateMonthlyAmount(
          income.originalAmount!,
          income.frequency,
        );

        return Text(
          CurrencyFormatter.format(monthlyOriginal, income.originalCurrency!),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetChip(
    BuildContext context,
    double amount,
    bool shouldUseOriginal,
    Income income,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          // Use original amount if currency matches to avoid rounding errors
          if (shouldUseOriginal)
            _buildOriginalNetAmount(context, income, ref)
          else
            CurrencyText(
              amount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildOriginalNetAmount(
    BuildContext context,
    Income income,
    WidgetRef ref,
  ) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (settings) {
        if (income.originalAmount == null) {
          return const SizedBox();
        }

        // Calculate monthly original gross amount based on frequency
        final monthlyOriginalGross = _calculateMonthlyAmount(
          income.originalAmount!,
          income.frequency,
        );

        // Calculate the deduction ratio from the USD-based values
        // This ratio includes all deductions (taxes, retirement, insurance, etc.)
        final deductionRatio = income.grossAmount > 0
            ? income.totalDeductions / income.grossAmount
            : 0.0;

        // Apply the same deduction ratio to the original amount to get net
        final monthlyOriginalNet = monthlyOriginalGross * (1 - deductionRatio);

        final formattedAmount = CurrencyFormatter.format(
          monthlyOriginalNet,
          settings.currency,
        );

        return Text(
          formattedAmount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        );
      },
    );
  }
}
