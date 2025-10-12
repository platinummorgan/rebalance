import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../app.dart';

/// Interactive Pro-only rebalancing plan builder with customization and tracking
class RebalancingPlanScreen extends ConsumerStatefulWidget {
  const RebalancingPlanScreen({super.key});

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
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rebalancing Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showRebalancingGuide(context),
            tooltip: 'Rebalancing Guide',
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
                child: const Text('Go Back'),
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
              final rebalancingData = _calculateRebalancing(accounts, settings);

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
              'No Accounts Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your investment accounts to generate a personalized rebalancing plan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/accounts/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProUpgradePrompt(BuildContext context) {
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
              'Pro Feature',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Interactive rebalancing plans with customizable strategies, execution tracking, and PDF export.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/pro'),
              icon: const Icon(Icons.star),
              label: const Text('Upgrade to Pro'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade600,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRebalancingNeeded(BuildContext context) {
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
              'You\'re Well Balanced!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your portfolio is within target ranges. No rebalancing needed at this time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Dashboard'),
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
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final totalToMove = data['totalToMove'] as double;
    final perMonth = (_strategy == 'immediate')
        ? totalToMove
        : totalToMove / _glideLengthMonths;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                              'Your Personalized Plan',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize, track, and execute',
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
          _buildSummaryCard(context, formatter, perMonth, totalToMove, data),

          const SizedBox(height: 24),

          // Comparison: Before vs After
          _buildBeforeAfterComparison(context, data),

          const SizedBox(height: 24),

          // Execution Checklist
          if (_strategy == 'dollar-cost')
            _buildExecutionChecklist(context, formatter, perMonth, data),

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
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
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
                    'Locked Accounts Detected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatter.format(lockedAssets)} in retirement/locked accounts can\'t be moved. Plan shows only actionable moves from your ${formatter.format(unlockedAssets)} in unlocked accounts.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  if (unlockedAssets == 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '💡 Tip: Consider adjusting future 401(k) contributions to bonds/international funds.',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rebalancing Strategy',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

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
                    Radio<String>(
                      value: 'dollar-cost',
                      groupValue: _strategy,
                      onChanged: (value) => setState(() => _strategy = value!),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dollar-Cost Average (Recommended)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Spread rebalancing over multiple months to reduce timing risk',
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
                    Radio<String>(
                      value: 'immediate',
                      groupValue: _strategy,
                      onChanged: (value) => setState(() => _strategy = value!),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Immediate Rebalance',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Execute the full rebalancing in one transaction',
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
    );
  }

  Widget _buildGlidePathCustomizer(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Glide Path Duration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'How many months to spread the rebalancing over?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildGlideOption(context, 3, 'Fast'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlideOption(context, 6, 'Balanced'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGlideOption(context, 12, 'Gradual'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlideOption(BuildContext context, int months, String label) {
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
              'months',
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
    NumberFormat formatter,
    double perMonth,
    double totalToMove,
    Map<String, dynamic> data,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_strategy == 'immediate') ...[
              Text(
                'Execute Now',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                formatter.format(totalToMove),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total to rebalance immediately',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.8),
                ),
              ),
            ] else ...[
              Text(
                'Monthly Transfer Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '${formatter.format(perMonth)}/mo',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Over $_glideLengthMonths months • Total: ${formatter.format(totalToMove)}',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.8),
                ),
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
                      child: Text(
                        '${formatter.format(amount)}${_strategy == 'dollar-cost' ? '/mo' : ''} → ${m['destination']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Before vs After',
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
                        'Current',
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
                        'Target',
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
    NumberFormat formatter,
    double perMonth,
    Map<String, dynamic> data,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execution Checklist',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your monthly progress',
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
                  'Month $monthNum: ${DateFormat('MMM yyyy').format(date)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  'Transfer ${formatter.format(perMonth)}',
                  style: TextStyle(
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
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
            '$completedMonths of $_glideLengthMonths months completed',
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
          label: const Text('Export PDF'),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateRebalancing(
    List<Account> accounts,
    Settings settings,
  ) {
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
        'destination': 'Bonds',
        'amount': bondsDiff,
        'color': Colors.blue,
      });
    }

    if (intlDiff > 0) {
      movements.add({
        'destination': 'International Equity',
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
        'US Equity': currentUSPct,
        'Bonds': currentBondsPct,
        'Intl Equity': currentIntlPct,
        'Cash': currentCashPct,
      },
      'after': {
        'US Equity': targetUSPct,
        'Bonds': targetBondsPct,
        'Intl Equity': targetIntlPct,
        'Cash': targetCashPct,
      },
    };
  }

  void _exportToPDF(BuildContext context, Map<String, dynamic> data) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📄 PDF export coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRebalancingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, size: 24),
            SizedBox(width: 12),
            Text('Rebalancing Guide'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why Rebalance?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Over time, some investments grow faster than others, causing your portfolio to drift from your target allocation. Rebalancing brings it back in line.',
              ),
              SizedBox(height: 16),
              Text(
                'Dollar-Cost Averaging',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Spreading rebalancing over multiple months reduces timing risk and can result in better average prices.',
              ),
              SizedBox(height: 16),
              Text(
                'Immediate Rebalancing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Execute the full rebalancing in one transaction. Faster but exposes you to current market timing.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
