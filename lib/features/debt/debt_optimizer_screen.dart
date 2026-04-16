import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../routes.dart' show AppRouter;
import '../../utils/currency_formatter.dart';
import '../../services/exchange_rate_service.dart';
import '../../generated/app_localizations.dart';

/// Debt payoff optimizer - calculates avalanche/snowball strategies
/// and shows potential interest savings with Pro upgrade.
class DebtOptimizerScreen extends ConsumerStatefulWidget {
  final double? initialExtraPayment;
  final String? initialStrategy;
  final String? presetSource;

  const DebtOptimizerScreen({
    super.key,
    this.initialExtraPayment,
    this.initialStrategy,
    this.presetSource,
  });

  @override
  ConsumerState<DebtOptimizerScreen> createState() =>
      _DebtOptimizerScreenState();
}

class _DebtOptimizerScreenState extends ConsumerState<DebtOptimizerScreen> {
  double _extraPayment = 0.0;
  String? _activeStrategy; // user-selected strategy; defaults to recommended
  String _currency = 'USD'; // Currency code, updated from settings

  @override
  void initState() {
    super.initState();
    final presetPayment = widget.initialExtraPayment;
    if (presetPayment != null && presetPayment.isFinite && presetPayment >= 0) {
      _extraPayment = presetPayment.clamp(0.0, 2000.0).toDouble();
    }
    final strategy = widget.initialStrategy;
    if (strategy == 'avalanche' || strategy == 'snowball') {
      _activeStrategy = strategy;
    }
  }

  // Helper to format currency with user's selected currency
  String _formatCurrency(double amount) {
    return CurrencyFormatter.format(amount, _currency);
  }

  // Helper to calculate payoff date from month number
  String _getPayoffDate(int monthsFromNow) {
    final now = DateTime.now();
    final payoffDate = DateTime(now.year, now.month + monthsFromNow, 1);
    return DateFormat.yMMM(Localizations.localeOf(context).toString())
        .format(payoffDate);
  }

