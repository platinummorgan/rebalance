import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../data/calculators/liquidity.dart';
import '../../data/calculators/concentration.dart';
import '../../data/calculators/homebias.dart';
import '../../data/calculators/fixedincome.dart';
import '../../data/calculators/debtload.dart';
import '../../widgets/currency_text.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mix & Dials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            tooltip: 'About Allocation Analysis',
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
                onPressed: () => ref.read(accountsProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildReportsContent(context, ref, accounts);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              Icons.donut_large_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Analysis Available',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Add your accounts to see detailed allocation analysis and rebalancing recommendations.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.push('/accounts'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Your First Account'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsContent(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
  ) {
    final allocation = _calculateAllocation(accounts);
    final totalAssets =
        accounts.fold<double>(0.0, (sum, account) => sum + account.balance);

    // Watch liabilities and settings for proper calculations
    final liabilitiesAsync = ref.watch(liabilitiesProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Portfolio Summary',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Total Assets: ',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                CurrencyText(
                                  totalAssets,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Updated ${DateFormat('MMM d').format(DateTime.now())}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
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

          // Large allocation donut chart
          Text(
            'Asset Allocation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: _buildLargeAllocationDonut(
                      context,
                      allocation,
                      totalAssets,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailedLegend(context, ref, allocation, totalAssets),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Diversification Dials
          Text(
            'Diversification Dials',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Only show dials if we have all required data
          liabilitiesAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading debt data: $error'),
              ),
            ),
            data: (liabilities) => settingsAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error loading settings: $error'),
                ),
              ),
              data: (settings) => _buildDiversificationDials(
                context,
                ref,
                accounts,
                liabilities,
                settings,
                allocation,
                totalAssets,
              ),
            ),
          ),
        ],
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
      allocation['Cash'] =
          allocation['Cash']! + (breakdown['cash'] as num).toDouble();
      allocation['Bonds'] =
          allocation['Bonds']! + (breakdown['bonds'] as num).toDouble();
      allocation['US Equity'] =
          allocation['US Equity']! + (breakdown['usEq'] as num).toDouble();
      allocation['Intl Equity'] =
          allocation['Intl Equity']! + (breakdown['intlEq'] as num).toDouble();
      allocation['Real Estate'] = allocation['Real Estate']! +
          (breakdown['realEstate'] as num).toDouble();
      allocation['Alternative'] =
          allocation['Alternative']! + (breakdown['alt'] as num).toDouble();
    }

    return allocation;
  }

  Widget _buildLargeAllocationDonut(
    BuildContext context,
    Map<String, double> allocation,
    double totalAssets,
  ) {
    if (totalAssets == 0) {
      return const Center(child: Text('No data available'));
    }

    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.green, // Cash
      Colors.blue, // Bonds
      Colors.purple, // US Equity
      Colors.orange, // Intl Equity
      Colors.brown, // Real Estate
      Colors.teal, // Alternative
    ];

    int colorIndex = 0;
    allocation.forEach((key, value) {
      if (value > 0) {
        final percentage = (value / totalAssets) * 100;
        sections.add(
          PieChartSectionData(
            color: colors[colorIndex % colors.length],
            value: value,
            // Use one decimal to match the detailed legend formatting
            title: percentage > 3 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    });

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 3,
        centerSpaceRadius: 60,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildDetailedLegend(
    BuildContext context,
    WidgetRef ref,
    Map<String, double> allocation,
    double totalAssets,
  ) {
    final colors = [
      Colors.green, // Cash
      Colors.blue, // Bonds
      Colors.purple, // US Equity
      Colors.orange, // Intl Equity
      Colors.brown, // Real Estate
      Colors.teal, // Alternative
    ];

    final keys = allocation.keys.toList();

    return Column(
      children: List.generate(keys.length, (index) {
        final key = keys[index];
        final value = allocation[key]!;
        if (value == 0) return const SizedBox();

        final percentage = (value / totalAssets * 100);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              CurrencyText(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).where((widget) => widget is! SizedBox).toList(),
    );
  }

  Widget _buildDiversificationDials(
    BuildContext context,
    WidgetRef ref,
    List<Account> accounts,
    List<Liability> liabilities,
    Settings settings,
    Map<String, double> allocation,
    double totalAssets,
  ) {
    // Calculate dial values using proper calculators
    final liquidityResult = LiquidityCalculator.calculateLiquidity(
      accounts,
      settings.monthlyEssentials,
      settings,
    );

    final concentrationResult =
        ConcentrationCalculator.calculateConcentration(accounts, settings);

    final homeBiasResult =
        HomeBiasCalculator.calculateHomeBias(accounts, settings);

    final fixedIncomeResult =
        FixedIncomeCalculator.calculateFixedIncomeAllocation(
      accounts,
      settings,
    );

    final debtLoadResult = DebtLoadCalculator.calculateDebtLoad(
      accounts,
      liabilities,
      settings.monthlyEssentials,
      settings,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diversification Dials',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),

            // Responsive grid of dials
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                if (isNarrow) {
                  // Single column layout for narrow screens
                  return Column(
                    children: [
                      _buildDial(
                        context,
                        'Liquidity',
                        '${liquidityResult.monthsOfEssentials.toStringAsFixed(1)}mo',
                        _getCalculatorBandColor(liquidityResult.band),
                        liquidityResult.description,
                      ),
                      const SizedBox(height: 16),
                      _buildDial(
                        context,
                        'Concentration',
                        '${(concentrationResult.largestBucketPct * 100).toStringAsFixed(0)}%',
                        _getCalculatorBandColor(concentrationResult.band),
                        concentrationResult.description,
                      ),
                      const SizedBox(height: 16),
                      _buildDial(
                        context,
                        'Home-bias',
                        '${(homeBiasResult.intlEquityPct * 100).toStringAsFixed(0)}%',
                        _getCalculatorBandColor(homeBiasResult.band),
                        homeBiasResult.description,
                      ),
                      const SizedBox(height: 16),
                      _buildDial(
                        context,
                        'Fixed Income',
                        '${(fixedIncomeResult.bondPct * 100).toStringAsFixed(0)}%',
                        _getCalculatorBandColor(fixedIncomeResult.band),
                        fixedIncomeResult.description,
                      ),
                      const SizedBox(height: 16),
                      _buildDial(
                        context,
                        'Debt Load',
                        '${(debtLoadResult.weightedApr * 100).toStringAsFixed(1)}%',
                        _getCalculatorBandColor(debtLoadResult.band),
                        debtLoadResult.description,
                      ),
                    ],
                  );
                } else {
                  // Two columns for wider screens
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDial(
                              context,
                              'Liquidity',
                              '${liquidityResult.monthsOfEssentials.toStringAsFixed(1)}mo',
                              _getCalculatorBandColor(liquidityResult.band),
                              liquidityResult.description,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDial(
                              context,
                              'Concentration',
                              '${(concentrationResult.largestBucketPct * 100).toStringAsFixed(0)}%',
                              _getCalculatorBandColor(concentrationResult.band),
                              concentrationResult.description,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDial(
                              context,
                              'Home-bias',
                              '${(homeBiasResult.intlEquityPct * 100).toStringAsFixed(0)}%',
                              _getCalculatorBandColor(homeBiasResult.band),
                              homeBiasResult.description,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDial(
                              context,
                              'Fixed Income',
                              '${(fixedIncomeResult.bondPct * 100).toStringAsFixed(0)}%',
                              _getCalculatorBandColor(fixedIncomeResult.band),
                              fixedIncomeResult.description,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDial(
                              context,
                              'Debt Load',
                              '${(debtLoadResult.weightedApr * 100).toStringAsFixed(1)}%',
                              _getCalculatorBandColor(debtLoadResult.band),
                              debtLoadResult.description,
                            ),
                          ),
                          Expanded(child: Container()), // Empty space
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDial(
    BuildContext context,
    String title,
    String value,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color, width: 3),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Universal color method for calculator result bands
  Color _getCalculatorBandColor(dynamic band) {
    // All calculator enums use red/yellow/green pattern
    final bandStr = band.toString().split('.').last;
    switch (bandStr) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue': // Special case for liquidity
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Mix & Dials'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This screen provides detailed analysis of your portfolio:'),
            SizedBox(height: 12),
            Text('• Asset Allocation - Visual breakdown of your investments'),
            SizedBox(height: 8),
            Text('• Diversification Dials - Risk and geographic distribution'),
            SizedBox(height: 8),
            Text('• Rebalancing Plans - Actionable recommendations'),
            SizedBox(height: 12),
            Text(
              'All analysis is based on your current account balances and allocations.',
            ),
          ],
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
