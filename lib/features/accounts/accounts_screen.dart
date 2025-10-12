import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../data/repositories.dart';
import '../../app.dart';

class AccountsScreen extends ConsumerWidget {
  final String? assetTypeFilter;

  const AccountsScreen({super.key, this.assetTypeFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final fromSnapshot =
        GoRouterState.of(context).uri.queryParameters['fromSnapshot'] == 'true';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          assetTypeFilter != null ? '$assetTypeFilter Accounts' : 'Accounts',
        ),
        actions: [
          if (fromSnapshot)
            TextButton.icon(
              onPressed: () => _navigateBackToSnapshot(context, ref),
              icon: const Icon(Icons.assessment, size: 18),
              label: const Text('Back to Snapshot'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          if (assetTypeFilter != null && !fromSnapshot)
            TextButton(
              onPressed: () => context.push('/accounts'),
              child: Text(
                'Show All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading accounts: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(accountsProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (accounts) {
          // Filter accounts based on asset type if specified
          final filteredAccounts = assetTypeFilter != null
              ? _filterAccountsByAssetType(accounts, assetTypeFilter!)
              : accounts;

          if (filteredAccounts.isEmpty) {
            return _buildEmptyState(
              context,
              isFiltered: assetTypeFilter != null,
            );
          }
          return _buildAccountsList(
            context,
            filteredAccounts,
            ref,
            fromSnapshot: fromSnapshot,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/accounts/add'),
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isFiltered = false}) {
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
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isFiltered ? 'No $assetTypeFilter Accounts' : 'No Accounts Yet',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltered
                ? 'No accounts found with $assetTypeFilter allocation. Try viewing all accounts or add a new account with $assetTypeFilter investments.'
                : 'Add your first account to start tracking your net worth and asset allocation.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (isFiltered) ...[
            OutlinedButton(
              onPressed: () => context.push('/accounts'),
              child: const Text('View All Accounts'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/accounts/add'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add New Account'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ] else
            FilledButton.icon(
              onPressed: () => context.push('/accounts/add'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Your First Account'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    List<Account> accounts,
    WidgetRef ref, {
    bool fromSnapshot = false,
  }) {
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final fullFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
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
                      'Total Assets',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(totalAssets),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Info banner when from snapshot
        if (fromSnapshot)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assessment,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtered from snapshot analysis',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateBackToSnapshot(context, ref),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Back to Snapshot',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Accounts list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final percentage = totalAssets > 0
                  ? ((account.balance / totalAssets) * 100)
                  : 0.0;

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
                            color: _getAccountKindColor(context, account.kind),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getAccountIcon(account.kind),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          account.name,
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
                                    color: _getAccountKindColor(
                                      context,
                                      account.kind,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getAccountKindColor(
                                        context,
                                        account.kind,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _getAccountTypeDisplayName(account.kind),
                                    style: TextStyle(
                                      color: _getAccountKindColor(
                                        context,
                                        account.kind,
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fullFormatter.format(account.balance),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Updated ${_getRelativeTime(account.updatedAt)}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/accounts/${account.id}'),
                      ),
                    ),

                    // Delete button in top-right corner
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () =>
                            _showDeleteAccountDialog(context, ref, account),
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

  IconData _getAccountIcon(String kind) {
    switch (kind.toLowerCase()) {
      case 'cash':
      case 'checking':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'brokerage':
      case 'investment':
        return Icons.trending_up;
      case 'retirement':
        return Icons.elderly;
      case 'crypto':
        return Icons.currency_bitcoin;
      case 'realestate':
      case 'realestateequity':
        return Icons.home;
      case 'hsa':
        return Icons.medical_services;
      case '529':
        return Icons.school;
      default:
        return Icons.account_balance_wallet;
    }
  }

  Color _getAccountKindColor(BuildContext context, String kind) {
    switch (kind.toLowerCase()) {
      case 'cash':
      case 'checking':
        return Colors.green;
      case 'savings':
        return Colors.blue;
      case 'brokerage':
      case 'investment':
        return Colors.purple;
      case 'retirement':
        return Colors.orange;
      case 'crypto':
        return Colors.amber;
      case 'realestate':
      case 'realestateequity':
        return Colors.brown;
      case 'hsa':
        return Colors.teal;
      case '529':
        return Colors.indigo;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getAccountTypeDisplayName(String kind) {
    switch (kind.toLowerCase()) {
      case 'checking':
        return 'Checking';
      case 'savings':
        return 'Savings';
      case 'brokerage':
        return 'Brokerage';
      case 'retirement':
        return '401k/IRA';
      case 'hsa':
        return 'HSA';
      case 'cd':
        return 'CD';
      case 'cash':
        return 'Cash';
      case 'crypto':
        return 'Crypto';
      case 'realestate':
        return 'Real Estate';
      default:
        return kind.toUpperCase();
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<Account> _filterAccountsByAssetType(
    List<Account> accounts,
    String assetType,
  ) {
    return accounts.where((account) {
      switch (assetType) {
        case 'Cash':
          return account.pctCash > 0.0;
        case 'Bonds':
          return account.pctBonds > 0.0;
        case 'US Equity':
          return account.pctUsEq > 0.0;
        case 'Intl Equity':
          return account.pctIntlEq > 0.0;
        case 'Real Estate':
          return account.pctRealEstate > 0.0;
        case 'Alternatives':
          return account.pctAlt > 0.0;
        default:
          return true; // Show all accounts if unknown filter
      }
    }).toList();
  }
}

void _navigateBackToSnapshot(BuildContext context, WidgetRef ref) {
  // Navigate back to dashboard first
  context.go('/dashboard');

  // Then show the Net Worth History sheet
  // We'll need to trigger the sheet opening after navigation
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showNetWorthHistory(context, ref);
  });
}

void _showNetWorthHistory(BuildContext context, WidgetRef ref) {
  final snapshotsAsync = ref.read(snapshotsProvider);
  snapshotsAsync.whenData((snapshots) {
    if (snapshots.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Net Worth History',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Text(
                        'History view not implemented yet',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  });
}

void _showDeleteAccountDialog(
  BuildContext context,
  WidgetRef ref,
  Account account,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Account'),
      content: Text(
        'Are you sure you want to delete "${account.name}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await RepositoryService.deleteAccount(account.id);
              if (context.mounted) {
                // Refresh both providers to update the UI and dashboard calculations
                await ref.read(accountsProvider.notifier).reload();
                await ref.read(liabilitiesProvider.notifier).reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${account.name} deleted successfully'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
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
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
