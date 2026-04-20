import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../widgets/currency_text.dart';
import '../../utils/currency_formatter.dart';
import '../../services/workflow_impact_service.dart';
import '../pro/pro_screen.dart';
import '../../generated/app_localizations.dart';

/// Interactive Pro-only rebalancing plan builder with customization and tracking
class RebalancingPlanScreen extends ConsumerStatefulWidget {
  final String? initialStrategy;
  final int? initialGlideMonths;
  final double? suggestedMoveAmount;
  final String? presetSource;

  const RebalancingPlanScreen({
    super.key,
    this.initialStrategy,
    this.initialGlideMonths,
    this.suggestedMoveAmount,
    this.presetSource,
  });

  @override
  ConsumerState<RebalancingPlanScreen> createState() =>
      _RebalancingPlanScreenState();
}

class _RebalancingPlanScreenState extends ConsumerState<RebalancingPlanScreen> {
  // User-customizable settings
  int _glideLengthMonths = 6; // 3, 6, or 12 months
  String _strategy = 'dollar-cost'; // 'dollar-cost' or 'immediate'

  // Execution tracking
  final Map<int, bool> _monthlyChecklist = {};

  @override
  void initState() {
    super.initState();
    final strategy = widget.initialStrategy;
    if (strategy == 'dollar-cost' || strategy == 'immediate') {
      _strategy = strategy!;
    }

    final glide = widget.initialGlideMonths;
    if (glide != null && (glide == 3 || glide == 6 || glide == 12)) {
      _glideLengthMonths = glide;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final accountsAsync = ref.watch(accountsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.rebalancingPlan),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showRebalancingGuide(context),
            tooltip: loc.rebalancingGuide,
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
              Text('Error loading data: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: Text(loc.goBack),
              ),
            ],
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return _buildEmptyState(context);
          }

