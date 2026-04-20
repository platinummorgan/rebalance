import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/calculators/financial_health.dart';
import '../../../data/models.dart';
import '../../../generated/app_localizations.dart';
import '../../../routes.dart' show AppRouter;

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
                      '${AppLocalizations.of(context)!.financialHealthScore} — ${AppLocalizations.of(context)!.howBalancedIsYourPortfolio}',
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
                      '${_getGradeText(healthResult.grade, context)} • ${percentage > cap ? '${largestBucket['name']} ${percentage.toStringAsFixed(1)}% (cap ${cap.toStringAsFixed(0)}%)' : AppLocalizations.of(context)!.wellBalanced}',
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
        'name': AppLocalizations.of(context)!.concentrationRisk,
        'weight': '30%',
        'score': 65,
        'target': 80,
      },
      {
        'name': AppLocalizations.of(context)!.fixedIncomeBalance,
        'weight': '25%',
        'score': 72,
        'target': 75,
      },
      {
        'name': AppLocalizations.of(context)!.liquidityBuffer,
        'weight': '20%',
        'score': 55,
        'target': 70,
      },
      {
        'name': AppLocalizations.of(context)!.internationalExposure,
        'weight': '15%',
        'score': 78,
        'target': 80,
      },
      {
        'name': AppLocalizations.of(context)!.debtManagement,
        'weight': '10%',
        'score': 85,
        'target': 90,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.weightedBreakdown,
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
        'name': AppLocalizations.of(context)!.concentration,
        'change': 2,
        'reason': AppLocalizations.of(context)!.reducedUsEquityPosition,
      },
      {
        'name': AppLocalizations.of(context)!.bonds,
        'change': 1,
        'reason': AppLocalizations.of(context)!.addedFixedIncomeAllocation,
      },
      {
        'name': AppLocalizations.of(context)!.liquidity,
        'change': 0,
        'reason': AppLocalizations.of(context)!.noChangeInCashPosition,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.whatMoved,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.sinceLast30d,
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
        'title': AppLocalizations.of(context)!.openMixAndDials,
        'description':
            AppLocalizations.of(context)!.reviewDetailedAllocationBreakdown,
        'icon': Icons.donut_large,
        'isPrimary': true,
        'onTap': () => context.push('/reports'),
      },
      {
        'title': AppLocalizations.of(context)!.addToPlan,
        'description': AppLocalizations.of(context)!.createRebalancingStrategy,
        'icon': Icons.auto_fix_high,
        'isPrimary': false,
        'onTap': () => context.push('/reports'),
      },
      {
        'title': AppLocalizations.of(context)!.setTargetAllocation,
        'description': AppLocalizations.of(context)!.adjustYourRiskPreferences,
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
          AppLocalizations.of(context)!.nextActions,
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
            AppLocalizations.of(context)!.seeHowAddingBondsAffectsScore,
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
            label: Text(AppLocalizations.of(context)!.runSimulation),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBands(BuildContext context) {
    return ExpansionTile(
      title: Text(
        AppLocalizations.of(context)!.explainGradeBands,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GradeBandRow(
                grade: 'A',
                range: '80-100',
                label: AppLocalizations.of(context)!.excellent,
                color: Colors.green,
              ),
              _GradeBandRow(
                grade: 'B',
                range: '60-79',
                label: AppLocalizations.of(context)!.good,
                color: Colors.lightGreen,
              ),
              _GradeBandRow(
                grade: 'C',
                range: '40-59',
                label: AppLocalizations.of(context)!.fair,
                color: Colors.orange,
              ),
              _GradeBandRow(
                grade: 'D',
                range: '20-39',
                label: AppLocalizations.of(context)!.needsWork,
                color: Colors.deepOrange,
              ),
              _GradeBandRow(
                grade: 'F',
                range: '0-19',
                label: AppLocalizations.of(context)!.poor,
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
                      AppLocalizations.of(context)!.financialHealth,
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
