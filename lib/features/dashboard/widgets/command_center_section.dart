import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app.dart';
import '../../../data/calculators/allocation.dart';
import '../../../data/calculators/financial_health.dart';
import '../../../data/models.dart';
import '../../../routes.dart' show AppRouter;
import '../../../utils/currency_formatter.dart';

class CommandCenterSection extends ConsumerWidget {
  final List<Account> accounts;

  const CommandCenterSection({
    super.key,
    required this.accounts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final liabilities = ref.watch(liabilitiesProvider).maybeWhen(
          data: (data) => data,
          orElse: () => const <Liability>[],
        );
    final incomes = ref.watch(incomesProvider).maybeWhen(
          data: (data) => data,
          orElse: () => const <Income>[],
        );
    final expenses = ref.watch(expensesProvider).maybeWhen(
          data: (data) => data,
          orElse: () => const <MonthlyExpense>[],
        );
    final settings = ref.watch(settingsProvider).maybeWhen(
          data: (data) => data,
          orElse: () => null,
        );

    final currency = settings?.currency ?? 'USD';
    final totalAssets = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    final totalLiabilities =
        liabilities.fold<double>(0, (sum, l) => sum + l.balance);
    final netWorth = totalAssets - totalLiabilities;

    final double monthlyIncome =
        incomes.fold<double>(0, (sum, i) => sum + i.monthlyNet);
    final double monthlyTrackedExpenses =
        expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final double monthlyEssentials = settings?.monthlyEssentials ?? 0;
    final double monthlyBurn =
        max(monthlyTrackedExpenses, monthlyEssentials).toDouble();
    final double monthlySurplus = monthlyIncome - monthlyBurn;

    final cashBuffer = accounts
        .where((a) => a.kind == 'cash' || a.kind == 'savings')
        .fold<double>(0, (sum, a) => sum + a.balance);
    final double runwayMonths = monthlyBurn > 0 ? cashBuffer / monthlyBurn : 0.0;

    final healthResult = settings == null
        ? null
        : FinancialHealthCalculator.calculateOverallHealth(
            accounts,
            liabilities,
            settings,
          );

    final urgencyItems = _buildUrgencyItems(
      context: context,
      totalAssets: totalAssets,
      liabilities: liabilities,
      runwayMonths: runwayMonths,
      monthlySurplus: monthlySurplus,
    );

    final scenarioCards = _buildScenarioCards(
      context: context,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netWorth: netWorth,
      liabilities: liabilities,
      monthlySurplus: monthlySurplus,
      accounts: accounts,
      currency: currency,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary.withValues(alpha: 0.24),
                  scheme.secondary.withValues(alpha: 0.16),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.space_dashboard_rounded,
                        color: scheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Command Center',
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (healthResult != null)
                      _HealthBadge(
                        score: healthResult.score,
                        grade: healthResult.grade.name,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Today\'s highest-leverage financial moves',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      label: 'Net Worth',
                      value: CurrencyFormatter.format(netWorth, currency),
                    ),
                    _MetricChip(
                      label: monthlySurplus >= 0 ? 'Monthly Surplus' : 'Monthly Gap',
                      value: CurrencyFormatter.format(monthlySurplus, currency),
                      color: monthlySurplus >= 0 ? Colors.green : Colors.red,
                    ),
                    _MetricChip(
                      label: 'Cash Runway',
                      value: runwayMonths.isFinite
                          ? '${runwayMonths.toStringAsFixed(1)} mo'
                          : '--',
                      color: runwayMonths >= 4
                          ? Colors.green
                          : (runwayMonths >= 2 ? Colors.orange : Colors.red),
                    ),
                    _MetricChip(
                      label: 'Open Liabilities',
                      value: liabilities.length.toString(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _UrgencyTimelineCard(items: urgencyItems),
          const SizedBox(height: 14),
          _ScenarioDeck(
            cards: scenarioCards,
            onTap: (route) => context.push(route),
          ),
        ],
      ),
    );
  }

  List<_UrgencyItem> _buildUrgencyItems({
    required BuildContext context,
    required double totalAssets,
    required List<Liability> liabilities,
    required double runwayMonths,
    required double monthlySurplus,
  }) {
    final dueSoon = liabilities
        .where((l) => l.daysUntilDue != null && l.daysUntilDue! <= 14)
        .toList()
      ..sort((a, b) => (a.daysUntilDue ?? 999).compareTo(b.daysUntilDue ?? 999));

    final items = <_UrgencyItem>[];

    if (dueSoon.isNotEmpty) {
      final top = dueSoon.first;
      final days = top.daysUntilDue ?? 0;
      final dueText = days < 0
          ? 'Overdue by ${days.abs()} day${days.abs() == 1 ? '' : 's'}'
          : (days == 0
              ? 'Due today'
              : 'Due in $days day${days == 1 ? '' : 's'}');
      items.add(
        _UrgencyItem(
          title: top.name,
          subtitle: '$dueText • APR ${(top.apr * 100).toStringAsFixed(1)}%',
          icon: Icons.event_busy_rounded,
          severity: days < 0
              ? _UrgencySeverity.critical
              : (days <= 2 ? _UrgencySeverity.high : _UrgencySeverity.medium),
          route: AppRouter.liabilities,
        ),
      );
    }

    if (totalAssets > 0) {
      final totals = AllocationCalculator.calculateTotals(accounts);
      String largestBucket = 'usEq';
      double largestAmount = 0;
      totals.forEach((bucket, amount) {
        if (amount > largestAmount) {
          largestAmount = amount;
          largestBucket = bucket;
        }
      });
      final largestPct = (largestAmount / totalAssets) * 100;
      if (largestPct >= 35) {
        items.add(
          _UrgencyItem(
            title: 'Concentration: ${_bucketName(largestBucket)}',
            subtitle: '${largestPct.toStringAsFixed(1)}% in one bucket',
            icon: Icons.balance_rounded,
            severity:
                largestPct >= 45 ? _UrgencySeverity.high : _UrgencySeverity.medium,
            route: AppRouter.rebalancing,
          ),
        );
      }
    }

    if (runwayMonths < 4) {
      items.add(
        _UrgencyItem(
          title: runwayMonths < 2 ? 'Cash buffer is thin' : 'Cash buffer needs work',
          subtitle:
              'Runway ${runwayMonths.toStringAsFixed(1)} months • target 4.0+ months',
          icon: Icons.health_and_safety_rounded,
          severity: runwayMonths < 2
              ? _UrgencySeverity.high
              : _UrgencySeverity.medium,
          route: AppRouter.targets,
        ),
      );
    }

    if (monthlySurplus < 0) {
      items.add(
        const _UrgencyItem(
          title: 'Monthly cashflow is negative',
          subtitle: 'Spending exceeds income in current profile',
          icon: Icons.trending_down_rounded,
          severity: _UrgencySeverity.critical,
          route: AppRouter.expenses,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _UrgencyItem(
          title: 'No immediate fires',
          subtitle: 'You are clear for proactive optimization this week',
          icon: Icons.check_circle_rounded,
          severity: _UrgencySeverity.good,
          route: AppRouter.scenario,
        ),
      );
    }

    return items.take(4).toList();
  }

  List<_ScenarioCardModel> _buildScenarioCards({
    required BuildContext context,
    required double totalAssets,
    required double totalLiabilities,
    required double netWorth,
    required List<Liability> liabilities,
    required double monthlySurplus,
    required List<Account> accounts,
    required String currency,
  }) {
    final equityExposure = accounts.fold<double>(
      0,
      (sum, a) => sum + (a.balance * (a.pctUsEq + a.pctIntlEq + a.pctAlt)),
    );
    final drawdownImpact = equityExposure * 0.20;
    final shockNetWorth = netWorth - drawdownImpact;

    final highAprDebt = liabilities
        .where((l) => l.apr >= 0.18)
        .fold<double>(0, (sum, l) => sum + l.balance);
    final suggestedDebtExtra = monthlySurplus > 0 ? monthlySurplus : 0.0;
    final blitzMonths = monthlySurplus > 0 && highAprDebt > 0
        ? (highAprDebt / monthlySurplus).ceil()
        : null;

    final totals = totalAssets > 0
        ? AllocationCalculator.calculateTotals(accounts)
        : <String, double>{};
    String largestBucket = 'usEq';
    double largestAmount = 0;
    totals.forEach((bucket, amount) {
      if (amount > largestAmount) {
        largestAmount = amount;
        largestBucket = bucket;
      }
    });
    final largestPct = totalAssets > 0 ? (largestAmount / totalAssets) * 100 : 0;
    final shiftToThirty =
        max(0, ((largestPct - 30) / 100) * totalAssets).toDouble();

    final shockScenarioRoute = Uri(
      path: AppRouter.scenario,
      queryParameters: {
        'preset': 'shock20',
        'source': 'command_center',
        'years': '1',
        'expectedReturn': '-0.20',
        'volatility': '0.30',
        'goalAmount': max(1000, shockNetWorth).toStringAsFixed(2),
        'monthlyContribution': max(monthlySurplus, 0).toStringAsFixed(2),
      },
    ).toString();

    final debtBlitzRoute = Uri(
      path: AppRouter.debtOptimizer,
      queryParameters: {
        'source': 'command_center',
        'strategy': 'avalanche',
        'extraPayment': suggestedDebtExtra.toStringAsFixed(2),
      },
    ).toString();

    final rebalanceLiftRoute = Uri(
      path: AppRouter.rebalancing,
      queryParameters: {
        'source': 'command_center',
        'strategy': 'immediate',
        'suggestedMove': shiftToThirty.toStringAsFixed(2),
        'glideMonths': '6',
      },
    ).toString();

    return [
      _ScenarioCardModel(
        title: 'Shock Test',
        subtitle: '-20% risk-asset month',
        metric: CurrencyFormatter.format(drawdownImpact * -1, currency),
        detail: 'Projected net worth: ${CurrencyFormatter.format(shockNetWorth, currency)}',
        route: shockScenarioRoute,
        icon: Icons.show_chart_rounded,
      ),
      _ScenarioCardModel(
        title: 'Debt Blitz',
        subtitle: 'Apply surplus to high APR first',
        metric: blitzMonths == null ? 'Not Ready' : '$blitzMonths months',
        detail: highAprDebt > 0
            ? 'High APR debt: ${CurrencyFormatter.format(highAprDebt, currency)}'
            : 'No high APR balance detected',
        route: debtBlitzRoute,
        icon: Icons.bolt_rounded,
      ),
      _ScenarioCardModel(
        title: 'Rebalance Lift',
        subtitle: 'Move toward 30% max bucket',
        metric: CurrencyFormatter.format(shiftToThirty, currency),
        detail:
            '${_bucketName(largestBucket)} at ${largestPct.toStringAsFixed(1)}% now',
        route: rebalanceLiftRoute,
        icon: Icons.tune_rounded,
      ),
      _ScenarioCardModel(
        title: 'Tax Lens',
        subtitle: 'Locate drag and optimize placement',
        metric: CurrencyFormatter.format(totalLiabilities * 0.01, currency),
        detail: 'Potential annual drag reduction estimate',
        route: AppRouter.taxSmart,
        icon: Icons.account_tree_rounded,
      ),
    ];
  }

  String _bucketName(String key) {
    switch (key) {
      case 'cash':
        return 'Cash';
      case 'bonds':
        return 'Bonds';
      case 'usEq':
        return 'US Equity';
      case 'intlEq':
        return 'Intl Equity';
      case 'realEstate':
        return 'Real Estate';
      case 'alt':
        return 'Alternatives';
      default:
        return 'Portfolio';
    }
  }
}

class _HealthBadge extends StatelessWidget {
  final int score;
  final String grade;

  const _HealthBadge({
    required this.score,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = score >= 80
        ? Colors.green
        : (score >= 65 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scoreColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 14, color: scoreColor),
          const SizedBox(width: 6),
          Text(
            '$grade $score',
            style: TextStyle(
              color: scoreColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricChip({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgencyTimelineCard extends StatelessWidget {
  final List<_UrgencyItem> items;

  const _UrgencyTimelineCard({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timelapse_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Urgency Timeline',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == items.length - 1;
            return _UrgencyRow(item: item, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _UrgencyRow extends StatelessWidget {
  final _UrgencyItem item;
  final bool isLast;

  const _UrgencyRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.severity) {
      _UrgencySeverity.critical => Colors.red,
      _UrgencySeverity.high => Colors.deepOrange,
      _UrgencySeverity.medium => Colors.orange,
      _UrgencySeverity.good => Colors.green,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(item.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 34,
                      color: color.withValues(alpha: 0.34),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.72),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(item.icon, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

class _ScenarioDeck extends StatelessWidget {
  final List<_ScenarioCardModel> cards;
  final ValueChanged<String> onTap;

  const _ScenarioDeck({
    required this.cards,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scenario Playbook',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final card = cards[index];
              return _ScenarioCard(
                card: card,
                onTap: () => onTap(card.route),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final _ScenarioCardModel card;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 224,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.18),
            scheme.secondary.withValues(alpha: 0.11),
            scheme.surfaceContainerHighest.withValues(alpha: 0.86),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(card.icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.metric,
            style: TextStyle(
              fontSize: 20,
              color: scheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          FilledButton.tonal(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }
}

class _UrgencyItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final _UrgencySeverity severity;
  final String route;

  const _UrgencyItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.severity,
    required this.route,
  });
}

class _ScenarioCardModel {
  final String title;
  final String subtitle;
  final String metric;
  final String detail;
  final String route;
  final IconData icon;

  const _ScenarioCardModel({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.detail,
    required this.route,
    required this.icon,
  });
}

enum _UrgencySeverity {
  critical,
  high,
  medium,
  good,
}
