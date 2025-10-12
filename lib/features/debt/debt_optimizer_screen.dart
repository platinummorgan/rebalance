import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../routes.dart' show AppRouter;

/// Debt payoff optimizer - calculates avalanche/snowball strategies
/// and shows potential interest savings with Pro upgrade.
class DebtOptimizerScreen extends ConsumerStatefulWidget {
  const DebtOptimizerScreen({super.key});

  @override
  ConsumerState<DebtOptimizerScreen> createState() =>
      _DebtOptimizerScreenState();
}

class _DebtOptimizerScreenState extends ConsumerState<DebtOptimizerScreen> {
  double _extraPayment = 0.0;
  String? _activeStrategy; // user-selected strategy; defaults to recommended

  // Helper to format currency with commas
  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }

  // Helper to calculate payoff date from month number
  String _getPayoffDate(int monthsFromNow) {
    final now = DateTime.now();
    final payoffDate = DateTime(now.year, now.month + monthsFromNow, 1);
    return DateFormat('MMM yyyy').format(payoffDate);
  }

  @override
  Widget build(BuildContext context) {
    final liabilitiesAsync = ref.watch(liabilitiesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return liabilitiesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Debt Optimizer')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Debt Optimizer')),
        body: Center(child: Text('Error: $error')),
      ),
      data: (liabilities) => settingsAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Debt Optimizer')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Debt Optimizer')),
          body: Center(child: Text('Error: $error')),
        ),
        data: (settings) => _buildContent(context, liabilities, settings),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Liability> liabilities,
    Settings settings,
  ) {
    // Pro gate - redirect non-Pro users to upgrade screen
    if (!settings.isPro) {
      return _buildProGate(context);
    }

    if (liabilities.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Debt Optimizer'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'No debts to optimize!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add liabilities from the Liabilities tab to use this tool.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final totalDebt = liabilities.fold(0.0, (sum, l) => sum + l.balance);
    final totalMinPayment =
        liabilities.fold(0.0, (sum, l) => sum + l.minPayment);

    // Calculate both strategies
    final avalancheResult = _calculatePayoffStrategy(
      liabilities,
      _extraPayment,
      strategy: 'avalanche',
    );
    final snowballResult = _calculatePayoffStrategy(
      liabilities,
      _extraPayment,
      strategy: 'snowball',
    );

    // Determine which strategy is better
    final betterStrategy =
        avalancheResult.totalInterest <= snowballResult.totalInterest
            ? 'avalanche'
            : 'snowball';
    final betterResult =
        betterStrategy == 'avalanche' ? avalancheResult : snowballResult;
    _activeStrategy ??= betterStrategy;
    final selectedResult =
        _activeStrategy == 'avalanche' ? avalancheResult : snowballResult;
    final interestDiff =
        (avalancheResult.totalInterest - snowballResult.totalInterest).abs();
    final monthsDiff =
        (avalancheResult.monthsToPayoff - snowballResult.monthsToPayoff).abs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Optimizer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current debt overview
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 20,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current Debt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                          .format(totalDebt),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${liabilities.length} ${liabilities.length == 1 ? 'liability' : 'liabilities'} • ${_formatCurrency(totalMinPayment)}/mo minimum',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Extra payment slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Extra Monthly Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                              .format(_extraPayment),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _extraPayment,
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      label: _formatCurrency(_extraPayment),
                      onChanged: (value) {
                        setState(() {
                          _extraPayment = value;
                        });
                      },
                    ),
                    Text(
                      'Total monthly payment: ${_formatCurrency(totalMinPayment + _extraPayment)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Strategy comparison with toggle
            Row(
              children: [
                const Text(
                  'Payoff Strategies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildStrategyToggle(context, betterStrategy),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'We recommend the option with lower total interest. You can still select the other for motivation wins.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (interestDiff > 0)
              _buildComparisonSummaryCard(
                context,
                avalanche: avalancheResult,
                snowball: snowballResult,
                better: betterStrategy,
                interestDiff: interestDiff,
                monthsDiff: monthsDiff,
              ),
            if (interestDiff > 0) const SizedBox(height: 16),

            // Avalanche card
            _buildStrategyCard(
              context,
              title:
                  'Avalanche${betterStrategy == 'avalanche' ? ' (Recommended)' : ''}',
              subtitle: 'Highest APR first – minimizes total interest',
              result: avalancheResult,
              isRecommended: betterStrategy == 'avalanche',
              isSelected: _activeStrategy == 'avalanche',
              onSelect: () => setState(() => _activeStrategy = 'avalanche'),
              icon: Icons.trending_down,
            ),

            const SizedBox(height: 12),

            // Snowball card
            _buildStrategyCard(
              context,
              title:
                  'Snowball${betterStrategy == 'snowball' ? ' (Recommended)' : ''}',
              subtitle: 'Smallest balance first – faster psychological wins',
              result: snowballResult,
              isRecommended: betterStrategy == 'snowball',
              isSelected: _activeStrategy == 'snowball',
              onSelect: () => setState(() => _activeStrategy = 'snowball'),
              icon: Icons.auto_awesome,
            ),

            const SizedBox(height: 24),

            // Pro upsell card
            if (!settings.isPro) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock Detailed Payoff Schedule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Get month-by-month payment breakdown showing:',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProFeature('Exact payoff date for each debt'),
                      _buildProFeature('Principal vs interest breakdown'),
                      _buildProFeature('Remaining balance tracking'),
                      _buildProFeature(
                        'Total interest saved: ${_formatCurrency(betterResult.interestSavingsVsMinimum)}',
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            // Navigate to Pro screen
                            Navigator.pushNamed(context, '/pro');
                          },
                          child: const Text('Upgrade to Pro'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Show debt payoff order
              const Text(
                'Debt Payoff Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Debts will be paid off in this order (${_activeStrategy!.toUpperCase()} strategy):',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildDebtPayoffOrder(context, selectedResult),
              const SizedBox(height: 24),

              // Show detailed schedule for Pro users
              const Text(
                'Payment Schedule',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Month-by-month breakdown (${_activeStrategy!.toUpperCase()} strategy):',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildPayoffSchedule(context, selectedResult),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebtPayoffOrder(BuildContext context, PayoffResult result) {
    if (result.debtPayoffOrder.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sort by priority order so the list matches the strategy
            ...(result.debtPayoffOrder.toList()
                  ..sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder)))
                .map((debt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${debt.priorityOrder}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.debtName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatCurrency(debt.balance)} at ${(debt.apr * 100).toStringAsFixed(1)}% APR',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Paid off',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _getPayoffDate(debt.payoffMonth),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${debt.payoffMonth} mo',
                            style: TextStyle(
                              fontSize: 10,
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
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required PayoffResult result,
    required bool isRecommended,
    required IconData icon,
    bool isSelected = false,
    VoidCallback? onSelect,
  }) {
    return Card(
      color: isRecommended
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isRecommended
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isRecommended
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'BEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                          if (isSelected && !isRecommended) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'SELECTED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isRecommended
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onSelect != null)
                  IconButton(
                    tooltip: 'Select strategy',
                    icon: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onSelect,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payoff Time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.monthsToPayoff} months',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRecommended
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Interest',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                          .format(result.totalInterest),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRecommended
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (result.interestSavingsVsMinimum > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Save ${_formatCurrency(result.interestSavingsVsMinimum)} vs minimum payments',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoffSchedule(BuildContext context, PayoffResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Payment Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.schedule.length > 12
                  ? 12
                  : result.schedule.length, // Show first 12 months
              itemBuilder: (context, index) {
                final month = result.schedule[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Month ${month.month}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatCurrency(month.totalPayment),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_formatCurrency(month.principalPayment)} principal • ${_formatCurrency(month.interestPayment)} interest',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Remaining: ${_formatCurrency(month.remainingBalance)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: month.remainingBalance == 0
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            if (result.schedule.length > 12) ...[
              const SizedBox(height: 8),
              Text(
                '... ${result.schedule.length - 12} more months',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Calculates debt payoff strategy (avalanche or snowball)
  PayoffResult _calculatePayoffStrategy(
    List<Liability> liabilities,
    double extraPayment, {
    required String strategy,
  }) {
    // Create mutable copy of liabilities with balances
    final debts = liabilities
        .map(
          (l) => _DebtSnapshot(
            name: l.name,
            balance: l.balance,
            apr: l.apr,
            minPayment: l.minPayment,
          ),
        )
        .toList();

    // Store initial balances for debt payoff info
    final initialDebts = debts
        .map((d) => {
              'name': d.name,
              'balance': d.balance,
              'apr': d.apr,
            },)
        .toList();

    // Sort based on strategy
    if (strategy == 'avalanche') {
      debts.sort((a, b) => b.apr.compareTo(a.apr)); // Highest APR first
    } else {
      debts.sort(
        (a, b) => a.balance.compareTo(b.balance),
      ); // Smallest balance first
    }

    final totalMinPayment = debts.fold(0.0, (sum, d) => sum + d.minPayment);
    final totalMonthlyPayment = totalMinPayment + extraPayment;

    double totalInterest = 0.0;
    int months = 0;
    final schedule = <MonthlyPayment>[];
    final debtPayoffOrder = <DebtPayoffInfo>[];
    final paidOffDebts = <String>{};

    // Simulate month-by-month payoff
    while (debts.any((d) => d.balance > 0) && months < 600) {
      // Safety limit: 50 years
      months++;
      double remainingPayment = totalMonthlyPayment;
      double monthInterest = 0.0;
      double monthPrincipal = 0.0;

      // Pay minimum on all debts first
      for (final debt in debts) {
        if (debt.balance <= 0) continue;

        final monthlyRate = debt.apr / 12;
        final interest = debt.balance * monthlyRate;
        monthInterest += interest;

        final minPayment = debt.minPayment < debt.balance + interest
            ? debt.minPayment
            : debt.balance + interest;
        final principal = minPayment - interest;

        debt.balance -= principal;
        monthPrincipal += principal;
        remainingPayment -= minPayment;

        if (debt.balance < 0) debt.balance = 0;
      }

      // Apply extra payment to highest priority debt
      if (remainingPayment > 0) {
        for (final debt in debts) {
          if (debt.balance <= 0) continue;

          final extraPrincipal =
              remainingPayment < debt.balance ? remainingPayment : debt.balance;
          debt.balance -= extraPrincipal;
          monthPrincipal += extraPrincipal;
          remainingPayment -= extraPrincipal;

          if (debt.balance < 0) debt.balance = 0;

          break; // Only pay extra on one debt per month
        }
      }

      // Track when debts get paid off
      for (var i = 0; i < debts.length; i++) {
        final debt = debts[i];
        if (debt.balance == 0 && !paidOffDebts.contains(debt.name)) {
          paidOffDebts.add(debt.name);
          final initialDebt =
              initialDebts[liabilities.indexWhere((l) => l.name == debt.name)];
          debtPayoffOrder.add(
            DebtPayoffInfo(
              debtName: debt.name,
              balance: initialDebt['balance'] as double,
              apr: initialDebt['apr'] as double,
              payoffMonth: months,
              priorityOrder: i + 1,
            ),
          );
        }
      }

      totalInterest += monthInterest;

      // Calculate total remaining balance across all debts
      final totalRemainingBalance =
          debts.fold(0.0, (sum, d) => sum + d.balance);

      schedule.add(
        MonthlyPayment(
          month: months,
          totalPayment: totalMonthlyPayment,
          principalPayment: monthPrincipal,
          interestPayment: monthInterest,
          remainingBalance: totalRemainingBalance,
        ),
      );
    }

    // Calculate interest savings vs minimum payments only
    final minimumOnlyResult = _calculateMinimumPaymentOnly(liabilities);

    return PayoffResult(
      monthsToPayoff: months,
      totalInterest: totalInterest,
      interestSavingsVsMinimum: minimumOnlyResult.totalInterest - totalInterest,
      schedule: schedule,
      debtPayoffOrder: debtPayoffOrder,
    );
  }

  /// Calculates payoff with minimum payments only (baseline)
  PayoffResult _calculateMinimumPaymentOnly(List<Liability> liabilities) {
    final debts = liabilities
        .map(
          (l) => _DebtSnapshot(
            name: l.name,
            balance: l.balance,
            apr: l.apr,
            minPayment: l.minPayment,
          ),
        )
        .toList();

    double totalInterest = 0.0;
    int months = 0;

    while (debts.any((d) => d.balance > 0) && months < 600) {
      months++;

      for (final debt in debts) {
        if (debt.balance <= 0) continue;

        final monthlyRate = debt.apr / 12;
        final interest = debt.balance * monthlyRate;
        totalInterest += interest;

        final minPayment = debt.minPayment < debt.balance + interest
            ? debt.minPayment
            : debt.balance + interest;
        final principal = minPayment - interest;

        debt.balance -= principal;
        if (debt.balance < 0) debt.balance = 0;
      }
    }

    return PayoffResult(
      monthsToPayoff: months,
      totalInterest: totalInterest,
      interestSavingsVsMinimum: 0,
      schedule: [],
      debtPayoffOrder: [], // No order needed for baseline calculation
    );
  }

  Widget _buildStrategyToggle(BuildContext context, String recommended) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleChip(context, 'Avalanche', 'avalanche', recommended),
          _buildToggleChip(context, 'Snowball', 'snowball', recommended),
        ],
      ),
    );
  }

  Widget _buildToggleChip(
    BuildContext context,
    String label,
    String value,
    String recommended,
  ) {
    final selected = _activeStrategy == value;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => _activeStrategy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            if (recommended == value)
              Icon(
                Icons.star,
                size: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            if (recommended == value) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonSummaryCard(
    BuildContext context, {
    required PayoffResult avalanche,
    required PayoffResult snowball,
    required String better,
    required double interestDiff,
    required int monthsDiff,
  }) {
    final betterLabel = better == 'avalanche' ? 'Avalanche' : 'Snowball';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Strategy Comparison',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$betterLabel saves ${_formatCurrency(interestDiff)} more interest${monthsDiff > 0 ? ' and finishes $monthsDiff month${monthsDiff == 1 ? '' : 's'} sooner' : ''} vs the other approach.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProGate(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Optimizer'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 72,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Unlock Debt Payoff Optimizer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Find the fastest path to debt freedom',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProFeatureItem(
                      'Compare avalanche vs snowball strategies',
                    ),
                    const SizedBox(height: 8),
                    _buildProFeatureItem(
                      'See exact payoff dates for each debt',
                    ),
                    const SizedBox(height: 8),
                    _buildProFeatureItem('Calculate total interest savings'),
                    const SizedBox(height: 8),
                    _buildProFeatureItem('Get month-by-month payment schedule'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(AppRouter.pro);
                },
                icon: const Icon(Icons.star),
                label: const Text('Upgrade to Pro'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProFeatureItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle,
          size: 20,
          color: Colors.green.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

/// Mutable snapshot of a debt for simulation
class _DebtSnapshot {
  final String name;
  double balance;
  final double apr;
  final double minPayment;

  _DebtSnapshot({
    required this.name,
    required this.balance,
    required this.apr,
    required this.minPayment,
  });
}

/// Result of debt payoff calculation
class PayoffResult {
  final int monthsToPayoff;
  final double totalInterest;
  final double interestSavingsVsMinimum;
  final List<MonthlyPayment> schedule;
  final List<DebtPayoffInfo> debtPayoffOrder;

  PayoffResult({
    required this.monthsToPayoff,
    required this.totalInterest,
    required this.interestSavingsVsMinimum,
    required this.schedule,
    required this.debtPayoffOrder,
  });
}

/// Information about when a specific debt gets paid off
class DebtPayoffInfo {
  final String debtName;
  final double balance;
  final double apr;
  final int payoffMonth;
  final int priorityOrder; // 1 = highest priority

  DebtPayoffInfo({
    required this.debtName,
    required this.balance,
    required this.apr,
    required this.payoffMonth,
    required this.priorityOrder,
  });
}

/// Single month in payment schedule
class MonthlyPayment {
  final int month;
  final double totalPayment;
  final double principalPayment;
  final double interestPayment;
  final double remainingBalance;

  MonthlyPayment({
    required this.month,
    required this.totalPayment,
    required this.principalPayment,
    required this.interestPayment,
    required this.remainingBalance,
  });
}