          return settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (settings) {
              // Check Pro status
              if (!settings.isPro) {
                return _buildProUpgradePrompt(context);
              }

              // Calculate rebalancing needs
              final rebalancingData =
                  _calculateRebalancing(accounts, settings, context);

              if (!rebalancingData['needsRebalancing']) {
                return _buildNoRebalancingNeeded(context);
              }

              return _buildInteractivePlan(context, rebalancingData, settings);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              loc.noAccountsYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.addAccountsForRebalancing,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/accounts/add'),
              icon: const Icon(Icons.add),
              label: Text(loc.addAccount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProUpgradePrompt(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 80,
              color: Colors.amber.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              loc.proFeature,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.rebalancingPlanProDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => const ProScreen(),
                ),
              ),
              icon: const Icon(Icons.star),
              label: Text(loc.upgradeToProTitle),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(loc.goBack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRebalancingNeeded(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 24),
            Text(
              loc.youreWellBalanced,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.noRebalancingNeeded,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: Text(loc.backToDashboard),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractivePlan(
    BuildContext context,
    Map<String, dynamic> data,
    Settings settings,
  ) {
    final loc = AppLocalizations.of(context)!;
    final totalToMove = data['totalToMove'] as double;
    final perMonth = (_strategy == 'immediate')
        ? totalToMove
        : totalToMove / _glideLengthMonths;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.presetSource == 'command_center' &&
              widget.suggestedMoveAmount != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Command Center context: move about ${CurrencyFormatter.format(widget.suggestedMoveAmount!, settings.currency)} toward target allocation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _logCommandCenterImpact(
                            data: data,
                          ),
                          icon: const Icon(Icons.insights_rounded, size: 16),
                          label: const Text('Log impact'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.yourPersonalizedPlan,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.customizeTrackExecute,
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Locked Accounts Warning (if applicable)
          if (data['hasLockedAccounts'] == true) ...[
            _buildLockedAccountsWarning(context, data),
            const SizedBox(height: 24),
          ],

          // Strategy Selector
          _buildStrategySelector(context),

          const SizedBox(height: 24),

          // Glide Path Customizer (only for dollar-cost averaging)
          if (_strategy == 'dollar-cost') ...[
            _buildGlidePathCustomizer(context),
            const SizedBox(height: 24),
          ],

          // Summary Card
          _buildSummaryCard(context, perMonth, totalToMove, data),

          const SizedBox(height: 24),

          // Comparison: Before vs After
          _buildBeforeAfterComparison(context, data),

          const SizedBox(height: 24),

          // Execution Checklist
          if (_strategy == 'dollar-cost')
            _buildExecutionChecklist(context, perMonth, data),

          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(context, data),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLockedAccountsWarning(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final loc = AppLocalizations.of(context)!;
    final lockedAssets = data['lockedAssets'] as double;
    final unlockedAssets = data['unlockedAssets'] as double;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.lock,
              color: Colors.blue.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.lockedAccountsDetected,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          children: [
                            CurrencyText(
                              lockedAssets,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              ' ${loc.lockedAccountsMessage} ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            CurrencyText(
                              unlockedAssets,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              ' ${loc.inUnlockedAccounts}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (unlockedAssets == 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      loc.lockedAccountsTip,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySelector(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.rebalancingStrategy,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            RadioGroup<String>(
              groupValue: _strategy,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _strategy = value);
                }
              },
              child: Column(
                children: [
                  // Dollar-Cost Averaging Option
                  InkWell(
                    onTap: () => setState(() => _strategy = 'dollar-cost'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _strategy == 'dollar-cost'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: _strategy == 'dollar-cost' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _strategy == 'dollar-cost'
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3)
                            : null,
                      ),
                      child: Row(
                        children: [
                          const Radio<String>(value: 'dollar-cost'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.dollarCostAverageRecommended,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.dollarCostDescription,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Immediate Rebalance Option
                  InkWell(
                    onTap: () => setState(() => _strategy = 'immediate'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _strategy == 'immediate'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: _strategy == 'immediate' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _strategy == 'immediate'
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.3)
                            : null,
                      ),
                      child: Row(
                        children: [
                          const Radio<String>(value: 'immediate'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.immediateRebalance,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loc.immediateRebalanceDescription,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 14,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlidePathCustomizer(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.glidePathDuration,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.howManyMonthsToSpread,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildGlideOption(context, 3, loc.fast),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlideOption(context, 6, loc.balanced),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlideOption(context, 12, loc.gradual),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlideOption(BuildContext context, int months, String label) {
    final loc = AppLocalizations.of(context)!;
    final isSelected = _glideLengthMonths == months;

    return InkWell(
      onTap: () => setState(() => _glideLengthMonths = months),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : null,
        ),
        child: Column(
          children: [
            Text(
              '$months',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              loc.months,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double perMonth,
    double totalToMove,
    Map<String, dynamic> data,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_strategy == 'immediate') ...[
              Text(
                loc.executeNow,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              CurrencyText(
                totalToMove,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                loc.totalToRebalanceImmediately,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.8),
                ),
              ),
            ] else ...[
              Text(
                loc.monthlyTransferAmount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CurrencyText(
                    perMonth,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    '/mo',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${loc.overMonths} $_glideLengthMonths ${loc.months} • ${loc.total}: ',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  CurrencyText(
                    totalToMove,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Breakdown
            ...((data['movements'] as List<Map<String, dynamic>>).map((m) {
              final amount = (_strategy == 'immediate')
                  ? m['amount'] as double
                  : (m['amount'] as double) / _glideLengthMonths;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: m['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: CurrencyText(
                              amount,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          Text(
                            '${_strategy == 'dollar-cost' ? '/mo' : ''} → ${m['destination']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildBeforeAfterComparison(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.beforeVsAfter,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.current,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...((data['before'] as Map<String, double>)
                          .entries
                          .map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '${e.value.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.target,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...((data['after'] as Map<String, double>)
                          .entries
                          .map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '${e.value.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionChecklist(
    BuildContext context,
    double perMonth,
    Map<String, dynamic> data,
  ) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.executionChecklist,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.trackMonthlyProgress,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_glideLengthMonths, (index) {
              final monthNum = index + 1;
              final date = DateTime.now().add(Duration(days: 30 * monthNum));
              final isChecked = _monthlyChecklist[monthNum] ?? false;

              return CheckboxListTile(
                value: isChecked,
                onChanged: (value) {
                  setState(() {
                    _monthlyChecklist[monthNum] = value ?? false;
                  });
                },
                title: Text(
                  '${loc.month} $monthNum: ${DateFormat('MMM yyyy').format(date)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Text(
                      '${loc.transfer} ',
                      style: TextStyle(
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    CurrencyText(
                      perMonth,
                      style: TextStyle(
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    final loc = AppLocalizations.of(context)!;
    final completedMonths = _monthlyChecklist.values.where((v) => v).length;
    final progress =
        _strategy == 'dollar-cost' ? completedMonths / _glideLengthMonths : 0.0;

    return Column(
      children: [
        if (_strategy == 'dollar-cost' && completedMonths > 0) ...[
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '$completedMonths ${loc.ofMonthsCompleted} $_glideLengthMonths ${loc.monthsCompleted}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
        ],
        FilledButton.icon(
          onPressed: () => _exportToPDF(context, data),
          icon: const Icon(Icons.download),
          label: Text(loc.exportPDF),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateRebalancing(
    List<Account> accounts,
    Settings settings,
    BuildContext context,
  ) {
    final loc = AppLocalizations.of(context)!;
    // Separate locked and unlocked accounts
    final unlockedAccounts = accounts.where((a) => !a.isLocked).toList();
    final lockedAccounts = accounts.where((a) => a.isLocked).toList();

    // Calculate total assets (for overall view)
    final totalAssets = accounts.fold<double>(
      0.0,
      (sum, account) => sum + account.balance,
    );

    // Calculate unlocked assets (for actionable rebalancing)
    final unlockedAssets = unlockedAccounts.fold<double>(
      0.0,
      (sum, account) => sum + account.balance,
    );

    final lockedAssets = lockedAccounts.fold<double>(
      0.0,
      (sum, account) => sum + account.balance,
    );

    // Calculate current allocation (overall portfolio view)
    double usEquity = 0.0;
    double bonds = 0.0;
    double intlEquity = 0.0;
    double cash = 0.0;

    for (final account in accounts) {
      usEquity += account.balance * (account.pctUsEq as num).toDouble();
      bonds += account.balance * (account.pctBonds as num).toDouble();
      intlEquity += account.balance * (account.pctIntlEq as num).toDouble();
      cash += account.balance * (account.pctCash as num).toDouble();
    }

    final currentUSPct = totalAssets > 0 ? (usEquity / totalAssets) * 100 : 0.0;
    final currentBondsPct = totalAssets > 0 ? (bonds / totalAssets) * 100 : 0.0;
    final currentIntlPct =
        totalAssets > 0 ? (intlEquity / totalAssets) * 100 : 0.0;
    final currentCashPct = totalAssets > 0 ? (cash / totalAssets) * 100 : 0.0;

    // Target allocation
    final targetUSPct = settings.usEquityTargetPct;
    const targetBondsPct = 35.0;
    const targetIntlPct = 20.0;
    const targetCashPct = 5.0;

    // Check if rebalancing is needed (5% drift threshold)
    final needsRebalancing = (currentUSPct - targetUSPct).abs() > 5.0 ||
        (currentBondsPct - targetBondsPct).abs() > 5.0 ||
        (currentIntlPct - targetIntlPct).abs() > 5.0;

    if (!needsRebalancing) {
      return {'needsRebalancing': false};
    }

    // Calculate movements ONLY from unlocked accounts
    final bondsDiff = (targetBondsPct - currentBondsPct) / 100 * unlockedAssets;
    final intlDiff = (targetIntlPct - currentIntlPct) / 100 * unlockedAssets;

    final movements = <Map<String, dynamic>>[];

    if (bondsDiff > 0) {
      movements.add({
        'destination': AppLocalizations.of(context)!.bonds,
        'amount': bondsDiff,
        'color': Colors.blue,
      });
    }

    if (intlDiff > 0) {
      movements.add({
        'destination': AppLocalizations.of(context)!.internationalEquity,
        'amount': intlDiff,
        'color': Colors.purple,
      });
    }

    final totalToMove = movements.fold<double>(
      0.0,
      (sum, m) => sum + (m['amount'] as double),
    );

    return {
      'needsRebalancing': true,
      'totalToMove': totalToMove,
      'movements': movements,
      'hasLockedAccounts': lockedAssets > 0,
      'lockedAssets': lockedAssets,
      'unlockedAssets': unlockedAssets,
      'before': {
        loc.usEquity: currentUSPct,
        loc.bonds: currentBondsPct,
        loc.internationalEquity: currentIntlPct,
        loc.cash: currentCashPct,
      },
      'after': {
        loc.usEquity: targetUSPct,
        loc.bonds: targetBondsPct,
        loc.internationalEquity: targetIntlPct,
        loc.cash: targetCashPct,
      },
    };
  }

  void _exportToPDF(BuildContext context, Map<String, dynamic> data) {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.pdfExportComingSoon),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logCommandCenterImpact({
    required Map<String, dynamic> data,
  }) async {
    final outcomeMetrics = await WorkflowImpactService.captureCurrentMetrics();
    final completed = await WorkflowImpactService.completeLatestPendingWorkflow(
      workflowId: WorkflowImpactService.workflowRebalanceLift,
      outcomeMetrics: outcomeMetrics,
      expectedMetrics: {
        'strategy': _strategy == 'immediate' ? 1.0 : 2.0, // 1 immediate, 2 DCA
        'glideMonths': _glideLengthMonths.toDouble(),
        'totalToMove': (data['totalToMove'] as num?)?.toDouble() ?? 0.0,
        'maxAllocationDriftPct': _maxAllocationDrift(data),
      },
      note:
          'Rebalance Lift plan logged with ${_strategy == 'immediate' ? 'immediate' : 'dollar-cost'} strategy.',
    );
    if (!mounted) return;

    ref.invalidate(workflowImpactLogsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          completed
              ? 'Impact loop updated for Rebalance Lift.'
              : 'No pending Rebalance Lift run found. Run from Command Center first.',
        ),
      ),
    );
  }

  double _maxAllocationDrift(Map<String, dynamic> data) {
    final before = data['before'];
    final after = data['after'];
    if (before is! Map || after is! Map) return 0.0;

    var maxDrift = 0.0;
    for (final entry in before.entries) {
      final key = entry.key;
      final beforeValue = (entry.value as num?)?.toDouble();
      final afterValue = (after[key] as num?)?.toDouble();
      if (beforeValue == null || afterValue == null) continue;
      final drift = (beforeValue - afterValue).abs();
      if (drift > maxDrift) {
        maxDrift = drift;
      }
    }
    return maxDrift;
  }

  void _showRebalancingGuide(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, size: 24),
            const SizedBox(width: 12),
            Text(loc.rebalancingGuide),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.whyRebalance,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                loc.whyRebalanceDescription,
              ),
              const SizedBox(height: 16),
              Text(
                loc.dollarCostAveragingTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                loc.dollarCostAveragingDescription,
              ),
              const SizedBox(height: 16),
              Text(
                loc.immediateRebalancingTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                loc.immediateRebalancingDescription,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.gotIt),
          ),
        ],
      ),
    );
  }
}
