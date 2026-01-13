import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../app.dart';
import '../../widgets/currency_text.dart';
import '../../utils/currency_formatter.dart';
import '../../generated/app_localizations.dart';

class LiabilitiesScreen extends ConsumerWidget {
  const LiabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final liabilitiesAsync = ref.watch(liabilitiesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.debtsAndLiabilities),
      ),
      body: liabilitiesAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(semanticsLabel: loc.loading),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('${loc.errorLoadingLiabilities}: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(liabilitiesProvider.notifier).reload(),
                child: Text(loc.retry),
              ),
            ],
          ),
        ),
        data: (liabilities) => settingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (settings) {
            if (liabilities.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildLiabilitiesList(context, ref, liabilities, settings);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/liabilities/add'),
        tooltip: loc.addLiability,
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
              color: Theme.of(context).colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            loc.noDebtsTracked,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            loc.trackCreditCardsAndLoans,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/liabilities/add'),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(loc.addYourFirstLiability),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showDebtTypesInfo(context),
            child: Text(loc.whatTypesOfDebt),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesList(
    BuildContext context,
    WidgetRef ref,
    List<Liability> liabilities,
    Settings settings,
  ) {
    final loc = AppLocalizations.of(context)!;
    // Filter out paid-off debts (balance = 0)
    final activeDebts =
        liabilities.where((liability) => liability.balance > 0).toList();

    final totalDebt = activeDebts.fold<double>(
      0.0,
      (sum, liability) => sum + liability.balance,
    );
    final totalMinPayments = activeDebts.fold<double>(
      0.0,
      (sum, liability) => sum + liability.minPayment,
    );

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
                Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.error.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.credit_card,
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
                          loc.totalDebt,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CurrencyText(
                          totalDebt,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${activeDebts.length} ${activeDebts.length == 1 ? loc.debt : loc.debtsPlural}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
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
                          loc.monthlyPayments,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CurrencyText(
                          totalMinPayments,
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
                          loc.avgInterestRate,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_calculateWeightedAPR(liabilities).toStringAsFixed(1)}%',
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

        // Debt Optimizer CTA
        if (activeDebts.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/debt-optimizer'),
                icon: const Icon(Icons.auto_awesome),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc.optimizePayoffStrategy),
                    if (!settings.isPro) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

        // Liabilities list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: liabilities.length,
            itemBuilder: (context, index) {
              final liability = liabilities[index];

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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                _getLiabilityKindColor(context, liability.kind),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getLiabilityIcon(liability.kind),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          liability.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${(liability.apr * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final settingsAsync =
                                        ref.watch(settingsProvider);
                                    return settingsAsync.maybeWhen(
                                      data: (settings) {
                                        final shouldUseOriginal =
                                            liability.originalCurrency !=
                                                    null &&
                                                liability.originalMinPayment !=
                                                    null &&
                                                liability.originalCurrency ==
                                                    settings.currency;

                                        final minPaymentText = shouldUseOriginal
                                            ? CurrencyFormatter.format(
                                                liability.originalMinPayment!,
                                                liability.originalCurrency!,
                                              )
                                            : CurrencyFormatter.format(
                                                liability.minPayment,
                                                settings.currency,
                                              );

                                        return Text(
                                          '${loc.minPayment} $minPaymentText/mo',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                      orElse: () => const SizedBox.shrink(),
                                    );
                                  },
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
                                  liability.originalCurrency != null &&
                                  liability.originalBalance != null &&
                                  liability.originalCurrency ==
                                      settings.currency,
                              orElse: () => false,
                            );

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (shouldUseOriginal)
                                  settingsAsync.when(
                                    loading: () => const SizedBox(),
                                    error: (_, __) => const SizedBox(),
                                    data: (settings) => Text(
                                      CurrencyFormatter.format(
                                        liability.originalBalance!,
                                        liability.originalCurrency!,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color:
                                            Theme.of(context).colorScheme.error,
                                      ),
                                    ),
                                  )
                                else
                                  CurrencyText(
                                    liability.balance,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                if (liability.creditLimit != null &&
                                    liability.creditLimit! > 0)
                                  Text(
                                    '${((liability.balance / liability.creditLimit!) * 100).toStringAsFixed(0)}% ${loc.used}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  )
                                else
                                  Text(
                                    '${loc.updated} ${_getRelativeTime(context, liability.updatedAt)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        onTap: () =>
                            context.push('/liabilities/${liability.id}'),
                      ),
                    ),

                    // Delete button in top-right corner
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () =>
                            _showDeleteLiabilityDialog(context, ref, liability),
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
            },
          ),
        ),
      ],
    );
  }

  double _calculateWeightedAPR(List<Liability> liabilities) {
    if (liabilities.isEmpty) return 0.0;

    double totalWeightedAPR = 0.0;
    double totalBalance = 0.0;

    for (final liability in liabilities) {
      totalWeightedAPR += liability.apr * liability.balance;
      totalBalance += liability.balance;
    }

    return totalBalance > 0 ? (totalWeightedAPR / totalBalance) * 100 : 0.0;
  }

  IconData _getLiabilityIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'creditcard':
        return Icons.credit_card;
      case 'mortgage':
        return Icons.home;
      case 'autoloan':
        return Icons.directions_car;
      case 'studentloan':
        return Icons.school;
      case 'personalloan':
        return Icons.person;
      case 'heloc':
        return Icons.home_work;
      case 'businessloan':
        return Icons.business;
      default:
        return Icons.payment;
    }
  }

  Color _getLiabilityKindColor(BuildContext context, String kind) {
    switch (kind.toLowerCase()) {
      case 'creditcard':
        return Colors.red;
      case 'mortgage':
        return Colors.brown;
      case 'autoloan':
        return Colors.blue;
      case 'studentloan':
        return Colors.purple;
      case 'personalloan':
        return Colors.orange;
      case 'heloc':
        return Colors.teal;
      case 'businessloan':
        return Colors.indigo;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _getRelativeTime(BuildContext context, DateTime dateTime) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ${loc.ago}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${loc.ago}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ${loc.ago}';
    } else {
      return loc.justNow;
    }
  }

  void _showDebtTypesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.typesOfDebtYouCanTrack),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.creditCardsDescription),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.mortgagesDescription),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.autoLoansDescription),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.studentLoansDescription),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.personalLoansDescription),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.helocDescription),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.businessLoansDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.gotIt),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/liabilities/add');
            },
            child: Text(AppLocalizations.of(context)!.addDebt),
          ),
        ],
      ),
    );
  }

  void _showDeleteLiabilityDialog(
    BuildContext context,
    WidgetRef ref,
    Liability liability,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Liability'),
        content: Text(
          'Are you sure you want to delete "${liability.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await RepositoryService.deleteLiability(liability.id);
                if (context.mounted) {
                  // Refresh both providers to update the UI and dashboard calculations
                  await ref.read(liabilitiesProvider.notifier).reload();
                  await ref.read(accountsProvider.notifier).reload();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${liability.name} deleted successfully'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting liability: $e'),
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
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}
