import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../app.dart';
import '../../widgets/currency_text.dart';
import '../../utils/currency_formatter.dart';
import '../../generated/app_localizations.dart';

class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomesAsync = ref.watch(incomesProvider);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.income),
      ),
      body: incomesAsync.when(
        loading: () => Center(child: Text(loc.loading)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade600),
              const SizedBox(height: 16),
              Text('${loc.errorLoadingIncome}: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(incomesProvider.notifier).reload(),
                child: Text(loc.retry),
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
        tooltip: loc.addIncomeSource,
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
              Icons.attach_money,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            loc.noIncomeSourcesYet,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            loc.trackYourIncomeSources,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/income/add'),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(loc.addYourFirstIncomeSource),
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
    final loc = AppLocalizations.of(context)!;
    // Calculate totals
    final totalMonthlyGross =
        incomes.fold<double>(0, (sum, income) => sum + income.monthlyGross);
    final totalMonthlyNet =
        incomes.fold<double>(0, (sum, income) => sum + income.monthlyNet);

    return Column(
      children: [
        // Summary header (matching Assets/Debts style)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade100.withValues(alpha: 0.3),
                Colors.green.shade50.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.totalMonthlyIncome,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CurrencyText(
                          totalMonthlyGross,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${incomes.length} ${incomes.length == 1 ? loc.source : loc.sources}',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.netIncome,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CurrencyText(
                          totalMonthlyNet,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          loc.taxRate,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalMonthlyGross > 0
                              ? '${(((totalMonthlyGross - totalMonthlyNet) / totalMonthlyGross) * 100).toStringAsFixed(1)}%'
                              : '0.0%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getIncomeKindColor(context, income.kind),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIncomeIcon(income.kind),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Text(
                income.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getIncomeKindColor(
                            context,
                            income.kind,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getIncomeKindColor(
                              context,
                              income.kind,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _getIncomeTypeDisplayName(context, income.kind),
                          style: TextStyle(
                            color: _getIncomeKindColor(
                              context,
                              income.kind,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _translateFrequency(context, income.frequency),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Consumer(
                builder: (context, ref, child) {
                  final settingsAsync = ref.watch(settingsProvider);
                  final shouldUseOriginal = settingsAsync.maybeWhen(
                    data: (settings) =>
                        income.originalCurrency != null &&
                        income.originalAmount != null &&
                        income.originalCurrency == settings.currency,
                    orElse: () => false,
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (shouldUseOriginal)
                        _buildOriginalCurrencyAmount(
                          context,
                          income,
                          ref,
                        )
                      else
                        CurrencyText(
                          income.monthlyGross,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green.shade700,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.net}: ',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (shouldUseOriginal)
                            _buildOriginalNetAmount(context, income, ref)
                          else
                            CurrencyText(
                              income.monthlyNet,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              onTap: () => context.push('/income/${income.id}'),
            ),
          ),

          // Delete button in top-right corner
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => _showDeleteIncomeDialog(context, ref, income),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ),
        ],
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

  IconData _getIncomeIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'salary':
      case 'w2':
        return Icons.business_center;
      case 'bonus':
        return Icons.card_giftcard;
      case 'freelance':
      case '1099':
        return Icons.work_outline;
      case 'investment':
        return Icons.trending_up;
      case 'rental':
        return Icons.home;
      case 'pension':
        return Icons.elderly;
      case 'social security':
        return Icons.account_balance;
      default:
        return Icons.attach_money;
    }
  }

  Color _getIncomeKindColor(BuildContext context, String kind) {
    switch (kind.toLowerCase()) {
      case 'salary':
      case 'w2':
        return Colors.blue;
      case 'bonus':
        return Colors.purple;
      case 'freelance':
      case '1099':
        return Colors.orange;
      case 'investment':
        return Colors.green;
      case 'rental':
        return Colors.brown;
      case 'pension':
        return Colors.teal;
      case 'social security':
        return Colors.indigo;
      default:
        return Colors.green.shade700;
    }
  }

  String _getIncomeTypeDisplayName(BuildContext context, String kind) {
    final loc = AppLocalizations.of(context)!;
    switch (kind.toLowerCase()) {
      case 'salary':
        return loc.incomeSalary;
      case 'w2':
        return loc.incomeW2;
      case 'bonus':
        return loc.incomeBonus;
      case 'freelance':
        return loc.incomeFreelance;
      case '1099':
        return loc.income1099;
      case 'investment':
        return loc.incomeInvestment;
      case 'rental':
        return loc.incomeRental;
      case 'pension':
        return loc.incomePension;
      case 'social security':
        return loc.incomeSocialSecurity;
      default:
        return kind;
    }
  }

  String _translateFrequency(BuildContext context, String frequency) {
    final loc = AppLocalizations.of(context)!;
    switch (frequency.toLowerCase()) {
      case 'monthly':
        return loc.frequencyMonthly;
      case 'biweekly':
        return loc.frequencyBiweekly;
      case 'weekly':
        return loc.frequencyWeekly;
      case 'annual':
        return loc.frequencyAnnual;
      case 'quarterly':
        return loc.frequencyQuarterly;
      default:
        return frequency[0].toUpperCase() + frequency.substring(1);
    }
  }

  void _showDeleteIncomeDialog(
    BuildContext context,
    WidgetRef ref,
    Income income,
  ) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteIncomeSource),
        content: Text(loc.areYouSureDeleteIncome),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await RepositoryService.deleteIncome(income.id);
                if (context.mounted) {
                  await ref.read(incomesProvider.notifier).reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.deletedSuccessfully),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${loc.errorDeletingIncome}: $e'),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade600,
            ),
            child: Text(loc.delete),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        );
      },
    );
  }
}