  @override
  Widget build(BuildContext context) {
    final liabilitiesAsync = ref.watch(liabilitiesProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final exchangeRateService = ref.watch(exchangeRateServiceProvider);

    return liabilitiesAsync.when(
      loading: () => Scaffold(
        appBar:
            AppBar(title: Text(AppLocalizations.of(context)!.debtOptimizer)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar:
            AppBar(title: Text(AppLocalizations.of(context)!.debtOptimizer)),
        body: Center(
          child: Text(
            AppLocalizations.of(context)!.errorWithMessage(error.toString()),
          ),
        ),
      ),
      data: (liabilities) => settingsAsync.when(
        loading: () => Scaffold(
          appBar:
              AppBar(title: Text(AppLocalizations.of(context)!.debtOptimizer)),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar:
              AppBar(title: Text(AppLocalizations.of(context)!.debtOptimizer)),
          body: Center(
            child: Text(
              AppLocalizations.of(context)!.errorWithMessage(error.toString()),
            ),
          ),
        ),
        data: (settings) => FutureBuilder<List<Liability>>(
          future: _convertLiabilities(
            liabilities,
            settings.baseCurrency,
            settings.currency,
            exchangeRateService,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.debtOptimizer),
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.debtOptimizer),
                ),
                body: Center(
                  child: Text(
                    AppLocalizations.of(context)!
                        .errorWithMessage(snapshot.error.toString()),
                  ),
                ),
              );
            }
            final convertedLiabilities = snapshot.data ?? liabilities;
            return _buildContent(context, convertedLiabilities, settings);
          },
        ),
      ),
    );
  }

  // Convert liabilities from base currency to display currency
  Future<List<Liability>> _convertLiabilities(
    List<Liability> liabilities,
    String baseCurrency,
    String displayCurrency,
    ExchangeRateService exchangeService,
  ) async {
    if (baseCurrency == displayCurrency) {
      return liabilities;
    }

    final rate = await exchangeService.getRate(baseCurrency, displayCurrency);

    return liabilities.map((liability) {
      return Liability(
        id: liability.id,
        name: liability.name,
        kind: liability.kind,
        balance: liability.balance * rate,
        apr: liability.apr,
        minPayment: liability.minPayment * rate,
        updatedAt: liability.updatedAt,
        creditLimit: liability.creditLimit != null
            ? liability.creditLimit! * rate
            : null,
        nextPaymentDate: liability.nextPaymentDate,
        paymentFrequencyDays: liability.paymentFrequencyDays,
        dayOfMonth: liability.dayOfMonth,
      );
    }).toList();
  }

  Widget _buildContent(
    BuildContext context,
    List<Liability> liabilities,
    Settings settings,
  ) {
    // Update currency from settings
    _currency = settings.currency;

    // Pro gate - redirect non-Pro users to upgrade screen
    if (!settings.isPro) {
      return _buildProGate(context);
    }

    if (liabilities.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.debtOptimizer),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.noDebtsToOptimize,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.addLiabilitiesFromTab,
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
        title: Text(AppLocalizations.of(context)!.debtOptimizer),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.presetSource == 'command_center')
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
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Command Center preset applied: extra payment ${CurrencyFormatter.format(_extraPayment, _currency)} / mo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                          AppLocalizations.of(context)!.currentDebt,
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
                      CurrencyFormatter.format(totalDebt, _currency),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.liabilityCount(
                        liabilities.length,
                        _formatCurrency(totalMinPayment),
                      ),
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
                        Text(
                          AppLocalizations.of(context)!.extraMonthlyPayment,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_extraPayment, _currency),
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
                      AppLocalizations.of(context)!.totalMonthlyPayment(
                        _formatCurrency(totalMinPayment + _extraPayment),
                      ),
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
                Text(
                  AppLocalizations.of(context)!.payoffStrategies,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStrategyToggle(context, betterStrategy),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.strategyRecommendation,
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
              title: betterStrategy == 'avalanche'
                  ? AppLocalizations.of(context)!.avalancheRecommended
                  : AppLocalizations.of(context)!.avalanche,
              subtitle: AppLocalizations.of(context)!.avalancheDescription,
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
              title: betterStrategy == 'snowball'
                  ? AppLocalizations.of(context)!.snowballRecommended
                  : AppLocalizations.of(context)!.snowball,
              subtitle: AppLocalizations.of(context)!.snowballDescription,
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
                            AppLocalizations.of(context)!
                                .unlockDetailedPayoffSchedule,
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
                        AppLocalizations.of(context)!.monthByMonthBreakdown,
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProFeature(
                        AppLocalizations.of(context)!.exactPayoffDate,
                      ),
                      _buildProFeature(
                        AppLocalizations.of(context)!.principalVsInterest,
                      ),
                      _buildProFeature(
                        AppLocalizations.of(context)!.remainingBalanceTracking,
                      ),
                      _buildProFeature(
                        AppLocalizations.of(context)!.totalInterestSaved(
                          _formatCurrency(
                            betterResult.interestSavingsVsMinimum,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            // Navigate to Pro screen
                            Navigator.pushNamed(context, '/pro');
                          },
                          child: Text(
                            AppLocalizations.of(context)!.upgradeToProTitle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Show debt payoff order
              Text(
                AppLocalizations.of(context)!.debtPayoffOrder,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.debtsWillBePaidInOrder(
                  _activeStrategy == 'avalanche'
                      ? AppLocalizations.of(context)!.avalanche.toUpperCase()
                      : AppLocalizations.of(context)!.snowball.toUpperCase(),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _buildDebtPayoffOrder(context, selectedResult),
              const SizedBox(height: 24),

              // Show detailed schedule for Pro users
              Text(
                AppLocalizations.of(context)!.paymentSchedule,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.monthByMonthStrategy(
                  _activeStrategy == 'avalanche'
                      ? AppLocalizations.of(context)!.avalanche.toUpperCase()
                      : AppLocalizations.of(context)!.snowball.toUpperCase(),
                ),
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
                            AppLocalizations.of(context)!.paidOff,
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
                                AppLocalizations.of(context)!.best,
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
                                AppLocalizations.of(context)!.selected,
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
                    tooltip: AppLocalizations.of(context)!.selectStrategy,
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
                      AppLocalizations.of(context)!.payoffTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!
                          .monthsCount(result.monthsToPayoff),
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
                      AppLocalizations.of(context)!.totalInterest,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(result.totalInterest, _currency),
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
                      AppLocalizations.of(context)!.saveVsMinimum(
                        _formatCurrency(result.interestSavingsVsMinimum),
                      ),
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
              AppLocalizations.of(context)!.detailedPaymentSchedule,
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
                            AppLocalizations.of(context)!
                                .monthNumber(month.month),
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
                                AppLocalizations.of(context)!
                                    .principalAndInterest(
                                  _formatCurrency(month.principalPayment),
                                  _formatCurrency(month.interestPayment),
                                ),
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
                            AppLocalizations.of(context)!.remaining(
                              _formatCurrency(month.remainingBalance),
                            ),
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
                AppLocalizations.of(context)!
                    .moreMonths(result.schedule.length - 12),
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
        .map(
          (d) => {
            'name': d.name,
            'balance': d.balance,
            'apr': d.apr,
          },
        )
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
          _buildToggleChip(
            context,
            AppLocalizations.of(context)!.avalanche,
            'avalanche',
            recommended,
          ),
          _buildToggleChip(
            context,
            AppLocalizations.of(context)!.snowball,
            'snowball',
            recommended,
          ),
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
                  AppLocalizations.of(context)!.strategyComparison,
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
              AppLocalizations.of(context)!.strategySavingsComparison(
                betterLabel,
                _formatCurrency(interestDiff),
                monthsDiff > 0
                    ? AppLocalizations.of(context)!.andFinishesEarlier(
                        monthsDiff,
                        monthsDiff == 1 ? '' : 's',
                      )
                    : '',
              ),
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
        title: Text(AppLocalizations.of(context)!.debtOptimizer),
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
              Text(
                AppLocalizations.of(context)!.unlockDebtPayoffOptimizer,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.fastestPathToDebtFreedom,
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
                      AppLocalizations.of(context)!.compareAvalancheSnowball,
                    ),
                    const SizedBox(height: 8),
                    _buildProFeatureItem(
                      AppLocalizations.of(context)!.seeExactPayoffDates,
                    ),
                    const SizedBox(height: 8),
                    _buildProFeatureItem(
                      AppLocalizations.of(context)!.calculateInterestSavings,
                    ),
                    const SizedBox(height: 8),
                    _buildProFeatureItem(
                      AppLocalizations.of(context)!.getMonthlySchedule,
                    ),
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
                label: Text(AppLocalizations.of(context)!.upgradeToProTitle),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.goBack),
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
