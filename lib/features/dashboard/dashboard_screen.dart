import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../routes.dart';
import '../../data/repositories.dart';
import 'mini_trend_chart_painter.dart';
import '../../data/models.dart';
import '../../data/snapshot_service.dart';
import '../../data/calculators/financial_health.dart';
import '../../data/calculators/allocation.dart';

import '../../app.dart';
import '../../utils/csv_exporter.dart';

// Top-level autosuggest helper so widget-building code can call it from any
// method inside the file regardless of class method ordering.
Widget _maybeBuildIntlAutosuggest(
  BuildContext context,
  Settings settings,
  List<Account> accounts,
  WidgetRef ref,
) {
  // If user already muted or set to light, don't suggest
  if (settings.globalDiversificationMode == 'off' ||
      settings.globalDiversificationMode == 'light') {
    return const SizedBox.shrink();
  }

  final totals = AllocationCalculator.calculateTotals(accounts);
  final assetsTotal = totals.values.reduce((a, b) => a + b);
  if (assetsTotal == 0) return const SizedBox.shrink();

  final intlPct = totals['intlEq']! / assetsTotal;

  // Suggest muting when international exposure is extremely low (<1%)
  if (intlPct < 0.01) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () {
          final settingsNotifier = ref.read(settingsProvider.notifier);
          final currentSettings = ref.read(settingsProvider).value;
          if (currentSettings != null) {
            final updated = Settings(
              riskBand: currentSettings.riskBand,
              monthlyEssentials: currentSettings.monthlyEssentials,
              driftThresholdPct: currentSettings.driftThresholdPct,
              notificationsEnabled: currentSettings.notificationsEnabled,
              usEquityTargetPct: currentSettings.usEquityTargetPct,
              isPro: currentSettings.isPro,
              biometricLockEnabled: currentSettings.biometricLockEnabled,
              darkModeEnabled: currentSettings.darkModeEnabled,
              colorTheme: currentSettings.colorTheme,
              homeCountry: currentSettings.homeCountry,
              globalDiversificationMode: 'off',
              intlTolerancePct: currentSettings.intlTolerancePct,
              intlFloorPct: currentSettings.intlFloorPct,
              intlPenaltyScale: currentSettings.intlPenaltyScale,
              intlTargetOverride: currentSettings.intlTargetOverride,
            );
            settingsNotifier.updateSettings(updated);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.visibility_off,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Hide Intl from score',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  return const SizedBox.shrink();
}

// Design Token System
class DesignTokens {
  // Border radius tokens
  static const double radiusCard = 16;
  static const double radiusChip = 10;
  static const double radiusIcon = 12;

  // Spacing tokens
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;

  // Elevation tokens
  static const double elevation1 = 2; // Quick actions, reminders
  static const double elevation2 = 4; // Alert cards
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rebalance'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final accountsAsync = ref.watch(accountsProvider);

          return accountsAsync.when(
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
                    onPressed: () =>
                        ref.read(accountsProvider.notifier).reload(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return _buildEmptyState(context);
              }
              return _buildDashboard(context, ref, accounts);
            },
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);

    return CustomScrollView(
      slivers: [
        // Enhanced Net Worth Card with History
        SliverToBoxAdapter(
          child: _buildNetWorthCard(context, ref, accounts),
        ),

        // Allocation Analysis Section
        SliverToBoxAdapter(
          child: _buildAllocationSection(context, ref, accounts),
        ),

        // Set Targets CTA Banner
        SliverToBoxAdapter(
          child: _buildSetTargetsBanner(context, ref),
        ),

        // Quick Actions removed (redundant actions relocated / available elsewhere)

        // Account Summary Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Accounts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRouter.accounts),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'View all (${accounts.length})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Account List with loading and empty states
        accounts.isEmpty
            ? _buildEmptyAccountsState(context)
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= accounts.take(5).length) return null;
                    final account = accounts[index];

                    return _buildEnhancedAccountTile(
                      context,
                      account,
                      index,
                      accounts.length,
                      totalAssets,
                    );
                  },
                  childCount: accounts.take(5).length,
                ),
              ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Padding(
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
                'Welcome to Rebalance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Start building your financial future by adding your first account. Track your net worth, analyze asset allocation, and get personalized insights.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  FilledButton.icon(
                    onPressed: () => context.push(AppRouter.accounts),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Your First Account'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showOnboardingSteps(context),
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Getting Started Guide'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _showSampleDataDialog(context),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Preview with Sample Data'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getAccountTypeDisplayName(String kind) {
    switch (kind.toLowerCase()) {
      case 'checking':
        return 'Checking Account';
      case 'savings':
        return 'Savings Account';
      case 'brokerage':
        return 'Brokerage Account';
      case 'retirement':
        return '401k/IRA';
      case 'hsa':
        return 'Health Savings Account';
      case 'cd':
        return 'Certificate of Deposit';
      case 'cash':
        return 'Cash Account';
      default:
        return kind.toUpperCase();
    }
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

  // Enhanced account tile with all the improvements (restored)
  Widget _buildEnhancedAccountTile(
    BuildContext context,
    Account account,
    int index,
    int totalCount,
    double totalAssets,
  ) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 0,
    );

    final percentOfPortfolio = (account.balance / totalAssets) * 100;
    final accountColor = _getAccountKindColor(context, account.kind);
    final lastUpdated = _getLastUpdatedText(account);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Semantics(
          label:
              '${_getAccountTypeDisplayName(account.kind)}, ${account.name}, balance ${formatter.format(account.balance)}, ${percentOfPortfolio.toStringAsFixed(1)} percent of portfolio',
          hint: 'Tap to view details, long press for quick actions',
          button: true,
          child: ListTile(
            visualDensity: const VisualDensity(vertical: -1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accountColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accountColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                _getAccountIcon(account.kind),
                color: accountColor,
                size: 22,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _getEnhancedAccountName(
                      account.name,
                      account.kind,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    formatter.format(account.balance),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFeatures: [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _getAccountTypeDisplayName(account.kind),
                      style: TextStyle(
                        color: accountColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(' • ', style: TextStyle(fontSize: 10)),
                  Flexible(
                    child: Text(
                      '${percentOfPortfolio.toStringAsFixed(1)}% of portfolio',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    lastUpdated,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => context.push('${AppRouter.accounts}/${account.id}'),
            onLongPress: () => _showAccountQuickActions(context, account),
          ),
        ),
      ),
    );
  }

  // Enhanced account naming with title case consistency
  String _getEnhancedAccountName(String name, String kind) {
    // Handle common naming patterns
    if (name.toLowerCase().contains('401k')) {
      return name.replaceAll(RegExp(r'401k', caseSensitive: false), '401(k)');
    }
    if (name.toLowerCase() == 'investment account' &&
        kind.toLowerCase() == 'brokerage') {
      return 'Brokerage Account';
    }
    return name;
  }

  // Get last updated text (mock for now)
  String _getLastUpdatedText(Account account) {
    // In real app, this would check actual last sync time
    final daysAgo = (account.id.hashCode % 7) + 1; // Mock: 1-7 days ago
    if (daysAgo <= 1) return 'Updated today';
    if (daysAgo == 2) return 'Updated yesterday';
    return 'Updated ${daysAgo}d ago';
  }

  // Quick actions sheet for long press
  void _showAccountQuickActions(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              account.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildQuickActionTile(context, 'Edit Account', Icons.edit, () {
              Navigator.pop(context);
              context.push('${AppRouter.accounts}/${account.id}/edit');
            }),
            _buildQuickActionTile(
                context, 'Add Transaction', Icons.add_circle_outline, () {
              Navigator.pop(context);
              // Navigate to add transaction
            }),
            _buildQuickActionTile(context, 'Rebalance', Icons.balance, () {
              Navigator.pop(context);
              // Show rebalancing options
            }),
            _buildQuickActionTile(
              context,
              'Archive',
              Icons.archive_outlined,
              () {
                Navigator.pop(context);
                _showArchiveConfirmation(context, account);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
            isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showArchiveConfirmation(BuildContext context, Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Account'),
        content: Text(
          'Are you sure you want to archive "${account.name}"? This will hide it from your dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle archive logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${account.name} archived')),
              );
            },
            child: const Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Empty state for when no accounts exist
  Widget _buildEmptyAccountsState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first account to start tracking your financial health and get personalized insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push(AppRouter.accounts),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Account'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOnboardingSteps(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => OnboardingStepsSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showSampleDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Sample Data'),
        content: const Text(
          'This will load sample financial data to demonstrate the app features. Your existing data will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, child) => FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                await _loadSampleData(ref);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Sample data loaded!')),
                );
              },
              child: const Text('Load'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSampleData(WidgetRef ref) async {
    // Create sample accounts
    final sampleAccounts = [
      Account(
        id: 'sample_checking',
        name: 'Checking Account',
        kind: 'cash',
        balance: 5000.0,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'sample_investment',
        name: 'Investment Account',
        kind: 'brokerage',
        balance: 25000.0,
        pctCash: 0.05,
        pctBonds: 0.20,
        pctUsEq: 0.60,
        pctIntlEq: 0.15,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'sample_401k',
        name: '401k',
        kind: 'retirement',
        balance: 15000.0,
        pctCash: 0.0,
        pctBonds: 0.40,
        pctUsEq: 0.50,
        pctIntlEq: 0.10,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'sample_savings',
        name: 'Savings Account',
        kind: 'savings',
        balance: 8000.0,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    // Create sample liabilities with realistic due dates
    final now = DateTime.now();
    final sampleLiabilities = [
      Liability(
        id: 'sample_mortgage',
        name: 'Mortgage',
        kind: 'mortgage',
        balance: 200000.0,
        apr: 0.035,
        minPayment: 1200.0,
        nextPaymentDate: DateTime(now.year, now.month, 1)
            .add(const Duration(days: 32)), // 1st of next month
        paymentFrequencyDays: 30,
        dayOfMonth: 1,
        updatedAt: DateTime.now(),
      ),
      Liability(
        id: 'sample_car',
        name: 'Car Loan',
        kind: 'autoLoan',
        balance: 15000.0,
        apr: 0.042,
        minPayment: 350.0,
        nextPaymentDate: now.add(
          const Duration(days: 3),
        ), // Due in 3 days (matches your screenshot)
        paymentFrequencyDays: 30,
        dayOfMonth: 15,
        updatedAt: DateTime.now(),
      ),
      Liability(
        id: 'sample_credit',
        name: 'Credit Card',
        kind: 'creditCard',
        balance: 2500.0,
        apr: 0.189,
        minPayment: 50.0,
        creditLimit: 5000.0,
        nextPaymentDate: now.add(const Duration(days: 6)), // Due in 6 days
        paymentFrequencyDays: 30,
        dayOfMonth: 25,
        updatedAt: DateTime.now(),
      ),
      Liability(
        id: 'sample_student',
        name: 'Student Loan',
        kind: 'studentLoan',
        balance: 18500.0,
        apr: 0.045,
        minPayment: 215.0,
        nextPaymentDate: now.add(const Duration(days: 1)), // Due tomorrow
        paymentFrequencyDays: 30,
        dayOfMonth: 10,
        updatedAt: DateTime.now(),
      ),
      Liability(
        id: 'sample_personal',
        name: 'Personal Loan',
        kind: 'personalLoan',
        balance: 5000.0,
        apr: 0.125,
        minPayment: 180.0,
        nextPaymentDate:
            now.subtract(const Duration(days: 2)), // 2 days overdue
        paymentFrequencyDays: 30,
        dayOfMonth: 28,
        updatedAt: DateTime.now(),
      ),
    ];

    // Save to repositories
    for (final account in sampleAccounts) {
      await RepositoryService.saveAccount(account);
    }

    for (final liability in sampleLiabilities) {
      await RepositoryService.saveLiability(liability);
    }

    // Refresh the providers to update the UI
    ref.read(accountsProvider.notifier).reload();
    ref.read(liabilitiesProvider.notifier).reload();
  }

  Widget _buildAllocationSection(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    // Calculate allocation totals
    final allocation = _calculateAllocation(accounts);
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.pie_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Asset Allocation',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Show allocation whenever there's non-zero assets.
              // Previously this required >=2 accounts which caused the
              // allocation to remain hidden when the user added their first
              // account. Change to only hide when totalAssets == 0.
              if (totalAssets == 0)
                _buildAllocationEmptyState(context)
              else ...[
                // Side-by-side layout: Pie chart + Health score
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;

                    if (isNarrow) {
                      // Stack vertically on narrow screens
                      return Column(
                        children: [
                          // Pie chart (centered)
                          SizedBox(
                            height: 180,
                            child: _buildAllocationDonut(
                              context,
                              ref,
                              accounts,
                              allocation,
                              totalAssets,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          _buildAllocationLegend(
                            context,
                            allocation,
                            totalAssets,
                          ),
                        ],
                      );
                    } else {
                      // Side-by-side on wider screens
                      return Column(
                        children: [
                          // Pie chart (centered, full width)
                          SizedBox(
                            height: 180,
                            child: _buildAllocationDonut(
                              context,
                              ref,
                              accounts,
                              allocation,
                              totalAssets,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legend spans full width below
                          _buildAllocationLegend(
                            context,
                            allocation,
                            totalAssets,
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 20),

                // View Full Analysis button (replaces previous quick actions entry point)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('View Full Analysis'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () => context.push(AppRouter.reports),
                  ),
                ),

                const SizedBox(height: 12),
                // Autosuggest: Offer to mute Home Bias when Intl exposure is extremely low
                Builder(builder: (ctx) {
                  final settings = ref.watch(settingsProvider).value;
                  if (settings == null) return const SizedBox.shrink();
                  return _maybeBuildIntlAutosuggest(
                      context, settings, accounts, ref,);
                },),

                const SizedBox(height: 16),

                // Promoted action card (retained)
                _buildTopActionCard(context, ref, accounts),
              ],

              // Due-soon nudge for debts
              _buildDueSoonNudge(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, double> _calculateAllocation(List<Account> accounts) {
    final allocation = {
      'Cash': 0.0,
      'Bonds': 0.0,
      'US Equity': 0.0,
      'Intl Equity': 0.0,
      'Real Estate': 0.0,
      'Alternative': 0.0,
    };

    for (final account in accounts) {
      final breakdown = account.allocationBreakdown;
      allocation['Cash'] = allocation['Cash']! + breakdown['cash']!;
      allocation['Bonds'] = allocation['Bonds']! + breakdown['bonds']!;
      allocation['US Equity'] = allocation['US Equity']! + breakdown['usEq']!;
      allocation['Intl Equity'] =
          allocation['Intl Equity']! + breakdown['intlEq']!;
      allocation['Real Estate'] =
          allocation['Real Estate']! + breakdown['realEstate']!;
      allocation['Alternative'] =
          allocation['Alternative']! + breakdown['alt']!;
    }

    return allocation;
  }

  Widget _buildAllocationEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No assets yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add an account to see your allocation breakdown.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationLegend(
    BuildContext context,
    Map<String, double> allocation,
    double totalAssets,
  ) {
    final entries = allocation.entries.toList();
    return Column(
      children: entries.map((e) {
        final percent = totalAssets > 0 ? (e.value / totalAssets) * 100 : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: Text(
                  e.key,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllocationDonut(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
    Map<String, double> allocation,
    double totalAssets,
  ) {
    if (totalAssets == 0) {
      return Center(
        child: Text(
          'No data',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    int colorIndex = 0;
    allocation.forEach((key, value) {
      if (value > 0) {
        final percentage = (value / totalAssets) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: value,
            // Use one decimal to match the legend formatting
            title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 30,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    });

    return Stack(
      children: [
        PieChart(
          PieChartData(
            sections: sections,
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            startDegreeOffset: -90,
          ),
        ),
        // Center with Total Equities percentage
        Positioned.fill(
          child: Center(
            child: _buildEquitiesCenter(context, allocation, totalAssets),
          ),
        ),
      ],
    );
  }

  Widget _buildEquitiesCenter(
    BuildContext context,
    Map<String, double> allocation,
    double totalAssets,
  ) {
    if (totalAssets == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No data',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // Calculate total equities percentage
    final usEquity = allocation['US Equity'] ?? 0.0;
    final intlEquity = allocation['Intl Equity'] ?? 0.0;
    final totalEquities = usEquity + intlEquity;
    final equitiesPercentage = (totalEquities / totalAssets) * 100;

    // Example target - in real app, get from settings
    const targetEquitiesPercentage = 60.0;
    final hasTarget = equitiesPercentage > 0;
    final delta = equitiesPercentage - targetEquitiesPercentage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large percentage with two-line label as requested
        Text(
          '${equitiesPercentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28, // Slightly larger
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Total Equities',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (hasTarget) ...[
          const SizedBox(height: 2),
          Text(
            'vs target ${targetEquitiesPercentage.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: delta.abs() <= 5
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopActionCard(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    // Check Pro status
    final settingsAsync = ref.watch(settingsProvider);
    final isPro = settingsAsync.value?.isPro ?? false;

    // Calculate concentration risk
    final allocation = _calculateAllocation(accounts);
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);

    if (totalAssets == 0) return const SizedBox();

    // Find largest bucket
    String largestBucket = '';
    double largestPercentage = 0.0;
    allocation.forEach((key, value) {
      final percentage = (value / totalAssets) * 100;
      if (percentage > largestPercentage) {
        largestPercentage = percentage;
        largestBucket = key;
      }
    });

    // Check if concentration risk exists
    final hasConcentrationRisk = largestPercentage > 20;

    if (!hasConcentrationRisk) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portfolio Balanced',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your allocation looks good! Keep monitoring for drift.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calculate rebalancing suggestions
    final shortfall = largestPercentage - 20.0;
    final amountToMove = (shortfall / 100) * totalAssets;
    final movePerMonth = (amountToMove / 6).ceil(); // 6-month glide

    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return RiskNudgeCard(
      title: 'Reduce concentration risk',
      diagnosis:
          'Largest bucket $largestBucket (${largestPercentage.toStringAsFixed(1)}%). Cap ≤20% per bucket.',
      action:
          'Shift ${formatter.format(movePerMonth)}/mo for ~6 months to Bonds/Intl.',
      ctaText: 'Create Rebalancing Plan',
      severityColor: Colors.amber,
      showPro: !isPro,
      personalizationChips: [
        '$largestBucket ${largestPercentage.toStringAsFixed(1)}%',
        'Cap 20%',
        'Target shift ${formatter.format(amountToMove.round())}',
      ],
      detectedAt: DateTime.now()
          .subtract(const Duration(hours: 2)), // Simulated: spotted 2h ago
      onChipTap: (chipLabel) {
        // Show a small contextual details sheet for the tapped chip
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          builder: (sheetCtx) {
            Widget content;

            if (chipLabel.startsWith('US Equity')) {
              content = Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'US Equity Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shows your US equity exposure across accounts. Consider diversifying into International and Bonds to reduce concentration risk.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.push(AppRouter.accounts);
                      },
                      child: const Text('View accounts with US Equity'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            } else if (chipLabel.startsWith('Cap')) {
              content = Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cap Explanation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A cap limits the maximum percentage of your portfolio in any single bucket to reduce single-market volatility.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                      },
                      child: const Text('Got it'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            } else if (chipLabel.startsWith('Target shift')) {
              content = Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Shift',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This suggests how much to move to reach the recommended cap over a 6-month glide path.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        context.push(AppRouter.rebalancing);
                      },
                      child: const Text('Create Rebalancing Plan'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            } else {
              content = Padding(
                padding: const EdgeInsets.all(16),
                child: Text(chipLabel),
              );
            }

            return SafeArea(child: content);
          },
        );
      },
      onCTA: () => context.push(AppRouter.rebalancing),
      onWhy: () {
        // Capture the parent context to avoid shadowing inside the dialog builder
        final parentContext = context;
        showDialog(
          context: parentContext,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(width: 8),
                Text('Why Rebalance?'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caps reduce single-bucket volatility',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                Text(
                  'Spreading your investments across different asset classes reduces concentration risk and helps protect your portfolio from volatility in any single market.',
                ),
                SizedBox(height: 12),
                Text(
                  'Moving excess into Bonds and International equity creates better diversification.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Got it'),
              ),
              TextButton(
                onPressed: () {
                  // Close the dialog first
                  Navigator.pop(dialogContext);
                  // Navigate to the rebalancing screen after the dialog closes.
                  // Use a microtask to ensure navigation happens after pop completes.
                  Future.microtask(
                    () => parentContext.push(AppRouter.rebalancing),
                  );
                },
                child: const Text('Learn more'),
              ),
            ],
          ),
        );
      },
      onSnooze: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risk nudge snoozed for 30 days'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onDismiss: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risk marked as resolved'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildQuickAddFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () => _openLastUsedAction(context),
        child: FloatingActionButton(
          onPressed: () => _showQuickAddSpeedDial(context),
          tooltip: 'Quick Add • Long press for last action',
          elevation: 0, // Remove default elevation since we have custom shadow
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _openLastUsedAction(BuildContext context) {
    // Show first-time tooltip if it's their first long press
    _showFirstTimeFABTooltip(context);

    // For demo purposes, assume the last used action was "Add Account"
    // In a real app, you'd store this in SharedPreferences or similar
    const lastAction = 'account'; // Could be 'account', 'liability', etc.

    switch (lastAction) {
      case 'account':
        context.push('${AppRouter.accounts}/add');
        break;
      case 'liability':
        context.push('${AppRouter.liabilities}/add');
        break;
      default:
        _showQuickAddSpeedDial(context);
    }
  }

  void _showFirstTimeFABTooltip(BuildContext context) {
    // In a real app, you'd check SharedPreferences to see if this is first time
    // For demo, we'll show it every time
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.tips_and_updates_outlined,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tip: Long-press the + button anytime to repeat your last action',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          bottom: 100,
          left: 16,
          right: 16,
        ), // Keep above FAB
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showQuickAddSpeedDial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Quick Add',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildQuickAddOption(
                    context,
                    'Account',
                    Icons.account_balance_wallet_outlined,
                    Theme.of(context).colorScheme.primary,
                    () {
                      Navigator.pop(context);
                      context.push(AppRouter.accounts);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAddOption(
                    context,
                    'Liability',
                    Icons.credit_card_outlined,
                    Theme.of(context).colorScheme.error,
                    () {
                      Navigator.pop(context);
                      context.push(AppRouter.liabilities);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueSoonNudge(BuildContext context, WidgetRef ref) {
    // Placeholder nudge area — keep minimal to avoid layout issues.
    // The full nudge implementation lives elsewhere; this keeps the
    // dashboard stable while we display the detailed score sheet.
    return const SizedBox.shrink();
  }

  Widget _buildNetWorthCard(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    // Calculate net worth
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Auto-create snapshot if it's been more than 24 hours
    _maybeCreateSnapshot(ref);

    // Get last snapshot for delta calculation
    final snapshotsAsync = ref.watch(snapshotsProvider);

    return snapshotsAsync.when(
      loading: () => _buildNetWorthCardLoading(
        context,
        totalAssets,
        accounts.length,
        formatter,
      ),
      error: (error, stack) => _buildNetWorthCardLoading(
        context,
        totalAssets,
        accounts.length,
        formatter,
      ),
      data: (snapshots) {
        return _buildNetWorthCardWithData(
          context,
          totalAssets,
          accounts.length,
          formatter,
          snapshots,
        );
      },
    );
  }

  Widget _buildNetWorthCardLoading(
    BuildContext context,
    double totalAssets,
    int accountCount,
    NumberFormat formatter,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showNetWorthHistory(context),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    // Health loading indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Health',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Net Worth',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(totalAssets),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push(AppRouter.accounts),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$accountCount accounts',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Updated ${DateFormat('MMM d').format(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthCardWithData(
    BuildContext context,
    double totalAssets,
    int accountCount,
    NumberFormat formatter,
    List<Snapshot> snapshots,
  ) {
    // Calculate 30-day delta
    double deltaAmount = 0.0;
    String deltaText = '';

    if (snapshots.isNotEmpty) {
      // Find snapshot from ~30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldSnapshot =
          snapshots.where((s) => s.at.isBefore(thirtyDaysAgo)).lastOrNull;

      if (oldSnapshot != null) {
        deltaAmount = totalAssets - oldSnapshot.netWorth;
        final isPositive = deltaAmount >= 0;
        deltaText =
            '${isPositive ? '+' : ''}${formatter.format(deltaAmount)} (30d)';
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showNetWorthHistory(context, snapshots),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    // Financial Health Score integrated here
                    _buildIntegratedHealthScore(context),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Net Worth',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(totalAssets),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                if (deltaText.isNotEmpty)
                  Row(
                    children: [
                      Text(
                        deltaAmount >= 0 ? '▲' : '▼',
                        style: TextStyle(
                          color: deltaAmount >= 0
                              ? Colors.lightGreenAccent
                              : Colors.red.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        deltaText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Tiny sparkline to the right
                      if (snapshots.length > 1)
                        SizedBox(
                          width: 60,
                          height: 20,
                          child: _buildTinySparkline(context, snapshots),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push(AppRouter.accounts),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$accountCount accounts',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Updated ${DateFormat('MMM d').format(DateTime.now())}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntegratedHealthScore(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final accountsAsync = ref.watch(accountsProvider);
        final liabilitiesAsync = ref.watch(liabilitiesProvider);
        final settingsAsync = ref.watch(settingsProvider);

        return accountsAsync.when(
          loading: () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Health',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠️',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ),
          data: (accounts) => liabilitiesAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Health',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
            data: (liabilities) => settingsAsync.when(
              loading: () => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Health',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              error: (error, stack) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
              data: (settings) {
                final healthResult =
                    FinancialHealthCalculator.calculateOverallHealth(
                  accounts,
                  liabilities,
                  settings,
                );

                return _buildEnhancedDashboardPill(
                  context,
                  healthResult,
                  accounts,
                  liabilities,
                  settings,
                  ref,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedDashboardPill(
    BuildContext context,
    FinancialHealthResult healthResult,
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
    WidgetRef ref,
  ) {
    // Check if we have sufficient data for calculation
    final hasValidData =
        accounts.isNotEmpty && accounts.any((account) => account.balance > 0);

    if (!hasValidData) {
      return _buildEmptyHealthPill(context);
    }

    final severityColor =
        _getSeverityColorForHealth(healthResult.grade, healthResult.score);

    // Enhanced timeframe and delta calculation based on data availability
    final timeframeData = _calculateTimeframeAndDelta(healthResult, accounts);
    final scoreDelta = timeframeData['delta'] as int;
    final timeframe = timeframeData['timeframe'] as String;
    // final confidence = timeframeData['confidence'] as double; // For future use

    return GestureDetector(
      onTap: () {
        debugPrint('Dashboard: health pill tapped - showing dialog');
        // Show a small dialog with two clear choices: Trend or Financial score.
        showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('View'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: const Text('Trend'),
                  onTap: () {
                    debugPrint('Dashboard: dialog -> Trend selected');
                    Navigator.of(dialogCtx).pop();
                    // Show the trend view
                    _showHealthTrendMiniChart(context, healthResult);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Financial score'),
                  onTap: () {
                    debugPrint('Dashboard: dialog -> Financial score selected');
                    Navigator.of(dialogCtx).pop();
                    // Show the score/details view
                    _showEnhancedHealthDetailsSheet(
                      context,
                      healthResult,
                      accounts,
                      liabilities,
                      settings,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: 'Tap to choose: Trend or Financial score',
        waitDuration: const Duration(milliseconds: 800),
        preferBelow: false,
        child: Semantics(
          label:
              'Overall financial health score ${healthResult.grade.name}, ${healthResult.score}. ${scoreDelta != 0 ? '${scoreDelta > 0 ? "Increased" : "Decreased"} by ${scoreDelta.abs()} points over $timeframe.' : ''} ${_getStatusLabel(healthResult.score)}. ${_getOverallHealthSubtitle(healthResult)}.',
          hint: 'Tap to view Trend or Financial score',
          button: true,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 56, // Increased from 48 to 56 for better touch target
              minWidth: 56,
              maxWidth: 280, // Prevent overflow issues
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: severityColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Autosuggest for International Exposure mute
                Positioned(
                  right: 0,
                  top: -6,
                  child: _maybeBuildIntlAutosuggest(
                    context,
                    settings,
                    accounts,
                    ref,
                  ),
                ),
                // Main column holds the pill content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main row with hierarchy: D • 68 big, Fair smaller, trend tertiary
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Grade (D) + bullet + Score (68) - primary hierarchy
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              healthResult.grade.name,
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${healthResult.score}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Status label (Fair) - secondary hierarchy
                        Text(
                          _getStatusLabel(healthResult.score),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                        ),
                        // Delta trend - tertiary hierarchy with dimmed timeframe
                        if (scoreDelta != 0) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Icon(
                                scoreDelta > 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 12,
                                color: scoreDelta > 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${scoreDelta > 0 ? '+' : ''}$scoreDelta',
                                style: TextStyle(
                                  color: scoreDelta > 0
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '($timeframe)',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Diversification caption + main driver (simplified secondary info)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Overall',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.5),
                            fontSize: 9,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _getOverallHealthSubtitle(
                              healthResult,
                            ), // Weakest: Debt Load 41/100
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Small chevron in the top-right to indicate the pill is tappable
                Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: severityColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHealthPill(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEmptyHealthStateActions(context),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '—',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.more_horiz,
                  size: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Health',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeltaChipWithSparkline(
    int scoreDelta,
    String timeframe,
    FinancialHealthResult healthResult,
  ) {
    final isPositive = scoreDelta > 0;
    final isNeutral = scoreDelta == 0;

    if (isNeutral) return const SizedBox.shrink();

    // Explicit delta colors - green for positive, red for negative
    final deltaColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final deltaArrow = isPositive ? '▲' : '▼';
    final deltaSign = isPositive ? '+' : '';

    // Format timeframe to abbreviated form
    final shortTimeframe = _formatTimeframeShort(timeframe);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ), // Increased padding
      decoration: BoxDecoration(
        color: deltaColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: deltaColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Stack(
        children: [
          // Fade 40% mini-sparkline background
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(
                painter: MiniSparklinePainter(
                  scores:
                      _generateMockTrendPoints(healthResult.score, scoreDelta),
                  color: deltaColor.withValues(alpha: 0.4),
                  strokeWidth: 1.2,
                ),
              ),
            ),
          ),
          // Delta text content - compact with overflow handling
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$deltaArrow$deltaSign$scoreDelta',
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 11, // Keep consistent with updated size
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 3), // Slightly more space
              Text(
                '($shortTimeframe)',
                style: TextStyle(
                  color: deltaColor.withValues(alpha: 0.8),
                  fontSize: 9, // Keep consistent with updated size
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeframeShort(String timeframe) {
    // Convert timeframes to shorter versions for the delta chip
    switch (timeframe.toLowerCase()) {
      case '30 days':
      case '30d':
        return '30d';
      case '7 days':
      case '7d':
        return '7d';
      case '90 days':
      case '90d':
        return '90d';
      case '3 months':
      case '3m':
        return '3m';
      case '6 months':
      case '6m':
        return '6m';
      case '1 year':
      case '1y':
        return '1y';
      default:
        return timeframe.length > 4 ? timeframe.substring(0, 4) : timeframe;
    }
  }

  String _getStatusLabel(int score) {
    // Align status labels with grade bands for consistency
    if (score >= 90) return 'Excellent'; // A grade: 90-100
    if (score >= 80) return 'Good'; // B grade: 80-89
    if (score >= 70) return 'Fair'; // C grade: 70-79
    if (score >= 60) {
      return 'Needs work'; // D grade: 60-69 (consistent with "Needs Attention")
    }
    return 'Poor'; // F grade: 0-59
  }

  // Removed: _getStatusLabelColor (unused)

  // Enhanced grade badge with tonal grade color and consistent styling
  Widget _buildEnhancedGradeBadge(HealthGrade grade, Color severityColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.12), // Tonal grade color
        borderRadius: BorderRadius.circular(12), // Match other chip radii
        border: Border.all(
          color: severityColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        grade.name,
        style: TextStyle(
          color: severityColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  // Quieter delta chip with outline style and clear timeframe
  Widget _buildQuieterDeltaChip(
    int scoreDelta,
    String timeframe,
    FinancialHealthResult healthResult,
  ) {
    final isPositive = scoreDelta > 0;
    final deltaColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final deltaArrow = isPositive ? '▲' : '▼';
    final deltaSign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent, // Quieter - no background fill
        borderRadius: BorderRadius.circular(12), // Match other chip radii
        border: Border.all(
          color: deltaColor.withValues(alpha: 0.3), // Outline style
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Subtle sparkline background (quieter than the filled version)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: MiniSparklinePainter(
                  scores: _generateMockTrendPoints(
                    healthResult.score,
                    scoreDelta,
                  ), // Use actual score
                  color: deltaColor.withValues(
                    alpha: 0.25,
                  ), // More visible but still subtle
                  strokeWidth: 1.0,
                ),
              ),
            ),
          ),
          // Delta text content
          Text(
            '$deltaArrow $deltaSign$scoreDelta (${_formatTimeframeShort(timeframe)})',
            style: TextStyle(
              color: deltaColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  // Get main driver text for actionable info
  String _getMainDriverText(List<Account> accounts) {
    if (accounts.isEmpty) return 'Add accounts for analysis';

    // Calculate asset allocation to find largest bucket
    final totalAssets = accounts
        .where((account) => account.balance > 0)
        .fold(0.0, (sum, account) => sum + account.balance);

    if (totalAssets == 0) return 'Add account balances';

    // Group by asset class and find largest
    final Map<String, double> allocationMap = {};
    for (final account in accounts.where((a) => a.balance > 0)) {
      final assetClass = _getAssetClass(account.kind);
      allocationMap[assetClass] =
          (allocationMap[assetClass] ?? 0) + account.balance;
    }

    if (allocationMap.isEmpty) return 'Balanced allocation';

    final largestEntry =
        allocationMap.entries.reduce((a, b) => a.value > b.value ? a : b);
    final percentage = (largestEntry.value / totalAssets * 100);

    if (percentage > 20) {
      return '${largestEntry.key} ${percentage.toStringAsFixed(1)}% (cap 20%)';
    } else {
      return 'Well balanced';
    }
  }

  // Map account types to asset classes for main driver text
  String _getAssetClass(String accountKind) {
    switch (accountKind.toLowerCase()) {
      case 'checking':
      case 'savings':
        return 'Cash';
      case 'brokerage':
        return 'US Equity'; // Simplified - in real app would analyze holdings
      case 'retirement':
        return 'US Equity'; // Simplified - in real app would analyze 401k allocation
      case 'ira':
        return 'US Equity'; // Simplified
      default:
        return 'US Equity'; // Default assumption
    }
  }

  String _getOverallHealthSubtitle(FinancialHealthResult healthResult) {
    if (healthResult.componentScores.isEmpty) {
      return 'Health calculated from 5 components';
    }

    // Find the weakest component
    final weakestEntry = healthResult.componentScores.entries
        .reduce((a, b) => a.value < b.value ? a : b);

    return 'Weakest: ${weakestEntry.key} ${weakestEntry.value}/100';
  }

  Widget _buildGradeBadge(
    FinancialHealthResult healthResult,
    Color severityColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Increased padding
      decoration: BoxDecoration(
        color: severityColor.withValues(
          alpha: 0.06,
        ), // Very light band color (5-8% opacity)
        borderRadius: BorderRadius.circular(8), // Increased border radius
        border: Border.all(
          color: severityColor.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            healthResult.grade.name,
            style: TextStyle(
              color: severityColor,
              fontSize: 16, // Increased from 14
              fontWeight: FontWeight.bold,
              letterSpacing: -0.1,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ], // Tabular figures
            ),
          ),
          Text(
            ' • ',
            style: TextStyle(
              color: severityColor.withValues(alpha: 0.6),
              fontSize: 14, // Increased from 12
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${healthResult.score}',
            style: TextStyle(
              color: severityColor,
              fontSize: 15, // Increased from 13
              fontWeight: FontWeight.w600,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ], // Tabular figures
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaChip(int scoreDelta, String timeframe) {
    final deltaColor = scoreDelta > 0
        ? Colors.green.shade600
        : scoreDelta < 0
            ? Colors.red.shade600
            : Colors.grey.shade600;

    final deltaArrow = scoreDelta > 0
        ? '▲'
        : scoreDelta < 0
            ? '▼'
            : '';
    final deltaSign = scoreDelta > 0 ? '+' : '';
    final shortTimeframe = _formatTimeframeShort(timeframe);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ), // Increased padding
      decoration: BoxDecoration(
        color: deltaColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8), // Increased border radius
        border: Border.all(
          color: deltaColor.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$deltaArrow$deltaSign$scoreDelta', // Removed space to be more compact
            style: TextStyle(
              color: deltaColor,
              fontSize: 11, // Increased from 10
              fontWeight: FontWeight.bold,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ], // Tabular figures
            ),
          ),
          const SizedBox(width: 2), // Added small spacing
          Text(
            '($shortTimeframe)',
            style: TextStyle(
              color: deltaColor.withValues(alpha: 0.8),
              fontSize: 9, // Increased from 8
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeChip(String timeframe, BuildContext context) {
    final shortTimeframe = _formatTimeframeShort(timeframe);

    return GestureDetector(
      onTap: () => _cycleTimeframe(context), // Cycle 7d / 30d / 90d / 1y
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ), // Increased padding
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8), // Increased border radius
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Text(
          shortTimeframe, // No trailing dot
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10, // Increased from 9
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _cycleTimeframe(BuildContext context) {
    // TODO: Implement timeframe cycling logic
    // This would cycle through 7d / 30d / 90d / 1y and update the state
  }

  List<double> _generateMockTrendPoints(int currentScore, int scoreDelta) {
    // Generate simple trend points for sparkline based on current score and delta
    final startScore = currentScore - scoreDelta;
    final points = <double>[];

    // Create 6 points showing the trend from start to current
    for (int i = 0; i < 6; i++) {
      final progress = i / 5.0;
      final interpolated = startScore + (scoreDelta * progress);
      // Add slight variation to make it look more realistic
      final variation = (i % 2 == 0 ? 0.5 : -0.5) * (scoreDelta.abs() * 0.1);
      points.add((interpolated + variation).clamp(0.0, 100.0));
    }

    return points;
  }

  Color _getSeverityColorForHealth(HealthGrade grade, int score) {
    // Enhanced severity-based colors that reflect urgency and action needed
    switch (grade) {
      case HealthGrade.A:
        // Excellent health - calm, positive green
        return score >= 90
            ? Colors.green.shade700 // Outstanding performance
            : Colors.green.shade600; // Strong performance
      case HealthGrade.B:
        // Good health - encouraging green-blue
        return score >= 80
            ? Colors.lightGreen.shade600 // Upper B range
            : Colors.lightGreen.shade700; // Lower B range
      case HealthGrade.C:
        // Fair health - cautionary yellow-orange
        return score >= 70
            ? Colors.amber.shade600 // Upper C range - still okay
            : Colors.orange.shade600; // Lower C range - getting concerning
      case HealthGrade.D:
        // Needs attention - urgent orange-red
        return score >= 60
            ? Colors.orange.shade700 // Upper D range - action needed soon
            : Colors
                .deepOrange.shade600; // Lower D range - urgent action needed
      case HealthGrade.F:
        // Critical - immediate action required
        if (score < 20) {
          return Colors.red.shade800; // Crisis level - immediate intervention
        } else if (score < 40) {
          return Colors.red.shade700; // Severe issues - urgent action
        } else {
          return Colors.red.shade600; // Poor but recoverable
        }
    }
  }

  void _showEnhancedHealthDetailsSheet(
    BuildContext context,
    FinancialHealthResult healthResult,
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
  ) {
    // For now, use the existing enhanced score details sheet
    _showEnhancedScoreDetailsSheet(
      context,
      healthResult,
      accounts,
      liabilities,
      settings,
    );
  }

  void _showHealthTrendMiniChart(
    BuildContext context,
    FinancialHealthResult healthResult,
  ) {
    // For now, use the existing trend mini chart
    _showTrendMiniChart(context, healthResult);
  }

  void _showEmptyHealthStateActions(BuildContext context) {
    // For now, use the existing empty state actions
    _showEmptyStateActions(context);
  }

  Color _getConfidenceColor(String timeframe) {
    // Confidence indicator colors based on data availability
    switch (timeframe) {
      case '90d':
        return Colors.green.shade600; // High confidence - lots of data
      case '30d':
        return Colors.orange.shade600; // Medium confidence - some data
      case '7d':
      default:
        return Colors.grey.shade400; // Lower confidence - limited data
    }
  }

  Map<String, dynamic> _calculateTimeframeAndDelta(
    FinancialHealthResult healthResult,
    List<Account> accounts,
  ) {
    // In a real app, this would analyze historical data to determine:
    // 1. How far back we have reliable data
    // 2. What the score was at that time
    // 3. Confidence level based on data completeness

    // Mock implementation with realistic logic
    final totalBalance = accounts.fold<double>(
      0.0,
      (sum, account) => sum + account.balance,
    );

    // Determine timeframe based on data richness
    String timeframe;
    int mockPreviousScore;
    double confidence;

    if (totalBalance > 100000) {
      // Wealthy users likely have more historical data
      timeframe = '90d';
      mockPreviousScore = healthResult.score - 5; // Larger historical change
      confidence = 0.9;
    } else if (totalBalance > 10000) {
      // Mid-tier users have moderate historical data
      timeframe = '30d';
      mockPreviousScore = healthResult.score - 3;
      confidence = 0.75;
    } else {
      // New users have limited historical data
      timeframe = '7d';
      mockPreviousScore = healthResult.score - 1;
      confidence = 0.6;
    }

    // Add some variability based on score
    if (healthResult.score >= 80) {
      // High scores tend to be more stable
      mockPreviousScore = healthResult.score - 1;
    } else if (healthResult.score <= 40) {
      // Low scores might be more volatile
      mockPreviousScore = healthResult.score + 2;
    }

    final delta = healthResult.score - mockPreviousScore;

    return {
      'delta': delta,
      'timeframe': timeframe,
      'confidence': confidence,
    };
  }

  Widget _buildEnhancedTrendIndicator(
    BuildContext context,
    int scoreDelta,
    String timeframe,
    Color baseColor,
  ) {
    if (scoreDelta == 0) return const SizedBox.shrink();

    final isPositive = scoreDelta > 0;
    final trendColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trendColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: trendColor,
          ),
          const SizedBox(width: 2),
          Text(
            '${scoreDelta.abs()} in $timeframe',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasIncompleteData(List<Account> accounts, Settings settings) {
    // Check if we're missing essential data for accurate scoring
    return settings.monthlyEssentials <= 0 ||
        accounts.isEmpty ||
        accounts.every((account) => account.balance <= 0);
  }

  void _showScoreTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How We Calculate This'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your financial health score is based on:'),
            SizedBox(height: 12),
            Text('• Concentration Risk (30%)'),
            Text('• Fixed Income Balance (25%)'),
            Text('• Liquidity Buffer (20%)'),
            Text('• International Exposure (15%)'),
            Text('• Debt Management (10%)'),
            SizedBox(height: 12),
            Text(
              'Scores range from 0-100 with letter grades A through F.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showEmptyStateActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Icon(
              Icons.compass_calibration_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),

            Text(
              'Get Your Financial Health Score',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            Text(
              'Add accounts and set monthly expenses to see how balanced your portfolio is.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRouter.accounts);
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Add Accounts'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRouter.targets);
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Add Monthly Essentials'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTrendMiniChart(
    BuildContext context,
    FinancialHealthResult healthResult,
  ) {
    // Enhanced mock trend data with realistic patterns
    final trendData = _generateRealisticTrendData(healthResult);
    final overallTrend = _calculateOverallTrend(trendData);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Financial Health Trend',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Current score badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColorForHealth(
                            healthResult.grade,
                            healthResult.score,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getSeverityColorForHealth(
                              healthResult.grade,
                              healthResult.score,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${healthResult.score}',
                              style: TextStyle(
                                color: _getSeverityColorForHealth(
                                  healthResult.grade,
                                  healthResult.score,
                                ),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${healthResult.grade.name} • ${_getGradeText(healthResult.grade)}',
                              style: TextStyle(
                                color: _getSeverityColorForHealth(
                                  healthResult.grade,
                                  healthResult.score,
                                ),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: overallTrend['color'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              overallTrend['icon'],
                              size: 12,
                              color: overallTrend['color'],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              overallTrend['text'],
                              style: TextStyle(
                                color: overallTrend['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

            // Mini chart visualization
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildMiniTrendChart(context, trendData, healthResult),
                ),
              ),
            ),

            // Insights footer
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...overallTrend['insights']
                      .map<Widget>(
                        (insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  insight,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateRealisticTrendData(
    FinancialHealthResult healthResult,
  ) {
    final now = DateTime.now();
    final currentScore = healthResult.score;
    final random =
        DateTime.now().millisecondsSinceEpoch % 100; // Semi-random seed

    // Generate 6 months of realistic data
    final data = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final date = now.subtract(Duration(days: 30 * i));
      int score;

      if (i == 0) {
        // Current score
        score = currentScore;
      } else {
        // Generate realistic historical scores with some trend
        final distanceFromCurrent = i.toDouble();
        final baseVariation = (random + i * 7) % 20 - 10; // -10 to +10
        final trendComponent =
            distanceFromCurrent * -1.5; // Slight improvement trend

        score = (currentScore + baseVariation + trendComponent)
            .round()
            .clamp(0, 100);
      }

      data.add({
        'date': date,
        'score': score,
        'month': _getMonthAbbr(date.month),
      });
    }

    return data;
  }

  String _getMonthAbbr(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  Map<String, dynamic> _calculateOverallTrend(
    List<Map<String, dynamic>> trendData,
  ) {
    if (trendData.length < 2) {
      return {
        'text': 'No trend',
        'color': Colors.grey,
        'icon': Icons.remove,
        'insights': ['Insufficient data for trend analysis'],
      };
    }

    final firstScore = trendData.first['score'] as int;
    final lastScore = trendData.last['score'] as int;
    final delta = lastScore - firstScore;
    final percentChange = ((delta / firstScore) * 100).round();

    // Calculate volatility
    var totalVariation = 0;
    for (int i = 1; i < trendData.length; i++) {
      final prevScore = trendData[i - 1]['score'] as int;
      final currentScore = trendData[i]['score'] as int;
      totalVariation += (currentScore - prevScore).abs();
    }
    final avgVolatility = totalVariation / (trendData.length - 1);

    // Determine trend characteristics
    Color trendColor;
    IconData trendIcon;
    String trendText;
    List<String> insights;

    if (delta >= 5) {
      trendColor = Colors.green.shade600;
      trendIcon = Icons.trending_up;
      trendText = '+$delta pts ($percentChange%)';
      insights = [
        'Strong upward trend over 6 months',
        if (avgVolatility < 3) 'Consistent improvement pattern',
        if (lastScore >= 70) 'Approaching excellent financial health',
      ];
    } else if (delta >= 2) {
      trendColor = Colors.lightGreen.shade600;
      trendIcon = Icons.keyboard_arrow_up;
      trendText = '+$delta pts ($percentChange%)';
      insights = [
        'Gradual improvement trend',
        if (avgVolatility < 4) 'Steady progress pattern',
      ];
    } else if (delta <= -5) {
      trendColor = Colors.red.shade600;
      trendIcon = Icons.trending_down;
      trendText = '$delta pts ($percentChange%)';
      insights = [
        'Declining trend needs attention',
        if (avgVolatility > 5) 'High volatility in scores',
        'Consider reviewing financial strategy',
      ];
    } else if (delta <= -2) {
      trendColor = Colors.orange.shade600;
      trendIcon = Icons.keyboard_arrow_down;
      trendText = '$delta pts ($percentChange%)';
      insights = [
        'Slight downward trend',
        'Monitor for continued decline',
      ];
    } else {
      trendColor = Colors.blue.shade600;
      trendIcon = Icons.horizontal_rule;
      trendText = 'Stable (${delta}pts)';
      insights = [
        'Stable financial health score',
        if (avgVolatility < 2) 'Low volatility indicates consistency',
      ];
    }

    return {
      'text': trendText,
      'color': trendColor,
      'icon': trendIcon,
      'insights': insights.where((insight) => insight.isNotEmpty).toList(),
    };
  }

  Widget _buildMiniTrendChart(
    BuildContext context,
    List<Map<String, dynamic>> trendData,
    FinancialHealthResult healthResult,
  ) {
    if (trendData.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    final scores = trendData.map((d) => d['score'] as int).toList();
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final scoreRange = maxScore - minScore;

    return Column(
      children: [
        // Chart area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              final chartHeight =
                  constraints.maxHeight - 40; // Leave space for labels

              return CustomPaint(
                size: Size(chartWidth, chartHeight),
                painter: MiniTrendChartPainter(
                  trendData: trendData,
                  minScore: minScore,
                  maxScore: maxScore,
                  scoreRange: scoreRange,
                  currentColor: _getSeverityColorForHealth(
                    healthResult.grade,
                    healthResult.score,
                  ),
                ),
              );
            },
          ),
        ),

        // Month labels
        Container(
          height: 20,
          margin: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: trendData
                .map(
                  (data) => Text(
                    data['month'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _getGradeText(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return 'Excellent Health';
      case HealthGrade.B:
        return 'Good Health';
      case HealthGrade.C:
        return 'Fair Health';
      case HealthGrade.D:
        return 'Needs Attention';
      case HealthGrade.F:
        return 'Immediate Action Required';
    }
  }

  Color _getGradeColorForDiversification(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return Colors.green.shade700;
      case HealthGrade.B:
        return Colors.lightGreen.shade700;
      case HealthGrade.C:
        return Colors.orange.shade700;
      case HealthGrade.D:
        return Colors.deepOrange.shade700;
      case HealthGrade.F:
        return Colors.red.shade700;
    }
  }

  Widget _buildTrendIndicator(BuildContext context, int currentScore) {
    // Mock trend data - in real app, compare with last month's score
    final lastMonthScore =
        currentScore - 3; // Example: score improved by 3 points
    final scoreDelta = currentScore - lastMonthScore;
    final isPositive = scoreDelta > 0;
    final isNeutral = scoreDelta == 0;

    if (isNeutral) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          size: 14,
          color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
        ),
        Text(
          '${scoreDelta.abs()}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
          ),
        ),
      ],
    );
  }

  List<Color> _getScoreGradientColors(HealthGrade grade) {
    // Use grade-appropriate colors for the background gradient
    switch (grade) {
      case HealthGrade.A:
        // Excellent - green gradient
        return [
          Colors.green.shade50.withValues(alpha: .9),
          Colors.white.withValues(alpha: .95),
        ];
      case HealthGrade.B:
        // Good - light green gradient
        return [
          Colors.lightGreen.shade50.withValues(alpha: .9),
          Colors.white.withValues(alpha: .95),
        ];
      case HealthGrade.C:
        // Fair - orange gradient
        return [
          Colors.orange.shade50.withValues(alpha: .9),
          Colors.white.withValues(alpha: .95),
        ];
      case HealthGrade.D:
        // Needs Work - deep orange gradient
        return [
          Colors.deepOrange.shade50.withValues(alpha: .9),
          Colors.white.withValues(alpha: .95),
        ];
      case HealthGrade.F:
        // Poor - red gradient
        return [
          Colors.red.shade50.withValues(alpha: .9),
          Colors.white.withValues(alpha: .95),
        ];
    }
  }

  void _showScoreDetailsSheet(
    BuildContext context,
    FinancialHealthResult healthResult,
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ScoreDetailsSheet(
          scrollController: scrollController,
          healthResult: healthResult,
          accounts: accounts,
          liabilities: liabilities,
          settings: settings,
        ),
      ),
    );
  }

  void _showEnhancedScoreDetailsSheet(
    BuildContext context,
    FinancialHealthResult healthResult,
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => EnhancedScoreDetailsSheet(
          scrollController: scrollController,
          healthResult: healthResult,
          accounts: accounts,
          liabilities: liabilities,
          settings: settings,
        ),
      ),
    );
  }

  void _showScoreQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Export PDF Report'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement PDF export
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: const Text('Save as Snapshot'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement snapshot save
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Score History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement score history
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTinySparkline(BuildContext context, List<Snapshot> snapshots) {
    if (snapshots.length < 2) return const SizedBox();

    // Take last 7 data points for tiny sparkline
    final recentSnapshots = snapshots.length > 7
        ? snapshots.sublist(snapshots.length - 7)
        : snapshots;

    return CustomPaint(
      size: const Size(60, 20),
      painter: SparklinePainter(
        snapshots: recentSnapshots,
        color: Colors.white.withValues(alpha: .7),
      ),
    );
  }

  Future<void> _maybeCreateSnapshot(WidgetRef ref) async {
    try {
      final snapshots = await RepositoryService.getSnapshots();
      final now = DateTime.now();

      // Check if we need to create a new snapshot (if >24h since last one)
      if (snapshots.isEmpty || now.difference(snapshots.last.at).inHours > 24) {
        final snapshot = await SnapshotService.createCurrentSnapshot();
        await ref.read(snapshotsProvider.notifier).addSnapshot(snapshot);
      }
    } catch (e) {
      // Silently fail - don't disrupt the UI
      debugPrint('Failed to create snapshot: $e');
    }
  }

  Widget _buildSetTargetsBanner(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
      data: (settings) {
        // If settings don't exist or monthlyEssentials is 0, show the banner
        // (monthlyEssentials is required in targets setup)
        if (settings.monthlyEssentials > 0) return const SizedBox();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: InkWell(
              onTap: () => context.push(AppRouter.targets),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.gps_fixed,
                        color: Theme.of(context).colorScheme.onTertiary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Your Financial Goals',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Define your risk tolerance and goals to get personalized insights',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer
                                  .withValues(alpha: .8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNetWorthHistory(BuildContext context, [List<Snapshot>? snapshots]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => NetWorthHistorySheet(
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// Simple sparkline painter
class SparklinePainter extends CustomPainter {
  final List<Snapshot> snapshots;
  final Color color;

  SparklinePainter({required this.snapshots, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Find min/max for scaling
    final values = snapshots.map((s) => s.netWorth).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) return; // All values are the same

    // Draw the line
    for (int i = 0; i < snapshots.length; i++) {
      final x = (i / (snapshots.length - 1)) * size.width;
      final normalizedValue = (snapshots[i].netWorth - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Net Worth History Sheet Widget
class NetWorthHistorySheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const NetWorthHistorySheet({
    super.key,
    required this.scrollController,
  });

  @override
  ConsumerState<NetWorthHistorySheet> createState() =>
      _NetWorthHistorySheetState();
}

class SnapshotDiff {
  final DateTime from;
  final DateTime to;
  final List<BucketDiff> buckets;
  final double assetsFrom;
  final double assetsTo;
  final double liabilitiesFrom;
  final double liabilitiesTo;
  final double netFrom;
  final double netTo;
  final double netDelta;

  SnapshotDiff({
    required this.from,
    required this.to,
    required this.buckets,
    required this.assetsFrom,
    required this.assetsTo,
    required this.liabilitiesFrom,
    required this.liabilitiesTo,
    required this.netFrom,
    required this.netTo,
    required this.netDelta,
  });
}

class BucketDiff {
  final String name;
  final double from;
  final double to;
  final double delta;
  final double
      deltaPct; // Percentage change vs total assets from 'from' snapshot

  BucketDiff({
    required this.name,
    required this.from,
    required this.to,
    required this.delta,
    required this.deltaPct,
  });
}

class SavedComparison {
  final String id;
  final String name;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime createdAt;
  final double netFrom;
  final double netTo;
  final double netDelta;

  SavedComparison({
    required this.id,
    required this.name,
    required this.fromDate,
    required this.toDate,
    required this.createdAt,
    required this.netFrom,
    required this.netTo,
    required this.netDelta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fromDate': fromDate.millisecondsSinceEpoch,
      'toDate': toDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'netFrom': netFrom,
      'netTo': netTo,
      'netDelta': netDelta,
    };
  }

  factory SavedComparison.fromMap(Map<String, dynamic> map) {
    return SavedComparison(
      id: map['id'],
      name: map['name'],
      fromDate: DateTime.fromMillisecondsSinceEpoch(map['fromDate']),
      toDate: DateTime.fromMillisecondsSinceEpoch(map['toDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      netFrom: map['netFrom'],
      netTo: map['netTo'],
      netDelta: map['netDelta'],
    );
  }
}

class _NetWorthHistorySheetState extends ConsumerState<NetWorthHistorySheet> {
  String selectedTimeframe = '30d';
  final timeframes = ['7d', '30d', '90d', '1y', 'All'];
  bool isCompareMode = false;
  Snapshot? compareFromSnapshot;
  Snapshot? compareToSnapshot;

  // Delta calculation based on your specification
  Map<String, dynamic> calculateDelta(
    List<Snapshot> snapshots,
    int horizonDays,
  ) {
    if (snapshots.isEmpty) return {'abs': 0.0, 'pct': 0.0};

    final latest = snapshots.last;
    final cutoff = latest.at.subtract(Duration(days: horizonDays));
    final prior = snapshots.reversed.firstWhere(
      (s) => s.at.isBefore(cutoff) || s.at.isAtSameMomentAs(cutoff),
      orElse: () => snapshots.first,
    );

    final absDelta = latest.netWorth - prior.netWorth;
    final pctDelta =
        absDelta / (prior.netWorth.abs() < 1 ? 1 : prior.netWorth.abs());

    return {'abs': absDelta, 'pct': pctDelta};
  }

  int getHorizonDays(String timeframe) {
    switch (timeframe) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      case '1y':
        return 365;
      default:
        return 30;
    }
  }

  String _getDeltaTimeframe(List<Snapshot> snapshots, int currentIndex) {
    // Find the closest prior snapshot within 30 days or use the nearest prior
    final current = snapshots[currentIndex];
    final thirtyDaysAgo = current.at.subtract(const Duration(days: 30));

    // Look for closest snapshot within 30 days
    Snapshot? priorSnapshot;
    for (int i = currentIndex + 1; i < snapshots.length; i++) {
      final candidate = snapshots[i];
      if (candidate.at.isAfter(thirtyDaysAgo)) {
        priorSnapshot = candidate;
        break;
      }
    }

    // If no snapshot within 30 days, use the nearest prior
    priorSnapshot ??= (currentIndex + 1 < snapshots.length)
        ? snapshots[currentIndex + 1]
        : null;

    if (priorSnapshot == null) return '1d';

    final daysDiff = current.at.difference(priorSnapshot.at).inDays;
    if (daysDiff <= 1) return '1d';
    if (daysDiff <= 7) return '7d';
    if (daysDiff <= 30) return '30d';
    return '${daysDiff}d';
  }

  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(snapshotsProvider);

    return snapshotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (snapshots) => _buildContent(context, snapshots),
    );
  }

  Widget _buildContent(BuildContext context, List<Snapshot> snapshots) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final compactFormatter = NumberFormat.compact(locale: 'en_US');

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Worth History',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshots.length} snapshots tracked',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons row
          Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final snapshotsAsync = ref.watch(snapshotsProvider);
                  final snapshots = snapshotsAsync.maybeWhen(
                    data: (data) => data,
                    orElse: () => <Snapshot>[],
                  );
                  final hasEnoughSnapshots = snapshots.length >= 2;

                  return Tooltip(
                    message: hasEnoughSnapshots
                        ? 'Compare snapshots'
                        : 'Create another snapshot to compare',
                    child: OutlinedButton.icon(
                      onPressed: hasEnoughSnapshots
                          ? () => _showCompareDialog(context)
                          : null,
                      icon: Icon(
                        Icons.compare_arrows,
                        size: 18,
                        color: hasEnoughSnapshots
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: .4),
                      ),
                      label: const Text('Compare'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        foregroundColor: hasEnoughSnapshots
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                        side: BorderSide(
                          color: hasEnoughSnapshots
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, _) => OutlinedButton.icon(
                  onPressed: () => _createManualSnapshot(context, ref),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Create'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showSavedComparisonsDialog(context),
                icon: const Icon(Icons.bookmark, size: 18),
                label: const Text('Saved'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeframe filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: timeframes.map((timeframe) {
                final isSelected = selectedTimeframe == timeframe;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(timeframe),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedTimeframe = timeframe;
                        });
                      }
                    },
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Snapshots list
          Expanded(
            child: snapshots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No history yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Snapshots are automatically created\nwhen you update your accounts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: snapshots.length,
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[
                          snapshots.length - 1 - index]; // Reverse order
                      final isLatest = index == 0;

                      // Calculate delta for this snapshot
                      final horizonDays = selectedTimeframe == 'All'
                          ? 99999
                          : getHorizonDays(selectedTimeframe);
                      final delta = calculateDelta(
                        snapshots.take(snapshots.length - index).toList(),
                        horizonDays,
                      );
                      final deltaAbs = delta['abs'] as double;
                      final isPositive = deltaAbs >= 0;

                      // Get recent snapshots for sparkline (6-12 most recent including this one)
                      final sparklineSnapshots = snapshots
                          .take(snapshots.length - index)
                          .toList()
                          .reversed
                          .take(12)
                          .toList()
                          .reversed
                          .toList();

                      final isSelected = isCompareMode &&
                          (compareFromSnapshot == snapshot ||
                              compareToSnapshot == snapshot);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5)
                            : null,
                        child: ListTile(
                          onTap: () => isCompareMode
                              ? _handleCompareSelection(snapshot)
                              : _showSnapshotDetail(context, snapshot),
                          onLongPress: () =>
                              _showSnapshotContextMenu(context, snapshot),
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatter.format(snapshot.netWorth),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy • h:mm a')
                                          .format(snapshot.at),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    // Delta indicator under timestamp
                                    if (deltaAbs.abs() > 0.01) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${isPositive ? '▲' : '▼'} ${isPositive ? '+' : '−'}\$${compactFormatter.format(deltaAbs.abs())} (${_getDeltaTimeframe(snapshots, index)})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isPositive
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Latest or Manual badge
                                  if (isLatest)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Latest',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else if (snapshot.source == 'manual')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Manual',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: sparklineSnapshots.length > 1
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    height: 20,
                                    child: _buildTinyRowSparkline(
                                      sparklineSnapshots,
                                      isPositive,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyRowSparkline(List<Snapshot> snapshots, bool isPositive) {
    return CustomPaint(
      painter: TinySparklinePainter(
        snapshots: snapshots,
        color: isPositive ? Colors.green : Colors.red,
      ),
      size: const Size(60, 20),
    );
  }

  void _createManualSnapshot(BuildContext context, WidgetRef ref) async {
    try {
      // Create snapshot using the same service as automatic snapshots
      final snapshot = await SnapshotService.createCurrentSnapshot();

      // Add to state using ref
      await ref.read(snapshotsProvider.notifier).addSnapshot(snapshot);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Snapshot saved · ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to create snapshot: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create snapshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSnapshotDetail(BuildContext context, Snapshot snapshot) {
    // Find prior snapshot for delta calculations
    final snapshotsAsync = ref.watch(snapshotsProvider);
    final snapshots = snapshotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Snapshot>[],
    );
    final currentIndex = snapshots.indexOf(snapshot);
    final priorSnapshot = currentIndex > 0 ? snapshots[currentIndex - 1] : null;

    // Calculate totals and validation
    final assetsTotal = snapshot.assetsTotal;
    final expectedTotal = snapshot.cashTotal +
        snapshot.bondsTotal +
        snapshot.usEqTotal +
        snapshot.intlEqTotal +
        snapshot.reTotal +
        snapshot.altTotal;
    final hasMathError = (assetsTotal - expectedTotal).abs() >= 1.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Snapshot Detail'),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // As-of + source row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at)} • ${snapshot.source.substring(0, 1).toUpperCase()}${snapshot.source.substring(1)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Delta vs prior snapshot
                          Consumer(
                            builder: (context, ref, _) {
                              final snapshots = ref.watch(snapshotsProvider);
                              return snapshots.when(
                                data: (snapshotList) {
                                  final currentIndex = snapshotList
                                      .indexWhere((s) => s.at == snapshot.at);
                                  if (currentIndex < snapshotList.length - 1) {
                                    final priorSnapshot =
                                        snapshotList[currentIndex + 1];
                                    return _buildDeltaVsPrior(
                                      context,
                                      snapshot,
                                      priorSnapshot,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (snapshot.note != null && snapshot.note!.isNotEmpty)
                      IconButton(
                        onPressed: () => _showSnapshotNote(context, snapshot),
                        icon: Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'View note',
                      ),
                  ],
                ),

                // Delta vs prior snapshot
                if (priorSnapshot != null) ...[
                  const SizedBox(height: 8),
                  _buildDeltaVsPrior(context, snapshot, priorSnapshot),
                ],

                const SizedBox(height: 20),

                // Assets section
                Text(
                  'Assets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Values and % of total assets',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                _buildEnhancedAssetRow(
                  context,
                  'Cash',
                  snapshot.cashTotal,
                  assetsTotal,
                  priorSnapshot?.cashTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Bonds',
                  snapshot.bondsTotal,
                  assetsTotal,
                  priorSnapshot?.bondsTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'US Equity',
                  snapshot.usEqTotal,
                  assetsTotal,
                  priorSnapshot?.usEqTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Intl Equity',
                  snapshot.intlEqTotal,
                  assetsTotal,
                  priorSnapshot?.intlEqTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Real Estate',
                  snapshot.reTotal,
                  assetsTotal,
                  priorSnapshot?.reTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Alternatives',
                  snapshot.altTotal,
                  assetsTotal,
                  priorSnapshot?.altTotal,
                ),

                const SizedBox(height: 16),

                // Assets total with validation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Assets Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (hasMathError) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message:
                                  'Doesn\'t add up - rounding difference detected',
                              child: Icon(
                                Icons.warning_outlined,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            ).format(assetsTotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (priorSnapshot != null) ...[
                            const SizedBox(height: 2),
                            _buildDeltaText(
                              assetsTotal - priorSnapshot.assetsTotal,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liabilities section
                Text(
                  'Liabilities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                _buildEnhancedAssetRow(
                  context,
                  'Liabilities',
                  snapshot.liabilitiesTotal,
                  assetsTotal,
                  priorSnapshot?.liabilitiesTotal,
                  isLiability: true,
                ),

                const SizedBox(height: 16),

                // Net Worth total
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Worth',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            NumberFormat.currency(
                              symbol: '\$',
                              decimalDigits: 0,
                            ).format(snapshot.netWorth),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: snapshot.netWorth < 0
                                  ? Colors.red.shade700
                                  : null,
                            ),
                          ),
                          if (priorSnapshot != null) ...[
                            const SizedBox(height: 2),
                            _buildDeltaText(
                              snapshot.netWorth - priorSnapshot.netWorth,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Text(
                  'Educational info only. Not financial advice.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Export buttons
          Consumer(
            builder: (context, ref, child) {
              final snapshotsAsync = ref.watch(snapshotsProvider);
              final snapshots = snapshotsAsync.maybeWhen(
                data: (data) => data,
                orElse: () => <Snapshot>[],
              );
              final hasEnoughSnapshots = snapshots.length >= 2;

              return TextButton.icon(
                onPressed: hasEnoughSnapshots
                    ? () => _exportSnapshotCSV(context, ref, snapshot)
                    : null,
                icon: Icon(
                  Icons.download,
                  size: 16,
                  color: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
                label: Text(
                  'CSV',
                  style: TextStyle(
                    color: hasEnoughSnapshots
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: .4),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final settingsAsync = ref.watch(settingsProvider);
              final isPro = settingsAsync.value?.isPro ?? false;
              final snapshotsAsync = ref.watch(snapshotsProvider);
              final snapshots = snapshotsAsync.maybeWhen(
                data: (data) => data,
                orElse: () => <Snapshot>[],
              );
              final hasEnoughSnapshots = snapshots.length >= 2;

              return TextButton.icon(
                onPressed: hasEnoughSnapshots
                    ? (isPro
                        ? () => _exportSnapshotPDF(context, snapshot)
                        : () => _showProRequiredDialog(context, 'PDF Export'))
                    : null,
                icon: Icon(
                  Icons.picture_as_pdf,
                  size: 16,
                  color: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: .4),
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: hasEnoughSnapshots
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isPro) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: hasEnoughSnapshots
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                style: TextButton.styleFrom(
                  foregroundColor: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAssetRow(
    BuildContext context,
    String label,
    double value,
    double assetsTotal,
    double? priorValue, {
    bool isLiability = false,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Calculate percentage (vs assets, not net worth)
    final percentage = assetsTotal > 0 ? (value / assetsTotal * 100) : 0.0;
    final percentageText =
        assetsTotal > 0 ? '${percentage.toStringAsFixed(1)}%' : '—';

    // Calculate delta vs prior
    final delta = priorValue != null ? value - priorValue : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _navigateToFilteredAccounts(context, label),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter.format(isLiability ? value : value),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isLiability ? Colors.red.shade700 : null,
                        ),
                      ),
                      if (!isLiability) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $percentageText',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (delta != null && delta.abs() > 0.01) ...[
                    const SizedBox(height: 2),
                    _buildDeltaText(delta),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ...existing code...

  Widget _buildDeltaText(double delta) {
    final isPositive = delta >= 0;
    final compactFormatter = NumberFormat.compact(locale: 'en_US');

    return Text(
      '${isPositive ? '+' : '−'}\$${compactFormatter.format(delta.abs())}',
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: .7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildDeltaVsPrior(
    BuildContext context,
    Snapshot current,
    Snapshot prior,
  ) {
    // Calculate delta
    final deltaAbs = current.netWorth - prior.netWorth;
    final isPositive = deltaAbs >= 0;

    // Calculate time horizon
    final daysDiff = current.at.difference(prior.at).inDays;
    final horizon = daysDiff <= 7 ? '7d' : '30d';

    final compactFormatter = NumberFormat.compact(locale: 'en_US');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '▲ +' : '▼ '}${compactFormatter.format(deltaAbs.abs())} ($horizon)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnapshotNote(BuildContext context, Snapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snapshot Note'),
        content: Text(snapshot.note ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredAccounts(BuildContext context, String assetType) {
    // Find the current snapshot being viewed (we need to pass this info)
    // For now, we'll use a query parameter to indicate we came from a snapshot

    // Close the snapshot detail dialog first
    Navigator.pop(context);

    // Then navigate to accounts screen with asset type filter and snapshot context
    context.push(
      '/accounts?assetType=${Uri.encodeComponent(assetType)}&fromSnapshot=true',
    );
  }

  void _exportSnapshotCSV(
    BuildContext context,
    WidgetRef ref,
    Snapshot snapshot,
  ) async {
    try {
      final csvData = StringBuffer();
      final now = DateTime.now();
      final timezone = now.timeZoneName;

      csvData.writeln('# Rebalance Snapshots Export');
      csvData.writeln('# Generated: ${now.toUtc().toIso8601String()}');
      csvData.writeln('# Timezone: $timezone');
      csvData.writeln('');
      csvData.writeln(
        'timestamp,source,assets_total,liabilities_total,net_worth,cash,bonds,us_equity,intl_equity,real_estate,alternatives',
      );

      final snapshotsAsync = ref.read(snapshotsProvider);
      final snapshots = snapshotsAsync.asData?.value ?? const <Snapshot>[];
      for (final snap in snapshots.reversed) {
        csvData.writeln(
          [
            snap.at.toUtc().toIso8601String(),
            snap.source,
            snap.assetsTotal.toStringAsFixed(2),
            snap.liabilitiesTotal.toStringAsFixed(2),
            snap.netWorth.toStringAsFixed(2),
            snap.cashTotal.toStringAsFixed(2),
            snap.bondsTotal.toStringAsFixed(2),
            snap.usEqTotal.toStringAsFixed(2),
            snap.intlEqTotal.toStringAsFixed(2),
            snap.reTotal.toStringAsFixed(2),
            snap.altTotal.toStringAsFixed(2),
          ].join(','),
        );
      }

      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileBaseName = 'rebalance_snapshots_$today';
      await CsvExporter.save(
        fileName: fileBaseName,
        csvContent: csvData.toString(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads/$fileBaseName.csv'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] Snapshot CSV export failed: $e');
      debugPrint('[Dashboard] Snapshot CSV stack: $stackTrace');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _exportSnapshotPDF(BuildContext context, Snapshot snapshot) {
    // PDF export is a Pro feature that's not yet implemented
    // This function should only be called if user is Pro
    Navigator.pop(context); // Close the snapshot detail dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export coming soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showProRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 24),
            SizedBox(width: 12),
            Text('Pro Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$feature is available with Rebalance Pro.'),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Pro for PDF exports, unlimited plans, and advanced analytics.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Would navigate to Pro screen
            },
            child: const Text('Upgrade to Pro'),
          ),
        ],
      ),
    );
  }

  void _showSnapshotContextMenu(BuildContext context, Snapshot snapshot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Snapshot Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Compare option
            ListTile(
              leading: Icon(
                Icons.compare_arrows,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Start Compare'),
              subtitle:
                  const Text('Select this as starting point for comparison'),
              onTap: () {
                Navigator.pop(context);
                _enterCompareMode(snapshot);
              },
            ),

            // Delete option
            Consumer(
              builder: (context, ref, _) {
                final snapshotsAsync = ref.watch(snapshotsProvider);
                final snapshots = snapshotsAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <Snapshot>[],
                );
                final canDelete = snapshots.length > 1;

                return ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: canDelete ? Colors.red : Colors.grey,
                  ),
                  title: Text(
                    'Delete Snapshot',
                    style: TextStyle(
                      color: canDelete ? Colors.red : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    canDelete
                        ? 'Remove this snapshot permanently'
                        : 'Cannot delete the only remaining snapshot',
                    style: TextStyle(
                      color: canDelete ? null : Colors.grey,
                    ),
                  ),
                  onTap: canDelete
                      ? () {
                          Navigator.pop(context);
                          _confirmDeleteSnapshot(context, snapshot);
                        }
                      : null,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSnapshot(BuildContext context, Snapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snapshot?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this snapshot?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(snapshot.at),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        Text(
                          'Net Worth: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(snapshot.netWorth)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, _) => FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSnapshot(context, ref, snapshot);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSnapshot(
    BuildContext context,
    WidgetRef ref,
    Snapshot snapshot,
  ) async {
    try {
      // Update the provider (this will handle both repository and state updates)
      await ref.read(snapshotsProvider.notifier).removeSnapshot(snapshot);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Snapshot deleted • ${DateFormat('MMM d, h:mm a').format(snapshot.at)}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete snapshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _enterCompareMode(Snapshot snapshot) {
    setState(() {
      isCompareMode = true;
      compareFromSnapshot = snapshot;
      compareToSnapshot = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compare mode: Select another snapshot to compare with ${DateFormat('MMM d').format(snapshot.at)}',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () => _exitCompareMode(),
        ),
      ),
    );
  }

  void _handleCompareSelection(Snapshot snapshot) {
    if (compareFromSnapshot == snapshot) {
      // Same snapshot selected, exit compare mode
      _exitCompareMode();
      return;
    }

    setState(() {
      compareToSnapshot = snapshot;
    });

    _showSnapshotComparison();
  }

  void _exitCompareMode() {
    setState(() {
      isCompareMode = false;
      compareFromSnapshot = null;
      compareToSnapshot = null;
    });
  }

  void _showSnapshotComparison() {
    if (compareFromSnapshot == null || compareToSnapshot == null) return;

    final diff =
        _calculateSnapshotDiff(compareFromSnapshot!, compareToSnapshot!);

    showDialog(
      context: context,
      builder: (context) => _CompareSnapshotsDialog(
        diff: diff,
        onSaveComparison: () => _saveComparison(diff),
      ),
    );

    _exitCompareMode();
  }

  SnapshotDiff _calculateSnapshotDiff(Snapshot from, Snapshot to) {
    // Calculate total assets from 'from' snapshot for percentage calculations
    final assetsFrom = from.cashTotal +
        from.bondsTotal +
        from.usEqTotal +
        from.intlEqTotal +
        from.reTotal +
        from.altTotal;

    double calculateBucketPct(double delta) {
      return assetsFrom > 0 ? delta / assetsFrom : 0.0;
    }

    final buckets = <BucketDiff>[
      BucketDiff(
        name: 'Cash',
        from: from.cashTotal,
        to: to.cashTotal,
        delta: to.cashTotal - from.cashTotal,
        deltaPct: calculateBucketPct(to.cashTotal - from.cashTotal),
      ),
      BucketDiff(
        name: 'Bonds',
        from: from.bondsTotal,
        to: to.bondsTotal,
        delta: to.bondsTotal - from.bondsTotal,
        deltaPct: calculateBucketPct(to.bondsTotal - from.bondsTotal),
      ),
      BucketDiff(
        name: 'US Equity',
        from: from.usEqTotal,
        to: to.usEqTotal,
        delta: to.usEqTotal - from.usEqTotal,
        deltaPct: calculateBucketPct(to.usEqTotal - from.usEqTotal),
      ),
      BucketDiff(
        name: 'Intl Equity',
        from: from.intlEqTotal,
        to: to.intlEqTotal,
        delta: to.intlEqTotal - from.intlEqTotal,
        deltaPct: calculateBucketPct(to.intlEqTotal - from.intlEqTotal),
      ),
      BucketDiff(
        name: 'Real Estate',
        from: from.reTotal,
        to: to.reTotal,
        delta: to.reTotal - from.reTotal,
        deltaPct: calculateBucketPct(to.reTotal - from.reTotal),
      ),
      BucketDiff(
        name: 'Alternatives',
        from: from.altTotal,
        to: to.altTotal,
        delta: to.altTotal - from.altTotal,
        deltaPct: calculateBucketPct(to.altTotal - from.altTotal),
      ),
    ];

    return SnapshotDiff(
      from: from.at,
      to: to.at,
      buckets: buckets,
      assetsFrom: from.assetsTotal,
      assetsTo: to.assetsTotal,
      liabilitiesFrom: from.liabilitiesTotal,
      liabilitiesTo: to.liabilitiesTotal,
      netFrom: from.netWorth,
      netTo: to.netWorth,
      netDelta: to.netWorth - from.netWorth,
    );
  }

  void _showCompareDialog(BuildContext context) {
    final snapshotsAsync = ref.read(snapshotsProvider);
    final snapshots = snapshotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Snapshot>[],
    );
    showDialog(
      context: context,
      builder: (context) => _CompareSnapshotsPickerDialog(
        snapshots: snapshots,
        onSaveComparison: _saveComparison,
      ),
    );
  }

  void _saveComparison(SnapshotDiff diff) async {
    if (!mounted) return;
    await _showSaveComparisonDialog(diff);
  }

  Future<void> _showSaveComparisonDialog(SnapshotDiff diff) async {
    if (!mounted) return;

    final TextEditingController nameController = TextEditingController();
    final fromDate = DateFormat('MMM d, yyyy').format(diff.from);
    final toDate = DateFormat('MMM d, yyyy').format(diff.to);

    // Suggest a default name
    nameController.text = '$fromDate to $toDate';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Comparison'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save this comparison for quick access later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Comparison Name',
                    hintText: 'Enter a descriptive name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison Details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: $fromDate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'To: $toDate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Net Change: ${NumberFormat.currency(symbol: '\$').format(diff.netDelta)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name for the comparison'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final savedComparison = SavedComparison(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  fromDate: diff.from,
                  toDate: diff.to,
                  createdAt: DateTime.now(),
                  netFrom: diff.netFrom,
                  netTo: diff.netTo,
                  netDelta: diff.netDelta,
                );

                await _storeSavedComparison(savedComparison);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved comparison "$name"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _storeSavedComparison(SavedComparison comparison) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing saved comparisons
      final savedComparisonsJson =
          prefs.getStringList('saved_comparisons') ?? [];

      // Add the new comparison
      savedComparisonsJson.add(jsonEncode(comparison.toMap()));

      // Save back to preferences
      await prefs.setStringList('saved_comparisons', savedComparisonsJson);
    } catch (e) {
      // Handle storage error
      debugPrint('Error saving comparison: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save comparison: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSavedComparisonsDialog(BuildContext context) async {
    final savedComparisons = await _loadSavedComparisons();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Saved Comparisons'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: savedComparisons.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No saved comparisons yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Save interesting comparisons for quick access',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: savedComparisons.length,
                    itemBuilder: (context, index) {
                      final comparison = savedComparisons[index];
                      final fromDate =
                          DateFormat('MMM d, yyyy').format(comparison.fromDate);
                      final toDate =
                          DateFormat('MMM d, yyyy').format(comparison.toDate);
                      final delta = comparison.netDelta;
                      final deltaColor = delta >= 0 ? Colors.green : Colors.red;
                      final deltaPrefix = delta >= 0 ? '+' : '';
                      final createdDate = DateFormat('MMM d, yyyy')
                          .format(comparison.createdAt);

                      return Card(
                        child: ListTile(
                          leading:
                              const Icon(Icons.bookmark, color: Colors.blue),
                          title: Text(
                            comparison.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$fromDate → $toDate'),
                              Text(
                                '$deltaPrefix${NumberFormat.currency(symbol: '\$').format(delta)}',
                                style: TextStyle(
                                  color: deltaColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Saved: $createdDate',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'load') {
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .pop(); // Close saved comparisons dialog first
                                }
                                await _loadComparison(comparison);
                              } else if (value == 'delete') {
                                await _deleteSavedComparison(comparison.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  _showSavedComparisonsDialog(context);
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'load',
                                child: Row(
                                  children: [
                                    Icon(Icons.compare_arrows, size: 18),
                                    SizedBox(width: 8),
                                    Text('Load Comparison'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<SavedComparison>> _loadSavedComparisons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedComparisonsJson =
          prefs.getStringList('saved_comparisons') ?? [];

      return savedComparisonsJson
          .map((json) => SavedComparison.fromMap(jsonDecode(json)))
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // Sort by creation date, newest first
    } catch (e) {
      debugPrint('Error loading saved comparisons: $e');
      return [];
    }
  }

  Future<void> _loadComparison(SavedComparison comparison) async {
    // Find snapshots that match the saved comparison dates
    final snapshotsAsync = ref.read(snapshotsProvider);
    final snapshots = snapshotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Snapshot>[],
    );

    // Find the closest snapshots to the saved dates
    Snapshot? fromSnapshot;
    Snapshot? toSnapshot;

    for (final snapshot in snapshots) {
      if (fromSnapshot == null ||
          (snapshot.at.difference(comparison.fromDate).abs() <
              fromSnapshot.at.difference(comparison.fromDate).abs())) {
        if (snapshot.at.difference(comparison.fromDate).abs().inDays <= 1) {
          fromSnapshot = snapshot;
        }
      }

      if (toSnapshot == null ||
          (snapshot.at.difference(comparison.toDate).abs() <
              toSnapshot.at.difference(comparison.toDate).abs())) {
        if (snapshot.at.difference(comparison.toDate).abs().inDays <= 1) {
          toSnapshot = snapshot;
        }
      }
    }

    if (fromSnapshot != null && toSnapshot != null) {
      final diff = _calculateSnapshotDiff(fromSnapshot, toSnapshot);

      // Add a small delay to ensure the saved comparisons dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _CompareSnapshotsDialog(
            diff: diff,
            onSaveComparison: () => _saveComparison(diff),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded comparison: ${comparison.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not find matching snapshots for this comparison'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteSavedComparison(String comparisonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedComparisonsJson =
          prefs.getStringList('saved_comparisons') ?? [];

      // Remove the comparison with the matching ID
      savedComparisonsJson.removeWhere((json) {
        final comparison = SavedComparison.fromMap(jsonDecode(json));
        return comparison.id == comparisonId;
      });

      // Save back to preferences
      await prefs.setStringList('saved_comparisons', savedComparisonsJson);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted saved comparison'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting saved comparison: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comparison: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Tiny sparkline painter for individual rows
class TinySparklinePainter extends CustomPainter {
  final List<Snapshot> snapshots;
  final Color color;

  TinySparklinePainter({required this.snapshots, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Find min/max for scaling
    final values = snapshots.map((s) => s.netWorth).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) {
      // Draw flat line if all values are the same
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    // Draw the line
    for (int i = 0; i < snapshots.length; i++) {
      final x = (i / (snapshots.length - 1)) * size.width;
      final normalizedValue = (snapshots[i].netWorth - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Onboarding Steps Sheet Widget
class OnboardingStepsSheet extends StatelessWidget {
  final ScrollController scrollController;

  const OnboardingStepsSheet({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Add Your Accounts',
        'description':
            'Start by adding your checking, savings, and investment accounts to track your total assets.',
        'action': 'Add Account',
        'route': '/accounts',
      },
      {
        'icon': Icons.credit_card_outlined,
        'title': 'Track Your Liabilities',
        'description':
            'Add mortgages, loans, and credit cards to get your complete net worth picture.',
        'action': 'Add Liability',
        'route': '/liabilities',
      },
      {
        'icon': Icons.gps_fixed,
        'title': 'Set Your Goals',
        'description':
            'Define your risk tolerance and financial goals to get personalized recommendations.',
        'action': 'Set Targets',
        'route': '/targets',
      },
      {
        'icon': Icons.donut_large_outlined,
        'title': 'Monitor Allocation',
        'description':
            'Review your asset allocation and get insights on rebalancing opportunities.',
        'action': 'View Reports',
        'route': '/reports',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Text(
            'Getting Started',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow these steps to set up your financial dashboard',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Steps list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      context.push(step['route'] as String);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      step['title'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  step['description'] as String,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      step['action'] as String,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareSnapshotsDialog extends StatelessWidget {
  final SnapshotDiff diff;
  final VoidCallback? onSaveComparison;

  const _CompareSnapshotsDialog({
    required this.diff,
    this.onSaveComparison,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final daysDiff = diff.to.difference(diff.from).inDays;
    final netDeltaPct =
        diff.netFrom.abs() > 0 ? diff.netDelta / diff.netFrom.abs() : 0.0;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Text(
              'Compare Snapshots',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional header with time context
            Text(
              '${DateFormat('MMM d, yyyy').format(diff.from)} → ${DateFormat('MMM d, yyyy').format(diff.to)} • ${daysDiff == 0 ? '0 days' : daysDiff == 1 ? '1 day' : '$daysDiff days'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),

            // Net Worth summary box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Worth',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${formatter.format(diff.netFrom)} → ${formatter.format(diff.netTo)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    () {
                      // Apply rounding rules to net worth delta
                      final displayNetDelta =
                          diff.netDelta.abs() < 1.0 ? 0.0 : diff.netDelta;
                      final displayNetPct = (netDeltaPct * 100).abs() < 0.05
                          ? 0.0
                          : netDeltaPct * 100;
                      return 'Δ ${displayNetDelta >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(displayNetDelta.round())} (${displayNetPct.toStringAsFixed(1)}%)';
                    }(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: daysDiff == 0
                          ? Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6)
                          : (diff.netDelta >= 0
                              ? Colors.green.shade600
                              : Colors.red.shade600),
                    ),
                  ),
                  if (daysDiff == 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pick a different date to see changes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Asset Changes section
            Text(
              'Asset Changes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (diff.buckets.every((b) => b.delta.abs() < 1.0))
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No change detected between these dates.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...diff.buckets
                          .where((bucket) => bucket.delta.abs() >= 1.0)
                          .map(
                            (bucket) =>
                                _buildComparisonRow(context, bucket, formatter),
                          ),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Assets Total
                    _buildComparisonRow(
                      context,
                      BucketDiff(
                        name: 'Assets Total',
                        from: diff.assetsFrom,
                        to: diff.assetsTo,
                        delta: diff.assetsTo - diff.assetsFrom,
                        deltaPct: diff.assetsFrom > 0
                            ? (diff.assetsTo - diff.assetsFrom) /
                                diff.assetsFrom
                            : 0.0,
                      ),
                      formatter,
                      isBold: true,
                    ),

                    // Liabilities
                    _buildComparisonRow(
                      context,
                      BucketDiff(
                        name: 'Liabilities',
                        from: diff.liabilitiesFrom,
                        to: diff.liabilitiesTo,
                        delta: diff.liabilitiesTo - diff.liabilitiesFrom,
                        deltaPct: diff.liabilitiesFrom.abs() > 0
                            ? (diff.liabilitiesTo - diff.liabilitiesFrom) /
                                diff.liabilitiesFrom.abs()
                            : 0.0,
                      ),
                      formatter,
                      isLiability: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Sticky footer with net summary and actions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                () {
                  // Apply rounding rules to sticky footer
                  final displayNetDelta =
                      diff.netDelta.abs() < 1.0 ? 0.0 : diff.netDelta;
                  final displayNetPct = (netDeltaPct * 100).abs() < 0.05
                      ? 0.0
                      : netDeltaPct * 100;
                  return 'Net: ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(diff.netFrom)} → ${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(diff.netTo)} | Δ ${displayNetDelta >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(displayNetDelta.round())} (${displayNetPct.toStringAsFixed(1)}%)';
                }(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: diff.netDelta >= 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (onSaveComparison != null)
                            TextButton.icon(
                              onPressed: onSaveComparison,
                              icon: const Icon(Icons.bookmark_add, size: 16),
                              label: const Text('Save'),
                            ),
                          if (onSaveComparison != null)
                            const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _exportComparisonCSV(context, diff),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('CSV'),
                          ),
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, _) {
                              final settingsAsync = ref.watch(settingsProvider);
                              final isPro = settingsAsync.maybeWhen(
                                data: (s) => s.isPro,
                                orElse: () => false,
                              );

                              return IconButton(
                                onPressed: isPro
                                    ? () => _exportComparisonPDF(context, diff)
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Pro Feature'),
                                            content: const Text(
                                              'PDF Export is available with Rebalance Pro.\n\n'
                                              'Upgrade to Pro for PDF exports, unlimited plans, and advanced analytics.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child:
                                                    const Text('Maybe Later'),
                                              ),
                                              FilledButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.push(AppRouter.pro);
                                                },
                                                child: const Text(
                                                  'Upgrade to Pro',
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.picture_as_pdf),
                                tooltip:
                                    isPro ? 'Export PDF' : 'PDF Export (Pro)',
                                iconSize: 20,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _exportComparisonCSV(BuildContext context, SnapshotDiff diff) async {
    try {
      final fromDate = DateFormat('yyyy-MM-dd').format(diff.from);
      final toDate = DateFormat('yyyy-MM-dd').format(diff.to);
      final fileBaseName = 'rebalance_compare_${fromDate}_to_$toDate';
      final now = DateTime.now();

      final csvData = StringBuffer();
      csvData.writeln('# Rebalance Compare Export');
      csvData.writeln(
        '# From: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(diff.from)}',
      );
      csvData.writeln(
        '# To: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(diff.to)}',
      );
      csvData.writeln('# Generated: ${now.toUtc().toIso8601String()}');
      csvData.writeln('');
      csvData.writeln(
        'asset_class,from_amount,to_amount,delta_amount,delta_percent',
      );
      for (final bucket in diff.buckets) {
        if (bucket.delta.abs() >= 1.0) {
          csvData.writeln(
            [
              bucket.name,
              bucket.from.toStringAsFixed(2),
              bucket.to.toStringAsFixed(2),
              bucket.delta.toStringAsFixed(2),
              (bucket.deltaPct * 100).toStringAsFixed(2),
            ].join(','),
          );
        }
      }

      csvData.writeln(
        [
          'Assets Total',
          diff.assetsFrom.toStringAsFixed(2),
          diff.assetsTo.toStringAsFixed(2),
          (diff.assetsTo - diff.assetsFrom).toStringAsFixed(2),
          diff.assetsFrom > 0
              ? ((diff.assetsTo - diff.assetsFrom) / diff.assetsFrom * 100)
                  .toStringAsFixed(2)
              : '0.00',
        ].join(','),
      );
      csvData.writeln(
        [
          'Net Worth',
          diff.netFrom.toStringAsFixed(2),
          diff.netTo.toStringAsFixed(2),
          diff.netDelta.toStringAsFixed(2),
          diff.netFrom.abs() > 0
              ? (diff.netDelta / diff.netFrom.abs() * 100).toStringAsFixed(2)
              : '0.00',
        ].join(','),
      );

      await CsvExporter.save(
        fileName: fileBaseName,
        csvContent: csvData.toString(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads/$fileBaseName.csv'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] Comparison CSV export failed: $e');
      debugPrint('[Dashboard] Comparison CSV stack: $stackTrace');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _exportComparisonPDF(BuildContext context, SnapshotDiff diff) {
    // PDF export is a Pro feature that's not yet implemented
    // This function should only be called if user is Pro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export coming soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    BucketDiff bucket,
    NumberFormat formatter, {
    bool isBold = false,
    bool isLiability = false,
  }) {
    // Apply rounding rules: collapse jitter if |Δ| < $1 or < 0.05%
    final displayDelta = bucket.delta.abs() < 1.0 ? 0.0 : bucket.delta;
    final displayPct =
        (bucket.deltaPct * 100).abs() < 0.05 ? 0.0 : bucket.deltaPct * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              bucket.name,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: isLiability ? Colors.red.shade700 : null,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              '${formatter.format(bucket.from)} → ${formatter.format(bucket.to)}',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '${displayDelta >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(displayDelta.round())}\n(${displayPct.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: bucket.name == 'Net Worth'
                    ? (displayDelta >= 0
                        ? Colors.green.shade600
                        : Colors.red.shade600)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface, // Neutral for asset buckets
                fontSize: 12,
                height: 1.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareSnapshotsPickerDialog extends StatefulWidget {
  final List<Snapshot> snapshots;
  final Function(SnapshotDiff)? onSaveComparison;

  const _CompareSnapshotsPickerDialog({
    required this.snapshots,
    this.onSaveComparison,
  });

  @override
  State<_CompareSnapshotsPickerDialog> createState() =>
      _CompareSnapshotsPickerDialogState();
}

class _CompareSnapshotsPickerDialogState
    extends State<_CompareSnapshotsPickerDialog> {
  Snapshot? fromSnapshot;
  Snapshot? toSnapshot;

  @override
  Widget build(BuildContext context) {
    final canCompare = fromSnapshot != null &&
        toSnapshot != null &&
        fromSnapshot != toSnapshot;
    final hasSufficientSnapshots = widget.snapshots.length >= 2;

    return AlertDialog(
      title: const Text('Compare Snapshots'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasSufficientSnapshots)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create another snapshot to compare.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Quick preset buttons
              Text(
                'Quick Comparisons:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildPresetButton('7d', 7),
                  _buildPresetButton('1m', 30),
                  _buildPresetButton('3m', 90),
                  _buildPresetButton('6m', 180),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Custom Selection:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              // From dropdown
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('From:')),
                  Expanded(
                    child: DropdownButton<Snapshot>(
                      isExpanded: true,
                      value: fromSnapshot,
                      hint: const Text('Select starting snapshot'),
                      items: widget.snapshots.asMap().entries.map((entry) {
                        final snapshot = entry.value;
                        return DropdownMenuItem(
                          value: snapshot,
                          child: Text(
                            '${DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at)} ${snapshot.source == 'manual' ? '(Manual)' : ''}',
                          ),
                        );
                      }).toList(),
                      onChanged: (snapshot) =>
                          setState(() => fromSnapshot = snapshot),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // To dropdown
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('To:')),
                  Expanded(
                    child: DropdownButton<Snapshot>(
                      isExpanded: true,
                      value: toSnapshot,
                      hint: const Text('Select ending snapshot'),
                      items: widget.snapshots.asMap().entries.map((entry) {
                        final snapshot = entry.value;
                        return DropdownMenuItem(
                          value: snapshot,
                          child: Text(
                            '${DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at)} ${snapshot.source == 'manual' ? '(Manual)' : ''}',
                          ),
                        );
                      }).toList(),
                      onChanged: (snapshot) =>
                          setState(() => toSnapshot = snapshot),
                    ),
                  ),
                ],
              ),
              // Same-snapshot warning
              if (fromSnapshot != null &&
                  toSnapshot != null &&
                  fromSnapshot == toSnapshot)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Same snapshot selected - no changes will be shown.',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canCompare
              ? () {
                  Navigator.pop(context);
                  _showComparison(context, fromSnapshot!, toSnapshot!);
                }
              : null,
          child: Text(
            !hasSufficientSnapshots
                ? 'Need 2+ snapshots'
                : fromSnapshot != null &&
                        toSnapshot != null &&
                        fromSnapshot == toSnapshot
                    ? 'No Change'
                    : 'Compare',
          ),
        ),
      ],
    );
  }

  void _showComparison(BuildContext context, Snapshot from, Snapshot to) {
    final diff = _calculateSnapshotDiff(from, to);
    showDialog(
      context: context,
      builder: (context) => _CompareSnapshotsDialog(
        diff: diff,
        onSaveComparison: widget.onSaveComparison != null
            ? () => widget.onSaveComparison!(diff)
            : null,
      ),
    );
  }

  SnapshotDiff _calculateSnapshotDiff(Snapshot from, Snapshot to) {
    // Calculate total assets from 'from' snapshot for percentage calculations
    final assetsFrom = from.cashTotal +
        from.bondsTotal +
        from.usEqTotal +
        from.intlEqTotal +
        from.reTotal +
        from.altTotal;

    double calculateBucketPct(double delta) {
      return assetsFrom > 0 ? delta / assetsFrom : 0.0;
    }

    final buckets = <BucketDiff>[
      BucketDiff(
        name: 'Cash',
        from: from.cashTotal,
        to: to.cashTotal,
        delta: to.cashTotal - from.cashTotal,
        deltaPct: calculateBucketPct(to.cashTotal - from.cashTotal),
      ),
      BucketDiff(
        name: 'Bonds',
        from: from.bondsTotal,
        to: to.bondsTotal,
        delta: to.bondsTotal - from.bondsTotal,
        deltaPct: calculateBucketPct(to.bondsTotal - from.bondsTotal),
      ),
      BucketDiff(
        name: 'US Equity',
        from: from.usEqTotal,
        to: to.usEqTotal,
        delta: to.usEqTotal - from.usEqTotal,
        deltaPct: calculateBucketPct(to.usEqTotal - from.usEqTotal),
      ),
      BucketDiff(
        name: 'Intl Equity',
        from: from.intlEqTotal,
        to: to.intlEqTotal,
        delta: to.intlEqTotal - from.intlEqTotal,
        deltaPct: calculateBucketPct(to.intlEqTotal - from.intlEqTotal),
      ),
      BucketDiff(
        name: 'Real Estate',
        from: from.reTotal,
        to: to.reTotal,
        delta: to.reTotal - from.reTotal,
        deltaPct: calculateBucketPct(to.reTotal - from.reTotal),
      ),
      BucketDiff(
        name: 'Alternatives',
        from: from.altTotal,
        to: to.altTotal,
        delta: to.altTotal - from.altTotal,
        deltaPct: calculateBucketPct(to.altTotal - from.altTotal),
      ),
    ];

    return SnapshotDiff(
      from: from.at,
      to: to.at,
      buckets: buckets,
      assetsFrom: from.assetsTotal,
      assetsTo: to.assetsTotal,
      liabilitiesFrom: from.liabilitiesTotal,
      liabilitiesTo: to.liabilitiesTotal,
      netFrom: from.netWorth,
      netTo: to.netWorth,
      netDelta: to.netWorth - from.netWorth,
    );
  }

  Widget _buildPresetButton(String label, int days) {
    return FilledButton.tonal(
      onPressed: () => _applyPreset(days),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _applyPreset(int days) {
    final label = days == 7
        ? '7 days'
        : days == 30
            ? '1 month'
            : days == 90
                ? '3 months'
                : '6 months';
    final now = DateTime.now();
    final targetDate = now.subtract(Duration(days: days));

    // Find the closest snapshots to the target dates
    Snapshot? closestFrom;
    Snapshot? closestTo;

    // Find closest snapshot to the target date (from)
    double minFromDiff = double.infinity;
    for (final snapshot in widget.snapshots) {
      final diff = (snapshot.at.difference(targetDate)).abs().inDays.toDouble();
      if (diff < minFromDiff) {
        minFromDiff = diff;
        closestFrom = snapshot;
      }
    }

    // Find the most recent snapshot (to)
    DateTime mostRecentDate = DateTime(1900);
    for (final snapshot in widget.snapshots) {
      if (snapshot.at.isAfter(mostRecentDate)) {
        mostRecentDate = snapshot.at;
        closestTo = snapshot;
      }
    }

    // Only apply if we found valid snapshots and they're different
    if (closestFrom != null && closestTo != null && closestFrom != closestTo) {
      setState(() {
        fromSnapshot = closestFrom;
        toSnapshot = closestTo;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected comparison: $label'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Progress Ring Painter for the financial health score
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw background ring
    canvas.drawCircle(center, radius, paint);

    // Draw progress arc
    paint.color = color;
    final sweepAngle = progress * 2 * 3.14159; // Full circle is 2π
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ProgressRingPainter ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

// Enhanced Score Details Sheet Widget
class EnhancedScoreDetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final FinancialHealthResult healthResult;
  final List<Account> accounts;
  final List<Liability> liabilities;
  final Settings settings;

  const EnhancedScoreDetailsSheet({
    super.key,
    required this.scrollController,
    required this.healthResult,
    required this.accounts,
    required this.liabilities,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate allocation for analysis
    final allocation = _calculateAllocation();
    final largestBucket = _findLargestBucket(allocation);
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Sticky header strip
          _buildStickyHeader(context, largestBucket, totalAssets),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Weighted breakdown
                _buildWeightedBreakdown(context),
                const SizedBox(height: 24),

                // What moved section
                _buildWhatMoved(context),
                const SizedBox(height: 24),

                // Next actions
                _buildNextActions(context),
                const SizedBox(height: 24),

                // Simulation CTA
                _buildSimulationCTA(context),
                const SizedBox(height: 24),

                // Explain bands (collapsible)
                _buildGradeBands(context),
                const SizedBox(height: 100), // Space for sticky footer
              ],
            ),
          ),

          // Sticky footer with CTAs
          _buildStickyFooter(context),
        ],
      ),
    );
  }

  Map<String, double> _calculateAllocation() {
    final allocation = {
      'Cash': 0.0,
      'Bonds': 0.0,
      'US Equity': 0.0,
      'Intl Equity': 0.0,
      'Real Estate': 0.0,
      'Alternative': 0.0,
    };

    for (final account in accounts) {
      final breakdown = account.allocationBreakdown;
      allocation['Cash'] = allocation['Cash']! + breakdown['cash']!;
      allocation['Bonds'] = allocation['Bonds']! + breakdown['bonds']!;
      allocation['US Equity'] = allocation['US Equity']! + breakdown['usEq']!;
      allocation['Intl Equity'] =
          allocation['Intl Equity']! + breakdown['intlEq']!;
      allocation['Real Estate'] =
          allocation['Real Estate']! + breakdown['realEstate']!;
      allocation['Alternative'] =
          allocation['Alternative']! + breakdown['alt']!;
    }

    return allocation;
  }

  Map<String, dynamic> _findLargestBucket(Map<String, double> allocation) {
    String largestName = '';
    double largestValue = 0.0;

    allocation.forEach((key, value) {
      if (value > largestValue) {
        largestValue = value;
        largestName = key;
      }
    });

    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);
    final percentage =
        totalAssets > 0 ? (largestValue / totalAssets) * 100 : 0.0;

    return {
      'name': largestName,
      'value': largestValue,
      'percentage': percentage,
    };
  }

  Widget _buildStickyHeader(
    BuildContext context,
    Map<String, dynamic> largestBucket,
    double totalAssets,
  ) {
    final gradeColor = _getGradeColorForDiversification(healthResult.grade);
    final percentage = largestBucket['percentage'] as double;
    const cap = 20.0; // Standard concentration cap

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: gradeColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // Big grade badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: gradeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    healthResult.grade.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Score — how balanced is your portfolio?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '${healthResult.score}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: gradeColor,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Band and rationale
                    Text(
                      '${_getGradeText(healthResult.grade)} • ${percentage > cap ? '${largestBucket['name']} ${percentage.toStringAsFixed(1)}% (cap ${cap.toStringAsFixed(0)}%)' : 'Well balanced'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightedBreakdown(BuildContext context) {
    final weights = [
      {
        'name': 'Concentration Risk',
        'weight': '30%',
        'score': 65,
        'target': 80,
      },
      {
        'name': 'Fixed Income Balance',
        'weight': '25%',
        'score': 72,
        'target': 75,
      },
      {'name': 'Liquidity Buffer', 'weight': '20%', 'score': 55, 'target': 70},
      {
        'name': 'International Exposure',
        'weight': '15%',
        'score': 78,
        'target': 80,
      },
      {'name': 'Debt Management', 'weight': '10%', 'score': 85, 'target': 90},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weighted Breakdown',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...weights.map(
          (dial) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dial['weight'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        dial['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${dial['score']}/${dial['target']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(
                          dial['score'] as int,
                          dial['target'] as int,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Meter bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        ((dial['score'] as int) / 100.0).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade400,
                            Colors.orange.shade400,
                            Colors.green.shade400,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatMoved(BuildContext context) {
    // Mock data for what changed - in real app, compare with previous calculation
    final changes = [
      {
        'name': 'Concentration',
        'change': 2,
        'reason': 'Reduced US Equity position',
      },
      {'name': 'Bonds', 'change': 1, 'reason': 'Added fixed income allocation'},
      {
        'name': 'Liquidity',
        'change': 0,
        'reason': 'No change in cash position',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What Moved',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Since last 30d:',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ...changes.map(
          (change) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _getChangeColor(change['change'] as int)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      (change['change'] as int) == 0
                          ? '0'
                          : '${(change['change'] as int) > 0 ? '+' : ''}${change['change']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getChangeColor(change['change'] as int),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${change['name']} ${(change['change'] as int) == 0 ? '' : '${(change['change'] as int) > 0 ? '+' : ''}${change['change']}'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        change['reason'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextActions(BuildContext context) {
    final actions = [
      {
        'title': 'Open Mix & Dials',
        'description': 'Review detailed allocation breakdown',
        'icon': Icons.donut_large,
        'isPrimary': true,
        'onTap': () => context.push('/reports'),
      },
      {
        'title': 'Add to Plan',
        'description': 'Create rebalancing strategy',
        'icon': Icons.auto_fix_high,
        'isPrimary': false,
        'onTap': () => context.push('/reports'),
      },
      {
        'title': 'Set Target Allocation',
        'description': 'Adjust your risk preferences',
        'icon': Icons.gps_fixed,
        'isPrimary': false,
        'onTap': () {
          // Navigate directly to the Targets & Alerts detail page
          context.push(AppRouter.targetsDetail);
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final isPrimary = action['isPrimary'] as bool;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        action['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                isPrimary
                    ? FilledButton.icon(
                        onPressed: action['onTap'] as VoidCallback,
                        icon: Icon(action['icon'] as IconData, size: 16),
                        label:
                            const Text('Open', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: action['onTap'] as VoidCallback,
                        icon: Icon(action['icon'] as IconData, size: 16),
                        label: const Text('Go', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSimulationCTA(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Test Scenarios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'See how adding \$1,500 to Bonds affects your score',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              // In real app, navigate to rebalancer with prefilled scenario
              Navigator.pop(context);
              context.push('/reports?scenario=bonds_1500');
            },
            icon: const Icon(Icons.calculate, size: 18),
            label: const Text('Run Simulation'),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBands(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Explain Grade Bands',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GradeBandRow(
                grade: 'A',
                range: '80-100',
                label: 'Excellent',
                color: Colors.green,
              ),
              _GradeBandRow(
                grade: 'B',
                range: '60-79',
                label: 'Good',
                color: Colors.lightGreen,
              ),
              _GradeBandRow(
                grade: 'C',
                range: '40-59',
                label: 'Fair',
                color: Colors.orange,
              ),
              _GradeBandRow(
                grade: 'D',
                range: '20-39',
                label: 'Needs Work',
                color: Colors.deepOrange,
              ),
              _GradeBandRow(
                grade: 'F',
                range: '0-19',
                label: 'Poor',
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: const SizedBox.shrink(), // Removed Share and Export buttons
    );
  }

  Color _getScoreColor(int score, int target) {
    final ratio = score / target;
    if (ratio >= 0.9) return Colors.green.shade600;
    if (ratio >= 0.7) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  Color _getChangeColor(int change) {
    if (change > 0) return Colors.green.shade600;
    if (change < 0) return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  String _getGradeText(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return 'Excellent Health';
      case HealthGrade.B:
        return 'Good Health';
      case HealthGrade.C:
        return 'Fair Health';
      case HealthGrade.D:
        return 'Needs Attention';
      case HealthGrade.F:
        return 'Immediate Action Required';
    }
  }

  Color _getGradeColorForDiversification(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return Colors.green.shade700;
      case HealthGrade.B:
        return Colors.lightGreen.shade700;
      case HealthGrade.C:
        return Colors.orange.shade700;
      case HealthGrade.D:
        return Colors.deepOrange.shade700;
      case HealthGrade.F:
        return Colors.red.shade700;
    }
  }
}

// Helper widget for grade band rows
class _GradeBandRow extends StatelessWidget {
  final String grade;
  final String range;
  final String label;
  final Color color;

  const _GradeBandRow({
    required this.grade,
    required this.range,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grade,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            range,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

// Score Details Sheet Widget
class ScoreDetailsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final FinancialHealthResult healthResult;
  final List<Account> accounts;
  final List<Liability> liabilities;
  final Settings settings;

  const ScoreDetailsSheet({
    super.key,
    required this.scrollController,
    required this.healthResult,
    required this.accounts,
    required this.liabilities,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Icon(
                Icons.compass_calibration_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health Score',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'How well-balanced is your portfolio?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                // Current Score Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getGradeColorForDiversification(healthResult.grade)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          _getGradeColorForDiversification(healthResult.grade)
                              .withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getGradeColorForDiversification(
                            healthResult.grade,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${healthResult.score}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${healthResult.grade.name} (${_getGradeDescription(healthResult.grade)})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              healthResult.summary,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // How It's Calculated
                Text(
                  'How It\'s Calculated',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildCalculationWeights(context),
                const SizedBox(height: 24),

                // Grade Bands
                Text(
                  'Grade Bands',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildGradeBands(context),
                const SizedBox(height: 24),

                // What to Do Next
                Text(
                  'What to Do Next',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildActionableSteps(context, healthResult),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGradeDescription(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return '80-100';
      case HealthGrade.B:
        return '60-79';
      case HealthGrade.C:
        return '40-59';
      case HealthGrade.D:
        return '20-39';
      case HealthGrade.F:
        return '0-19';
    }
  }

  Widget _buildCalculationWeights(BuildContext context) {
    final weights = [
      {
        'name': 'Concentration Risk',
        'weight': '30%',
        'description': 'No single asset class > 20%',
      },
      {
        'name': 'Fixed Income Balance',
        'weight': '25%',
        'description': 'Bonds match your target allocation',
      },
      {
        'name': 'Liquidity Buffer',
        'weight': '20%',
        'description': '3-6 months expenses in cash',
      },
      {
        'name': 'International Exposure',
        'weight': '15%',
        'description': 'Global diversification',
      },
      {
        'name': 'Debt Management',
        'weight': '10%',
        'description': 'Healthy debt-to-asset ratio',
      },
    ];

    return Column(
      children: weights
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['weight']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item['description']!,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildGradeBands(BuildContext context) {
    final bands = [
      {
        'grade': 'A',
        'range': '80-100',
        'label': 'Excellent',
        'color': Colors.green,
      },
      {
        'grade': 'B',
        'range': '60-79',
        'label': 'Good',
        'color': Colors.lightGreen,
      },
      {'grade': 'C', 'range': '40-59', 'label': 'Fair', 'color': Colors.orange},
      {
        'grade': 'D',
        'range': '20-39',
        'label': 'Needs Work',
        'color': Colors.deepOrange,
      },
      {'grade': 'F', 'range': '0-19', 'label': 'Poor', 'color': Colors.red},
    ] as List<Map<String, dynamic>>;

    return Column(
      children: bands
          .map(
            (band) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (band['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (band['color'] as Color).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: band['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        band['grade'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    band['range'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Text(band['label'] as String),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildActionableSteps(
    BuildContext context,
    FinancialHealthResult healthResult,
  ) {
    // Generate actionable steps based on the score
    List<String> steps = [];

    if (healthResult.score < 40) {
      steps.addAll([
        'Review your asset allocation fundamentals',
        'Ensure you have 3-6 months of expenses in cash',
        'Consider reducing concentration in any single asset class',
      ]);
    } else if (healthResult.score < 60) {
      steps.addAll([
        'Fine-tune your asset allocation targets',
        'Consider increasing international exposure',
        'Review and optimize your debt strategy',
      ]);
    } else if (healthResult.score < 80) {
      steps.addAll([
        'Make minor adjustments to stay on track',
        'Monitor for allocation drift over time',
        'Consider rebalancing quarterly',
      ]);
    } else {
      steps.addAll([
        'Maintain your excellent diversification',
        'Review quarterly to prevent drift',
        'Consider advanced optimization strategies',
      ]);
    }

    return Column(
      children: steps
          .asMap()
          .entries
          .map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Color _getGradeColorForDiversification(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return Colors.green.shade700;
      case HealthGrade.B:
        return Colors.lightGreen.shade700;
      case HealthGrade.C:
        return Colors.orange.shade700;
      case HealthGrade.D:
        return Colors.deepOrange.shade700;
      case HealthGrade.F:
        return Colors.red.shade700;
    }
  }
}

class MiniSparklinePainter extends CustomPainter {
  final List<double> scores;
  final Color color;
  final double strokeWidth;

  MiniSparklinePainter({
    required this.scores,
    required this.color,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty || scores.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Find min/max for scaling
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final scoreRange = maxScore - minScore;

    // Avoid division by zero
    if (scoreRange == 0) return;

    // Create path
    for (int i = 0; i < scores.length; i++) {
      final x = (i / (scores.length - 1)) * size.width;
      final normalizedScore = (scores[i] - minScore) / scoreRange;
      final y = size.height - (normalizedScore * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

// Reusable Risk Nudge Card Widget
class RiskNudgeCard extends StatefulWidget {
  final String title;
  final String diagnosis;
  final String action;
  final String ctaText;
  final VoidCallback onCTA;
  final VoidCallback? onWhy;
  final VoidCallback? onSnooze;
  final VoidCallback? onDismiss;
  final MaterialColor severityColor;
  final bool showPro;
  final bool isProgress;
  final String? progressText;
  final List<String>? personalizationChips;
  final DateTime? detectedAt; // New: timestamp for "spotted 2h ago"
  final ValueChanged<String>?
      onChipTap; // New: make chips tappable and receive the chip label

  const RiskNudgeCard({
    super.key,
    required this.title,
    required this.diagnosis,
    required this.action,
    required this.ctaText,
    required this.onCTA,
    this.onWhy,
    this.onSnooze,
    this.onDismiss,
    this.severityColor = Colors.amber,
    this.showPro = false,
    this.isProgress = false,
    this.progressText,
    this.personalizationChips,
    this.detectedAt,
    this.onChipTap,
  });

  @override
  State<RiskNudgeCard> createState() => _RiskNudgeCardState();
}

class _RiskNudgeCardState extends State<RiskNudgeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  bool _isExpanded = false; // Collapsed by default

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 8),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCTA() async {
    setState(() => _isLoading = true);

    // Simulate loading
    await Future.delayed(const Duration(milliseconds: 1500));

    widget.onCTA();

    setState(() => _isLoading = false);

    // Show success toast
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.ctaText} · 6-month glidepath'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime detectedAt) {
    final now = DateTime.now();
    final difference = now.difference(detectedAt);

    if (difference.inMinutes < 60) {
      return 'spotted ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'spotted ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'spotted ${difference.inDays}d ago';
    } else {
      return 'spotted ${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.severityColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16), // radius.card = 16
                border: Border.all(
                  color: widget.severityColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4, // elevation.2 = 4dp for alert cards
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with severity chip, title, timestamp and menu
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        // Severity chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.severityColor.shade600,
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Design token: radius.chip = 10
                          ),
                          child: const Text(
                            'High Risk',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ), // Consistent 8px gap (space.sm)
                        // Hazard icon nudged 2px right from chip
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            Icons.warning_amber_outlined,
                            color: widget.severityColor.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8), // Consistent 8px gap
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              // Timestamp if available
                              if (widget.detectedAt != null)
                                Text(
                                  _formatTimestamp(widget.detectedAt!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Expand/collapse chevron
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _isExpanded ? 0.5 : 0,
                          child: Icon(
                            Icons.expand_more,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expandable content section
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Breathing space below title (6-8px)
                              const SizedBox(height: 8),

                              // Personalization chips with desaturated styling
                              if (widget.personalizationChips != null) ...[
                                Wrap(
                                  spacing: 8, // Equal spacing between chips
                                  runSpacing: 6,
                                  children: widget.personalizationChips!
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final chip = entry.value;
                                    final isFirstChip = index ==
                                        0; // "US Equity 42.5%" stays prominent

                                    return GestureDetector(
                                      onTap: widget.onChipTap != null
                                          ? () => widget.onChipTap!(chip)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          // Tone down neutral chips while keeping High Risk dominant
                                          color: isFirstChip
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.7)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(
                                                    alpha: 0.08,
                                                  ), // onSurface 8% background
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ), // Design token: radius.chip = 10
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outline
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              chip,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isFirstChip
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ), // onSurface 65% text for readability
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            // Add tappable indicator for chips if onChipTap is provided
                                            if (widget.onChipTap != null) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 12,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                // Extra breathing space below chip row (14px total for action line separation)
                                const SizedBox(height: 14),
                              ],

                              // Primary action line with inline Why? link
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 600;

                                  if (isNarrow) {
                                    // Mobile: Stack button under action line
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Action line with inline Why?
                                        _buildActionLineWithWhy(
                                          context,
                                          isNarrow,
                                        ),
                                        const SizedBox(height: 6),
                                        // Explanatory diagnosis
                                        Text(
                                          widget.diagnosis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 14,
                                        ), // 12-16px spacing
                                        // Full-width button on mobile
                                        SizedBox(
                                          width: double.infinity,
                                          child: _buildCTAButton(
                                            context,
                                            isNarrow,
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Desktop: Right-aligned button next to action line
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .center, // Center button with action line
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Action line with inline Why?
                                                  _buildActionLineWithWhy(
                                                    context,
                                                    isNarrow,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  // Explanatory diagnosis
                                                  Text(
                                                    widget.diagnosis,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Button vertically centered with the entire left column content
                                            Align(
                                              alignment: Alignment.topCenter,
                                              child: _buildCTAButton(
                                                context,
                                                isNarrow,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  }
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionLineWithWhy(BuildContext context, bool isNarrow) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          widget.action,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (widget.onWhy != null) ...[
          const Text(' — '),
          GestureDetector(
            onTap: widget.onWhy,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Why?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
                SizedBox(width: 2), // 2px closer to text
                Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context, bool isNarrow) {
    if (widget.isProgress && widget.progressText != null) {
      return Column(
        crossAxisAlignment:
            isNarrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
            children: [
              SizedBox(
                width: 80,
                child: LinearProgressIndicator(
                  value: 0.33,
                  backgroundColor: widget.severityColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    widget.severityColor.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.progressText!,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: widget.onCTA,
            style: OutlinedButton.styleFrom(
              foregroundColor: widget.severityColor.shade700,
              side: BorderSide(color: widget.severityColor.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Adjust plan'),
          ),
        ],
      );
    } else {
      return FilledButton.icon(
        onPressed: _isLoading ? null : _handleCTA,
        style: FilledButton.styleFrom(
          backgroundColor: widget.severityColor == Colors.green
              ? Colors.green.shade600
              : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          side: widget.severityColor == Colors.green
              ? BorderSide(
                  color: Colors.green.shade700.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.auto_fix_high, size: 18),
        label: _isLoading
            ? const Text('Creating...')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.ctaText),
                  if (widget.showPro) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Pro',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  // CTA arrow to indicate primary action
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                  ),
                ],
              ),
      );
    }
  }
}

class _ExpandableDueSoonCard extends StatefulWidget {
  final List<Liability> liabilities;
  final WidgetRef ref;

  const _ExpandableDueSoonCard({required this.liabilities, required this.ref});

  @override
  State<_ExpandableDueSoonCard> createState() => _ExpandableDueSoonCardState();
}

class _ExpandableDueSoonCardState extends State<_ExpandableDueSoonCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryLiability = widget.liabilities.first;
    final totalLiabilities = widget.liabilities.length;

    // Determine primary colors based on most urgent liability
    Color backgroundColor;
    Color textColor;
    Color severityColor;
    String statusText;
    IconData iconData;

    if (primaryLiability.isOverdue) {
      backgroundColor = Colors.red.withValues(alpha: 0.06);
      textColor = Colors.red.shade800;
      severityColor = Colors.red.shade600;
      statusText = 'Overdue';
      iconData = Icons.warning;
    } else if (primaryLiability.daysUntilDue == 0) {
      backgroundColor = Colors.red.withValues(alpha: 0.06);
      textColor = Colors.red.shade800;
      severityColor = Colors.red.shade600;
      statusText = 'Due Today';
      iconData = Icons.today;
    } else {
      backgroundColor = Colors.orange.withValues(alpha: 0.06);
      textColor = Colors.orange.shade800;
      severityColor = Colors.orange.shade600;
      statusText = 'Due Soon';
      iconData = Icons.calendar_today;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with severity chip, title, timestamp and chevron
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Severity chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icon
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    iconData,
                    color: textColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Due',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$totalLiabilities ${totalLiabilities == 1 ? 'liability' : 'liabilities'} need attention',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Expand/collapse chevron
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: _isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Expandable content section
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      // All liabilities
                      ...widget.liabilities.asMap().entries.map((entry) {
                        final index = entry.key;
                        final liability = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index < widget.liabilities.length - 1 ? 12 : 0,
                          ),
                          child: _buildLiabilityRow(
                            liability,
                            isFirst: index == 0,
                          ),
                        );
                      }),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilityRow(Liability liability, {required bool isFirst}) {
    final daysUntil = liability.daysUntilDue;

    // Determine colors and status for this specific liability
    Color textColor;
    Color pillColor;
    String statusText;

    if (liability.isOverdue) {
      textColor = Colors.red.shade800;
      pillColor = Colors.red.shade600;
      statusText = 'Overdue';
    } else if (daysUntil == 0) {
      textColor = Colors.red.shade800;
      pillColor = Colors.red.shade600;
      statusText = 'Due Today';
    } else if (daysUntil == 1) {
      textColor = Colors.orange.shade800;
      pillColor = Colors.orange.shade600;
      statusText = 'Due Tomorrow';
    } else {
      textColor = Colors.orange.shade800;
      pillColor = Colors.orange.shade600;
      statusText = 'Due Soon';
    }

    // Format due date text
    String dueDateText;
    if (liability.isOverdue) {
      final overdueDays = -daysUntil!;
      dueDateText = overdueDays == 1
          ? '${liability.name} overdue by 1 day — '
          : '${liability.name} overdue by $overdueDays days — ';
    } else if (daysUntil == 0) {
      dueDateText = '${liability.name} due today — ';
    } else if (daysUntil == 1) {
      dueDateText = '${liability.name} due tomorrow — ';
    } else {
      dueDateText = '${liability.name} due in $daysUntil days — ';
    }

    return InkWell(
      onTap: () => context.push('${AppRouter.liabilities}/${liability.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                  children: [
                    TextSpan(
                      text: '$statusText • ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: dueDateText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\$${liability.minPayment.toStringAsFixed(0)} minimum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Paid button
            InkWell(
              onTap: () => _showPaymentDialog(context, liability),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Liability liability) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PaymentDialog(
        liability: liability,
        onPaymentComplete: () async {
          // Trigger dashboard data reload from the parent context
          await widget.ref.read(liabilitiesProvider.notifier).reload();
          await widget.ref.read(accountsProvider.notifier).reload();
          debugPrint('Dashboard providers reloaded after payment');
        },
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Liability liability;
  final Future<void> Function() onPaymentComplete;

  const _PaymentDialog({
    required this.liability,
    required this.onPaymentComplete,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountController = TextEditingController();
  String _selectedPaymentType = 'minimum';
  double? _customAmount;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _updateAmountForPaymentType();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateAmountForPaymentType() {
    double amount;
    switch (_selectedPaymentType) {
      case 'minimum':
        amount = widget.liability.minPayment;
        break;
      case 'full':
        amount = widget.liability.balance;
        break;
      case 'round_up':
        final roundUp =
            ((widget.liability.minPayment / 50).ceil() * 50).toDouble();
        amount = roundUp;
        break;
      case 'extra':
        amount = widget.liability.minPayment + 50;
        break;
      case 'custom':
        amount = _customAmount ?? widget.liability.minPayment;
        break;
      default:
        amount = widget.liability.minPayment;
    }

    _amountController.text = amount.toStringAsFixed(2);
  }

  double get _paymentAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _newBalance =>
      (widget.liability.balance - _paymentAmount).clamp(0.0, double.infinity);
  bool get _isValidPayment =>
      _paymentAmount > 0 && _paymentAmount <= widget.liability.balance;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.payment,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark as Paid',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.liability.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Current balance info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Balance'),
                        Text(
                          '\$${widget.liability.balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Minimum Payment'),
                        Text(
                          '\$${widget.liability.minPayment.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payment type selection
              const Text(
                'Payment Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPaymentTypeChip(
                    'minimum',
                    'Minimum',
                    '\$${widget.liability.minPayment.toStringAsFixed(0)}',
                  ),
                  _buildPaymentTypeChip(
                    'round_up',
                    'Round Up',
                    '\$${((widget.liability.minPayment / 50).ceil() * 50).toStringAsFixed(0)}',
                  ),
                  _buildPaymentTypeChip(
                    'extra',
                    'Extra \$50',
                    '\$${(widget.liability.minPayment + 50).toStringAsFixed(0)}',
                  ),
                  _buildPaymentTypeChip('full', 'Pay Off', 'Full'),
                  _buildPaymentTypeChip('custom', 'Custom', 'Custom'),
                ],
              ),
              const SizedBox(height: 16),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  errorText: !_isValidPayment && _paymentAmount > 0
                      ? 'Amount cannot exceed balance'
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _customAmount = double.tryParse(value);
                    if (_selectedPaymentType != 'custom') {
                      _selectedPaymentType = 'custom';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Notes (optional)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add a note about this payment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
                onChanged: (value) {
                  _notes = value.isEmpty ? null : value;
                },
              ),
              const SizedBox(height: 20),

              // Payment preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Amount'),
                        Text(
                          '\$${_paymentAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Balance'),
                        Text(
                          '\$${_newBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isValidPayment ? () => _processPayment() : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Mark as Paid',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  Widget _buildPaymentTypeChip(String type, String label, String amount) {
    final isSelected = _selectedPaymentType == type;
    return FilterChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
          if (type != 'custom')
            Text(
              amount,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPaymentType = type;
            _updateAmountForPaymentType();
          });
        }
      },
      selectedColor: Colors.green.shade600,
      backgroundColor: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Future<void> _processPayment() async {
    if (!_isValidPayment) return;

    try {
      // Create payment record
      final payment = Payment.create(
        liabilityId: widget.liability.id,
        amount: _paymentAmount,
        paymentType: _selectedPaymentType,
        notes: _notes,
        previousBalance: widget.liability.balance,
        newBalance: _newBalance,
      );

      // Save payment to database
      await RepositoryService.savePayment(payment);

      // Update liability balance and due date
      final updatedLiability = Liability(
        id: widget.liability.id,
        name: widget.liability.name,
        balance: _newBalance,
        minPayment: _newBalance == 0 ? 0 : widget.liability.minPayment,
        apr: widget.liability.apr,
        kind: widget.liability.kind,
        updatedAt: DateTime.now(),
        creditLimit: widget.liability.creditLimit,
        nextPaymentDate: _calculateNextPaymentDate(),
        paymentFrequencyDays: widget.liability.paymentFrequencyDays,
        dayOfMonth: widget.liability.dayOfMonth,
      );

      // Save updated liability
      await RepositoryService.saveLiability(updatedLiability);

      // Debug: Print the updated balance
      debugPrint(
        'Payment processed: ${widget.liability.name} balance updated from ${widget.liability.balance} to ${updatedLiability.balance}',
      );

      // Close dialog first
      Navigator.pop(context);

      // Trigger dashboard data reload using callback
      await widget.onPaymentComplete();

      // Show success message
      final message = _paymentAmount >= widget.liability.balance
          ? 'Congratulations! ${widget.liability.name} has been paid off!'
          : 'Payment of \$${_paymentAmount.toStringAsFixed(2)} recorded for ${widget.liability.name}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  DateTime? _calculateNextPaymentDate() {
    // If the liability is paid off, no next payment date
    if (_newBalance == 0) return null;

    final now = DateTime.now();
    final currentDueDate = widget.liability.nextPaymentDate;

    // If no current due date or frequency info, return null
    if (currentDueDate == null ||
        widget.liability.paymentFrequencyDays == null) {
      return null;
    }

    // Calculate next payment date based on frequency
    final frequency = widget.liability.paymentFrequencyDays!;

    // If current payment is overdue, calculate from today
    if (currentDueDate.isBefore(now)) {
      return DateTime(
        now.year,
        now.month + 1,
        widget.liability.dayOfMonth ?? 1,
      );
    }

    // Otherwise, advance by the frequency period
    return currentDueDate.add(Duration(days: frequency));
  }
}
