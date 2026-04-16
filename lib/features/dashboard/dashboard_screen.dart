import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../routes.dart' show AppRouter;
import '../../data/repositories.dart';
import 'mini_trend_chart_painter.dart';
import '../../data/models.dart';
import '../../data/snapshot_service.dart';
import '../../data/calculators/financial_health.dart';
import '../../data/calculators/allocation.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/currency_text.dart';
import '../../services/analytics_service.dart';
import '../pro/pro_screen.dart';
import 'widgets/risk_nudge_card.dart';
import 'widgets/onboarding_steps_sheet.dart';
import 'widgets/score_details_sheet.dart';
import 'widgets/net_worth_history_sheet.dart';
import 'widgets/command_center_section.dart';

import '../../app.dart';
import '../../generated/app_localizations.dart';

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
    // Redesigned as a compact info banner (less intrusive, no misleading score predictions)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Low intl exposure detected — tap to exclude from score',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.87),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.6),
                ),
              ],
            ),
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

  // Helper method to get currency code from settings
  String _getCurrency(WidgetRef ref) {
    return ref.watch(settingsProvider).value?.currency ?? 'USD';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.03),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: CommandCenterSection(accounts: accounts),
          ),

          // Weekly Guardrails / Safe to Spend Card
          SliverToBoxAdapter(
            child: _buildWeeklyGuardrailsCard(context, ref),
          ),

          // Profile Completion Indicator
          SliverToBoxAdapter(
            child: _buildProfileCompletionCard(context, ref, accounts),
          ),

          // Enhanced Net Worth Card with History
          SliverToBoxAdapter(
            child: _buildNetWorthCard(context, ref, accounts),
          ),

          // Pro Features Banner (dismissible)
          SliverToBoxAdapter(
            child: _buildProBanner(context, ref),
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
                    AppLocalizations.of(context)!.recentAccounts,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRouter.accounts),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                        '${AppLocalizations.of(context)!.viewAll} (${accounts.length})',
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
                        ref,
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
      ),
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
    WidgetRef ref,
    Account account,
    int index,
    int totalCount,
    double totalAssets,
  ) {
    final currency = _getCurrency(ref);
    final percentOfPortfolio = (account.balance / totalAssets) * 100;
    final accountColor = _getAccountKindColor(context, account.kind);
    final lastUpdated = _getLastUpdatedText(context, account);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Material(
        elevation: 6,
        shadowColor: accountColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                accountColor.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accountColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Semantics(
            label:
                '${_getAccountTypeDisplayName(account.kind)}, ${account.name}, balance ${CurrencyFormatter.format(account.balance, currency)}, ${percentOfPortfolio.toStringAsFixed(1)} percent of portfolio',
            hint: 'Tap to view details, long press for quick actions',
            button: true,
            child: InkWell(
              onTap: () =>
                  context.push(AppRouter.accountDetail, extra: account),
              onLongPress: () => _showAccountQuickActions(context, account),
              borderRadius: BorderRadius.circular(20),
              child: ListTile(
                visualDensity: const VisualDensity(vertical: 0),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accountColor.withValues(alpha: 0.2),
                        accountColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accountColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accountColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getAccountIcon(account.kind),
                    color: accountColor,
                    size: 26,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: CurrencyText(
                          account.balance,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: accountColor.withValues(alpha: 0.6),
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
              ),
            ),
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
  String _getLastUpdatedText(BuildContext context, Account account) {
    final loc = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final updated = account.updatedAt;
    final difference = now.difference(updated);

    if (difference.inMinutes < 1) return 'Updated just now';
    if (difference.inHours < 1) return 'Updated ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return loc.updatedToday;
    if (difference.inDays == 1) return loc.updatedYesterday;
    return 'Updated ${difference.inDays}d ago';
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
            child: Text(AppLocalizations.of(context)!.cancel),
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
              AppLocalizations.of(context)!.noAccountsYet,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.getStarted,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppRouter.accounts),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addYourFirstAccount),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          Consumer(
            builder: (context, ref, child) => FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                await _loadSampleData(context, ref);
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

  Future<void> _loadSampleData(BuildContext context, WidgetRef ref) async {
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

    // Create sample income sources
    final sampleIncomes = [
      Income(
        id: 'sample_salary',
        name: 'Main Job Salary',
        kind: 'Salary',
        grossAmount: 6500.0,
        frequency: 'Monthly',
        updatedAt: DateTime.now(),
        federalTax: 1100.0,
        stateTax: 325.0,
        socialSecurityTax: 403.0,
        medicareTax: 94.25,
        retirement401k: 650.0,
        healthInsurance: 250.0,
        otherDeductions: 75.0,
      ),
      Income(
        id: 'sample_freelance',
        name: 'Freelance Work',
        kind: 'Freelance',
        grossAmount: 1200.0,
        frequency: 'Monthly',
        updatedAt: DateTime.now(),
        // No deductions for freelance - user handles taxes
      ),
    ];

    // Save to repositories
    for (final account in sampleAccounts) {
      await RepositoryService.saveAccount(account);
    }

    for (final liability in sampleLiabilities) {
      await RepositoryService.saveLiability(liability);
    }

    for (final income in sampleIncomes) {
      await RepositoryService.saveIncome(income);
    }

    // Refresh the providers to update the UI
    // Check if widget is still mounted before using ref
    if (context.mounted) {
      ref.read(accountsProvider.notifier).reload();
      ref.read(liabilitiesProvider.notifier).reload();
      ref.read(incomesProvider.notifier).reload();
    }
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
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
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
                    AppLocalizations.of(context)!.assetAllocation,
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
                    label: Text(AppLocalizations.of(context)!.viewFullAnalysis),
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
                Builder(
                  builder: (ctx) {
                    final settings = ref.watch(settingsProvider).value;
                    if (settings == null) return const SizedBox.shrink();
                    return _maybeBuildIntlAutosuggest(
                      context,
                      settings,
                      accounts,
                      ref,
                    );
                  },
                ),

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

  String _translateAssetClass(BuildContext context, String assetClass) {
    final loc = AppLocalizations.of(context)!;
    switch (assetClass) {
      case 'Cash':
        return loc.cash;
      case 'Bonds':
        return loc.bonds;
      case 'US Equity':
        return loc.usEquity;
      case 'Intl Equity':
        return loc.intlEquity;
      case 'Equities':
        return loc.equities;
      case 'Real Estate':
        return loc.realEstate;
      case 'Alternative':
      case 'Commodities':
        return loc.commodities;
      case 'Crypto':
        return loc.crypto;
      default:
        return loc.other;
    }
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
        final percent = totalAssets.abs() > 0
            ? (e.value.abs() / totalAssets.abs()) * 100
            : 0.0;
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
                  _translateAssetClass(context, e.key),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
    if (totalAssets.abs() < 0.01) {
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
      const Color(0xFF546E7A), // Blue Grey
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFFFF8F00), // Orange
      const Color(0xFF00796B), // Teal
      const Color(0xFFD32F2F), // Red
    ];

    int colorIndex = 0;
    allocation.forEach((key, value) {
      if (value.abs() > 0.01) {
        // Use absolute value to handle negative totals
        final absValue = value.abs();
        final percentage = (absValue / totalAssets.abs()) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: absValue,
            // Use one decimal to match the legend formatting
            title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 45, // Increased from 30 for wider color sections
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

    // If no sections, show empty state
    if (sections.isEmpty) {
      return Center(
        child: Text(
          'No allocation data',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 70, // Increased from 50 for larger center area
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
      ),
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
          AppLocalizations.of(context)!.totalEquities,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (hasTarget) ...[
          const SizedBox(height: 2),
          Text(
            '${AppLocalizations.of(context)!.vsTarget} ${targetEquitiesPercentage.toStringAsFixed(0)}%',
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

  Widget _buildProBanner(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final settings = settingsAsync.value;

    // Don't show banner if:
    // 1. User is already Pro
    // 2. User has dismissed it
    // 3. Settings not loaded yet
    if (settings == null ||
        settings.isPro == true ||
        settings.proBannerDismissed == true) {
      return const SizedBox.shrink();
    }

    // Track banner view (only once per session to avoid spam)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService().logProBannerView();
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🎉 NEW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Retirement Calculator',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monte Carlo simulation shows if you\'re on track',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CTA Button
                    GestureDetector(
                      onTap: () {
                        AnalyticsService().logProBannerTap();
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => const ProScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Try Free for 7 Days',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dismiss button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Track banner dismiss
                  AnalyticsService().logProBannerDismiss();

                  // Update settings to mark banner as dismissed
                  final settingsNotifier = ref.read(settingsProvider.notifier);
                  final updated = Settings(
                    riskBand: settings.riskBand,
                    monthlyEssentials: settings.monthlyEssentials,
                    driftThresholdPct: settings.driftThresholdPct,
                    notificationsEnabled: settings.notificationsEnabled,
                    usEquityTargetPct: settings.usEquityTargetPct,
                    isPro: settings.isPro,
                    biometricLockEnabled: settings.biometricLockEnabled,
                    darkModeEnabled: settings.darkModeEnabled,
                    colorTheme: settings.colorTheme,
                    liquidityBondHaircut: settings.liquidityBondHaircut,
                    bucketCap: settings.bucketCap,
                    employerStockThreshold: settings.employerStockThreshold,
                    monthlyIncome: settings.monthlyIncome,
                    incomeMultiplierFallback: settings.incomeMultiplierFallback,
                    schemaVersion: settings.schemaVersion,
                    concentrationRiskSnoozedUntil:
                        settings.concentrationRiskSnoozedUntil,
                    concentrationRiskResolvedAt:
                        settings.concentrationRiskResolvedAt,
                    homeCountry: settings.homeCountry,
                    globalDiversificationMode:
                        settings.globalDiversificationMode,
                    intlTargetOverride: settings.intlTargetOverride,
                    intlTolerancePct: settings.intlTolerancePct,
                    intlFloorPct: settings.intlFloorPct,
                    intlPenaltyScale: settings.intlPenaltyScale,
                    financialHealthBaseline: settings.financialHealthBaseline,
                    financialHealthGlobalScale:
                        settings.financialHealthGlobalScale,
                    currency: settings.currency,
                    baseCurrency: settings.baseCurrency,
                    proBannerDismissed: true, // Mark as dismissed
                  );
                  settingsNotifier.updateSettings(updated);
                },
              ),
            ],
          ),
        ),
      ),
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
    final settings = settingsAsync.value;

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
    final currency = settings?.currency ?? 'USD';

    return RiskNudgeCard(
      title: AppLocalizations.of(context)!.reduceConcentrationRisk,
      diagnosis:
          '${AppLocalizations.of(context)!.largestBucket} ${_translateAssetClass(context, largestBucket)} (${largestPercentage.toStringAsFixed(1)}%). ${AppLocalizations.of(context)!.capPerBucket} ≤20%.',
      action:
          '${AppLocalizations.of(context)!.shiftPerMonth} ${CurrencyFormatter.format(movePerMonth.toDouble(), currency)} for ~6 ${AppLocalizations.of(context)!.months} to Bonds/Intl.',
      ctaText: AppLocalizations.of(context)!.createRebalancingPlan,
      severityColor: Colors.amber,
      showPro: !isPro,
      personalizationChips: [
        '${_translateAssetClass(context, largestBucket)} ${largestPercentage.toStringAsFixed(1)}%',
        '${AppLocalizations.of(context)!.cap} 20%',
        '${AppLocalizations.of(context)!.targetShift} ${CurrencyFormatter.format(amountToMove.round().toDouble(), currency)}',
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
            final loc = AppLocalizations.of(context)!;

            if (chipLabel.startsWith(loc.usEquity)) {
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
            } else if (chipLabel.startsWith(loc.cap)) {
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
                      child: Text(AppLocalizations.of(context)!.createPlan),
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
        final router = GoRouter.of(parentContext);
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
                    () => router.push(AppRouter.rebalancing),
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

  Widget _buildDueSoonNudge(BuildContext context, WidgetRef ref) {
    // Placeholder nudge area — keep minimal to avoid layout issues.
    // The full nudge implementation lives elsewhere; this keeps the
    // dashboard stable while we display the detailed score sheet.
    return const SizedBox.shrink();
  }

  Widget _buildProfileCompletionCard(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    final loc = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final liabilitiesAsync = ref.watch(liabilitiesProvider);

    return settingsAsync.when(
      data: (settings) => incomesAsync.when(
        data: (incomes) => liabilitiesAsync.when(
          data: (liabilities) {
            // Calculate completion
            final completion = _calculateProfileCompletion(
              settings,
              accounts,
              incomes,
              liabilities,
            );

            // Hide if 100% complete or dismissed
            if (completion['percentage'] >= 100) {
              return const SizedBox.shrink();
            }

            final percentage = completion['percentage'] as int;
            final missingItems = completion['missing'] as List<String>;

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Material(
                elevation: 4,
                shadowColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () =>
                      _showProfileCompletionDetails(context, missingItems),
                  child: Container(
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
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.psychology_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.profileSetup,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    loc.percentComplete(percentage),
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            minHeight: 8,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.5),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          loc.completeProfileInsights,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Map<String, dynamic> _calculateProfileCompletion(
    Settings settings,
    List<Account> accounts,
    List<Income> incomes,
    List<Liability> liabilities,
  ) {
    int completed = 0;
    int total = 5;
    List<String> missing = [];

    // Check accounts (20%)
    if (accounts.isNotEmpty) {
      completed++;
    } else {
      missing.add('Add at least one account');
    }

    // Check income (20%)
    if (incomes.isNotEmpty) {
      completed++;
    } else {
      missing.add('Add your income sources');
    }

    // Check monthly essentials (20%)
    if (settings.monthlyEssentials > 0) {
      completed++;
    } else {
      missing.add('Set monthly essential expenses');
    }

    // Check risk profile/allocation targets (20%)
    // Risk band is always set, so check if it's been actively configured
    // by checking if user has at least 2 accounts (indicating they've engaged with allocation)
    if (accounts.length >= 2) {
      completed++;
    } else {
      missing.add('Add multiple accounts for allocation tracking');
    }

    // Check liabilities (20% - optional but good to have)
    if (liabilities.isNotEmpty) {
      completed++;
    } else {
      missing.add('Add debts (if any)');
    }

    final percentage = ((completed / total) * 100).round();

    return {
      'percentage': percentage,
      'completed': completed,
      'total': total,
      'missing': missing,
    };
  }

  void _showProfileCompletionDetails(
    BuildContext context,
    List<String> missing,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Complete Your Setup',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Add these to unlock better insights:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            ...missing.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyLarge,
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
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to appropriate screen based on first missing item
                  if (missing.contains('Add at least one account')) {
                    context.push(AppRouter.accounts);
                  } else if (missing.contains('Add your income sources')) {
                    context.push(AppRouter.income);
                  } else if (missing
                      .contains('Set monthly essential expenses')) {
                    context.push(AppRouter.targets);
                  } else if (missing.contains('Configure allocation targets')) {
                    context.push(AppRouter.targets);
                  } else if (missing.contains('Add debts (if any)')) {
                    context.push(AppRouter.liabilities);
                  }
                },
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGuardrailsCard(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(settingsProvider);
    final incomesAsync = ref.watch(incomesProvider);
    final liabilitiesAsync = ref.watch(liabilitiesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    return settingsAsync.when(
      data: (settings) => incomesAsync.when(
        data: (incomes) => liabilitiesAsync.when(
          data: (liabilities) => accountsAsync.when(
            data: (accounts) => expensesAsync.when(
              data: (expenses) {
                // Calculate weekly data
                final weeklyData = _calculateWeeklyGuardrailsData(
                  settings,
                  incomes,
                  liabilities,
                  accounts,
                  expenses,
                );

                final safeToSpend =
                    (weeklyData['safeToSpend'] as num).toDouble();
                final daysOfBuffer = weeklyData['daysOfBuffer'] as int;
                final weeklyIncome =
                    (weeklyData['weeklyIncome'] as num).toDouble();
                final weeklyBills =
                    (weeklyData['weeklyBills'] as num).toDouble();

                // Determine state colors
                final Color statusColor;
                final String statusIcon;
                final String statusText;

                if (safeToSpend < 0) {
                  statusColor = Colors.red;
                  statusIcon = '🚨';
                  statusText = loc.overBudgetThisWeek;
                } else if (daysOfBuffer < 3) {
                  statusColor = Colors.orange;
                  statusIcon = '⚠';
                  statusText = loc.onTrack;
                } else {
                  statusColor = Colors.green;
                  statusIcon = '✓';
                  statusText = loc.onTrack;
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Material(
                    elevation: 8,
                    shadowColor: statusColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => context.push(AppRouter.guardrails),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              statusColor.withValues(alpha: 0.15),
                              statusColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  statusIcon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.weeklyGuardrails,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        statusText,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: statusColor.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.safeToSpendThisWeek,
                              style: TextStyle(
                                color: statusColor.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CurrencyText(
                              safeToSpend,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (daysOfBuffer >= 0)
                              Text(
                                loc.daysOfBuffer(daysOfBuffer),
                                style: TextStyle(
                                  color: statusColor.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.weeklyIncome,
                                        style: TextStyle(
                                          color: statusColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CurrencyText(
                                        weeklyIncome,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loc.weeklyBills,
                                        style: TextStyle(
                                          color: statusColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      CurrencyText(
                                        weeklyBills,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
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
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Map<String, dynamic> _calculateWeeklyGuardrailsData(
    Settings settings,
    List<Income> incomes,
    List<Liability> liabilities,
    List<Account> accounts,
    List<MonthlyExpense> expenses,
  ) {
    // Calculate weekly income (using monthlyNet - after tax)
    double weeklyIncome = 0;
    for (var income in incomes) {
      final netMonthly = income.monthlyNet;
      weeklyIncome += netMonthly / 4.33;
    }

    // Calculate weekly bills (monthly expenses + debt payments)
    double monthlyExpensesTotal = 0;
    for (var expense in expenses) {
      monthlyExpensesTotal += expense.amount;
    }
    double weeklyBills = monthlyExpensesTotal / 4.33;

    for (var liability in liabilities) {
      final monthlyPayment = liability.minPayment;
      weeklyBills += monthlyPayment / 4.33;
    }

    // Calculate total cash across accounts
    double totalCash = 0;
    for (var account in accounts) {
      if (account.kind == 'cash' || account.kind == 'checking') {
        totalCash += account.balance;
      }
    }

    // Calculate daily burn rate and buffer days
    final dailyBurn = weeklyBills / 7;

    // Buffer is always: how many days can cash cover the bills?
    final daysWeCanCover = dailyBurn > 0 ? (totalCash / dailyBurn) : 0;
    final cappedDays = daysWeCanCover.floor().clamp(0, 7);

    // Safe to spend = weekly income - weekly bills (can be negative)
    final safeToSpend = weeklyIncome - weeklyBills;

    return {
      'safeToSpend': safeToSpend,
      'weeklyIncome': weeklyIncome,
      'weeklyBills': weeklyBills,
      'daysOfBuffer': cappedDays,
      'dailyBurn': dailyBurn,
    };
  }

  Widget _buildNetWorthCard(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    // Calculate net worth
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);
    final currency = _getCurrency(ref);

    // Auto-create snapshot if it's been more than 24 hours
    _maybeCreateSnapshot(ref);

    // Get last snapshot for delta calculation
    final snapshotsAsync = ref.watch(snapshotsProvider);

    return snapshotsAsync.when(
      loading: () => _buildNetWorthCardLoading(
        context,
        totalAssets,
        accounts.length,
        currency,
      ),
      error: (error, stack) => _buildNetWorthCardLoading(
        context,
        totalAssets,
        accounts.length,
        currency,
      ),
      data: (snapshots) {
        return _buildNetWorthCardWithData(
          context,
          ref,
          totalAssets,
          accounts.length,
          snapshots,
        );
      },
    );
  }

  Widget _buildNetWorthCardLoading(
    BuildContext context,
    double totalAssets,
    int accountCount,
    String currency,
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
                  AppLocalizations.of(context)!.netWorthLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                CurrencyText(
                  totalAssets,
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
    WidgetRef ref,
    double totalAssets,
    int accountCount,
    List<Snapshot> snapshots,
  ) {
    // Calculate 30-day delta
    double? deltaAmount;

    if (snapshots.isNotEmpty) {
      // Find snapshot from ~30 days ago
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldSnapshot =
          snapshots.where((s) => s.at.isBefore(thirtyDaysAgo)).lastOrNull;

      if (oldSnapshot != null) {
        deltaAmount = totalAssets - oldSnapshot.netWorth;
      }
    }

    final hasDelta = deltaAmount != null;
    final deltaValue = deltaAmount ?? 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Material(
        elevation: 16,
        shadowColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () => _showNetWorthHistory(context, snapshots),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                  Color(0xFF388E3C),
                  Color(0xFF00897B),
                  Color(0xFF00796B),
                ],
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.white.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Financial Health Score — Expanded gives the pill bounded
                    // constraints from the parent Row; Align pushes it right.
                    // Using Spacer here would split remaining space 50/50 with
                    // Expanded, making the pill too narrow.
                    Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: _buildIntegratedHealthScore(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.netWorth,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFFFDE7),
                      Colors.white,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ).createShader(bounds),
                  child: CurrencyText(
                    totalAssets,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          color: const Color(0xFF80CBC4).withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (hasDelta)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: (deltaValue >= 0 ? Colors.green : Colors.red)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (deltaValue >= 0 ? Colors.green : Colors.red)
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          deltaValue >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: deltaValue >= 0
                              ? Colors.lightGreenAccent
                              : Colors.red.shade200,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        CurrencyText(
                          deltaValue,
                          showSign: true,
                          useAbsoluteValue: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${AppLocalizations.of(context)!.timeframe30d})',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (snapshots.length > 1) ...[
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 60,
                            height: 20,
                            child: _buildTinySparkline(context, snapshots),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push(AppRouter.accounts),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$accountCount ${AppLocalizations.of(context)!.accounts.toLowerCase()}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.update_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getUpdatedDateText(context),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  String _getUpdatedDateText(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(now.year, now.month, now.day);

    if (checkDate == today) {
      return AppLocalizations.of(context)!.updatedToday;
    } else if (checkDate == yesterday) {
      return AppLocalizations.of(context)!.updatedYesterday;
    } else {
      final daysAgo = today.difference(checkDate).inDays;
      if (daysAgo < 30) {
        return AppLocalizations.of(context)!.updatedDaysAgo(daysAgo);
      } else {
        // For dates older than 30 days, just use the date format
        return '${AppLocalizations.of(context)!.updated} ${DateFormat('MMM d').format(now)}';
      }
    }
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
            title: Text(AppLocalizations.of(context)!.view),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.show_chart),
                  title: Text(AppLocalizations.of(context)!.trend),
                  onTap: () {
                    debugPrint('Dashboard: dialog -> Trend selected');
                    Navigator.of(dialogCtx).pop();
                    // Show the trend view
                    _showHealthTrendMiniChart(context, healthResult);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(AppLocalizations.of(context)!.financialScore),
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
              'Overall financial health score ${healthResult.grade.name}, ${healthResult.score}. ${scoreDelta != 0 ? '${scoreDelta > 0 ? "Increased" : "Decreased"} by ${scoreDelta.abs()} points over $timeframe.' : ''} ${_getStatusLabel(context, healthResult.score)}. ${_getOverallHealthSubtitle(healthResult, context)}.',
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
                // Main column holds the pill content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main row with hierarchy: D • 68 big, Fair smaller, trend tertiary
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                        Flexible(
                          child: Text(
                            _getStatusLabel(context, healthResult.score),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                      mainAxisSize: MainAxisSize.max,
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
                          AppLocalizations.of(context)!.overall,
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
                              context,
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

  String _getStatusLabel(BuildContext context, int score) {
    // Align status labels with grade bands for consistency
    final localizations = AppLocalizations.of(context)!;
    if (score >= 90) return localizations.excellent; // A grade: 90-100
    if (score >= 80) return localizations.good; // B grade: 80-89
    if (score >= 70) return localizations.fair; // C grade: 70-79
    if (score >= 60) {
      return localizations
          .needsWork; // D grade: 60-69 (consistent with "Needs Attention")
    }
    return localizations.critical; // F grade: 0-59
  }

  // Removed: _getStatusLabelColor (unused)

  // Enhanced grade badge with tonal grade color and consistent styling
// Quieter delta chip with outline style and clear timeframe
// Get main driver text for actionable info
// Map account types to asset classes for main driver text
  String _translateComponentName(String componentName, BuildContext context) {
    switch (componentName) {
      case 'Debt Load':
        return AppLocalizations.of(context)!.componentDebtLoad;
      case 'Concentration':
        return AppLocalizations.of(context)!.componentConcentration;
      case 'Liquidity':
        return AppLocalizations.of(context)!.componentLiquidity;
      case 'Fixed Income':
        return AppLocalizations.of(context)!.componentFixedIncome;
      case 'Home Bias':
        return AppLocalizations.of(context)!.componentHomeBias;
      default:
        return componentName;
    }
  }

  String _getOverallHealthSubtitle(
    FinancialHealthResult healthResult,
    BuildContext context,
  ) {
    if (healthResult.componentScores.isEmpty) {
      return AppLocalizations.of(context)!.healthCalculatedFromComponents;
    }

    // Find the weakest component
    final weakestEntry = healthResult.componentScores.entries
        .reduce((a, b) => a.value < b.value ? a : b);

    return '${AppLocalizations.of(context)!.weakest}: ${_translateComponentName(weakestEntry.key, context)} ${weakestEntry.value}/100';
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
    final overallTrend = _calculateOverallTrend(trendData, context);

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
                        AppLocalizations.of(context)!.financialHealthTrend,
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
                              '${healthResult.grade.name} • ${_getGradeText(healthResult.grade, context)}',
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
                    AppLocalizations.of(context)!.keyInsights,
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
    BuildContext context,
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
      trendText =
          '+$delta ${AppLocalizations.of(context)!.pts} ($percentChange%)';
      insights = [
        AppLocalizations.of(context)!.strongUpwardTrend,
        if (avgVolatility < 3)
          AppLocalizations.of(context)!.consistentImprovementPattern,
        if (lastScore >= 70)
          AppLocalizations.of(context)!.approachingExcellentHealth,
      ];
    } else if (delta >= 2) {
      trendColor = Colors.lightGreen.shade600;
      trendIcon = Icons.keyboard_arrow_up;
      trendText =
          '+$delta ${AppLocalizations.of(context)!.pts} ($percentChange%)';
      insights = [
        AppLocalizations.of(context)!.gradualImprovementTrend,
        if (avgVolatility < 4)
          AppLocalizations.of(context)!.steadyProgressPattern,
      ];
    } else if (delta <= -5) {
      trendColor = Colors.red.shade600;
      trendIcon = Icons.trending_down;
      trendText =
          '$delta ${AppLocalizations.of(context)!.pts} ($percentChange%)';
      insights = [
        AppLocalizations.of(context)!.decliningTrendNeedsAttention,
        if (avgVolatility > 5)
          AppLocalizations.of(context)!.highVolatilityInScores,
        AppLocalizations.of(context)!.considerReviewingStrategy,
      ];
    } else if (delta <= -2) {
      trendColor = Colors.orange.shade600;
      trendIcon = Icons.keyboard_arrow_down;
      trendText =
          '$delta ${AppLocalizations.of(context)!.pts} ($percentChange%)';
      insights = [
        AppLocalizations.of(context)!.slightDownwardTrend,
        AppLocalizations.of(context)!.monitorForContinuedDecline,
      ];
    } else {
      trendColor = Colors.blue.shade600;
      trendIcon = Icons.horizontal_rule;
      trendText =
          '${AppLocalizations.of(context)!.stable} ($delta${AppLocalizations.of(context)!.pts})';
      insights = [
        AppLocalizations.of(context)!.stableFinancialHealthScore,
        if (avgVolatility < 2)
          AppLocalizations.of(context)!.lowVolatilityIndicatesConsistency,
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

  String _getGradeText(HealthGrade grade, BuildContext context) {
    switch (grade) {
      case HealthGrade.A:
        return AppLocalizations.of(context)!.excellentHealth;
      case HealthGrade.B:
        return AppLocalizations.of(context)!.goodHealth;
      case HealthGrade.C:
        return AppLocalizations.of(context)!.fairHealth;
      case HealthGrade.D:
        return AppLocalizations.of(context)!.needsWorkHealth;
      case HealthGrade.F:
        return AppLocalizations.of(context)!.poorHealth;
    }
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
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
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
