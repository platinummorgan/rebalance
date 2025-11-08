import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/retirement_calculator_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/premium_helper.dart';
import '../../utils/currency_formatter.dart';

class RetirementCalculatorScreen extends ConsumerStatefulWidget {
  const RetirementCalculatorScreen({super.key});

  @override
  ConsumerState<RetirementCalculatorScreen> createState() =>
      _RetirementCalculatorScreenState();
}

class _RetirementCalculatorScreenState
    extends ConsumerState<RetirementCalculatorScreen> {
  // Input values
  double _currentSavings = 50000;
  double _monthlyContribution = 1000;
  int _yearsUntilRetirement = 30;
  double _desiredMonthlyIncome = 5000;
  int _retirementDuration = 30;

  RetirementResult? _result;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _calculate();

    // Track calculator view with Pro status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPro = PremiumHelper.isPro(ref);
      AnalyticsService().logRetirementCalculatorView(isPro: isPro);
    });
  }

  void _calculate() {
    setState(() {
      _isCalculating = true;
    });

    // Run calculation asynchronously to keep UI responsive
    Future.delayed(const Duration(milliseconds: 100), () {
      final result = RetirementCalculatorService.calculate(
        currentSavings: _currentSavings,
        monthlyContribution: _monthlyContribution,
        yearsUntilRetirement: _yearsUntilRetirement,
        desiredMonthlyIncome: _desiredMonthlyIncome,
        retirementDuration: _retirementDuration,
      );

      if (mounted) {
        setState(() {
          _result = result;
          _isCalculating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPro = PremiumHelper.isPro(ref);

    if (!isPro) {
      return _buildUpgradeScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retirement Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildInputsSection(),
          const SizedBox(height: 16),
          if (_isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_result != null) ...[
            _buildResultsSection(_result!),
            const SizedBox(height: 16),
            _buildProbabilityChart(_result!),
            const SizedBox(height: 16),
            _buildRecommendationsSection(_result!),
          ],
        ],
      ),
    );
  }

  Widget _buildUpgradeScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retirement Calculator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.workspace_premium,
                size: 80,
                color: Colors.amber.shade700,
              ),
              const SizedBox(height: 24),
              const Text(
                'Pro Feature',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The Retirement Calculator uses Monte Carlo simulation to project whether you\'re on track for retirement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => PremiumHelper.showUpgradeDialog(
                  context,
                  feature: 'Retirement Calculator',
                  description:
                      'Get Monte Carlo simulations, probability analysis, and personalized retirement recommendations.',
                ),
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade to Pro'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'This calculator runs 1,000 simulations to estimate your retirement success probability.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Retirement Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Current Savings
            _buildSliderInput(
              label: 'Current Savings',
              value: _currentSavings,
              min: 0,
              max: 1000000,
              divisions: 200,
              format: (v) => CurrencyFormatter.format(v, 'USD'),
              onChanged: (v) {
                setState(() => _currentSavings = v);
                _calculate();
              },
            ),

            const SizedBox(height: 24),

            // Monthly Contribution
            _buildSliderInput(
              label: 'Monthly Contribution',
              value: _monthlyContribution,
              min: 0,
              max: 10000,
              divisions: 200,
              format: (v) => CurrencyFormatter.format(v, 'USD'),
              onChanged: (v) {
                setState(() => _monthlyContribution = v);
                _calculate();
              },
            ),

            const SizedBox(height: 24),

            // Years Until Retirement
            _buildSliderInput(
              label: 'Years Until Retirement',
              value: _yearsUntilRetirement.toDouble(),
              min: 1,
              max: 50,
              divisions: 49,
              format: (v) => '${v.round()} years',
              onChanged: (v) {
                setState(() => _yearsUntilRetirement = v.round());
                _calculate();
              },
            ),

            const SizedBox(height: 24),

            // Desired Monthly Income
            _buildSliderInput(
              label: 'Desired Monthly Income',
              value: _desiredMonthlyIncome,
              min: 1000,
              max: 20000,
              divisions: 190,
              format: (v) => CurrencyFormatter.format(v, 'USD'),
              onChanged: (v) {
                setState(() => _desiredMonthlyIncome = v);
                _calculate();
              },
            ),

            const SizedBox(height: 24),

            // Retirement Duration
            _buildSliderInput(
              label: 'Years in Retirement',
              value: _retirementDuration.toDouble(),
              min: 10,
              max: 40,
              divisions: 30,
              format: (v) => '${v.round()} years',
              onChanged: (v) {
                setState(() => _retirementDuration = v.round());
                _calculate();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderInput({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            InkWell(
              onTap: () => _showValueInputDialog(
                context,
                label,
                value,
                min,
                max,
                format,
                onChanged,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      format(value),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _showValueInputDialog(
    BuildContext context,
    String label,
    double currentValue,
    double min,
    double max,
    String Function(double) format,
    ValueChanged<double> onChanged,
  ) async {
    final controller = TextEditingController(
      text: currentValue.round().toString(),
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Enter value',
            hintText: '${min.round()} - ${max.round()}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                onChanged(value);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Please enter a value between ${min.round()} and ${max.round()}',),
                  ),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(RetirementResult result) {
    final probabilityPct = (result.probabilityOfSuccess * 100).round();

    Color getGradeColor() {
      if (result.grade == 'A') return Colors.green;
      if (result.grade == 'B') return Colors.lightGreen;
      if (result.grade == 'C') return Colors.orange;
      if (result.grade == 'D') return Colors.deepOrange;
      return Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Success Probability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$probabilityPct%',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: getGradeColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: getGradeColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Grade ${result.grade}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.assessment,
              style: TextStyle(
                fontSize: 16,
                color: getGradeColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 32),
            _buildStatRow(
              'At Retirement',
              CurrencyFormatter.format(result.projectedAtRetirement, 'USD'),
              Icons.savings,
            ),
            _buildStatRow(
              'Median After Retirement',
              CurrencyFormatter.format(result.medianFinalBalance, 'USD'),
              Icons.account_balance,
            ),
            _buildStatRow(
              'Best Case (90th)',
              CurrencyFormatter.format(result.percentile90Balance, 'USD'),
              Icons.trending_up,
              color: Colors.green,
            ),
            _buildStatRow(
              'Worst Case (10th)',
              CurrencyFormatter.format(result.percentile10Balance, 'USD'),
              Icons.trending_down,
              color: result.percentile10Balance < 0 ? Colors.red : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon,
      {Color? color,}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityChart(RetirementResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Outcome Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How likely different outcomes are',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            'Fail',
                            'Low',
                            'Med',
                            'High',
                            'Excellent',
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return Text(
                              labels[value.toInt()],
                              style: const TextStyle(fontSize: 11),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%',
                              style: const TextStyle(fontSize: 10),);
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),),
                  ),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateBarGroups(result),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(RetirementResult result) {
    // Simplified distribution based on probability
    final failureRate = (1 - result.probabilityOfSuccess) * 100;
    final successRate = result.probabilityOfSuccess * 100;

    // Distribute success across categories
    final excellent = successRate > 80 ? successRate - 60 : 0.0;
    final high =
        successRate > 60 ? (successRate > 80 ? 20.0 : successRate - 40) : 0.0;
    final medium =
        successRate > 40 ? (successRate > 60 ? 20.0 : successRate - 20) : 0.0;
    final low = successRate > 20
        ? (successRate > 40 ? 20.0 : successRate)
        : successRate;

    return [
      _makeBarGroup(0, failureRate, Colors.red),
      _makeBarGroup(1, low, Colors.orange),
      _makeBarGroup(2, medium, Colors.amber),
      _makeBarGroup(3, high, Colors.lightGreen),
      _makeBarGroup(4, excellent, Colors.green),
    ];
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 40,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(RetirementResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._getRecommendations(result).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        rec.icon,
                        size: 20,
                        color: rec.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rec.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),),
          ],
        ),
      ),
    );
  }

  List<_Recommendation> _getRecommendations(RetirementResult result) {
    final recommendations = <_Recommendation>[];

    if (result.probabilityOfSuccess < 0.70) {
      // Calculate how much more they need to save
      final requiredSavings =
          RetirementCalculatorService.calculateRequiredSavings(
        currentSavings: _currentSavings,
        yearsUntilRetirement: _yearsUntilRetirement,
        retirementGoal: result.projectedAtRetirement * 1.3, // 30% buffer
      );

      recommendations.add(_Recommendation(
        icon: Icons.savings,
        color: Colors.orange,
        text:
            'Consider increasing monthly contributions to ${CurrencyFormatter.format(requiredSavings, 'USD')} to improve your odds.',
      ),);
    }

    if (result.probabilityOfSuccess >= 0.90) {
      recommendations.add(const _Recommendation(
        icon: Icons.celebration,
        color: Colors.green,
        text: 'Excellent! Your retirement plan is on track.',
      ),);
    }

    // Check 4% rule
    final safeWithdrawal = RetirementCalculatorService.calculateSafeWithdrawal(
      result.projectedAtRetirement,
    );
    if (_desiredMonthlyIncome > safeWithdrawal * 1.2) {
      recommendations.add(_Recommendation(
        icon: Icons.warning,
        color: Colors.red,
        text:
            'Your desired income (${CurrencyFormatter.format(_desiredMonthlyIncome, 'USD')}) exceeds the "4% rule" safe withdrawal amount (${CurrencyFormatter.format(safeWithdrawal, 'USD')}).',
      ),);
    }

    if (_yearsUntilRetirement > 10) {
      recommendations.add(_Recommendation(
        icon: Icons.timeline,
        color: Colors.blue,
        text:
            'With $_yearsUntilRetirement years until retirement, time is your biggest advantage. Stay consistent with contributions.',
      ),);
    }

    if (recommendations.isEmpty) {
      recommendations.add(const _Recommendation(
        icon: Icons.trending_up,
        color: Colors.blue,
        text:
            'Your plan is reasonable. Review annually and adjust as your situation changes.',
      ),);
    }

    return recommendations;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How It Works'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Monte Carlo Simulation',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'This calculator runs 1,000 different scenarios with random market returns to estimate your retirement success probability.',
              ),
              SizedBox(height: 16),
              Text(
                'Assumptions',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Average annual return: 7%'),
              Text('• Market volatility: 15%'),
              Text('• Inflation: 3% per year'),
              SizedBox(height: 16),
              Text(
                'The 4% Rule',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'A common guideline suggests withdrawing 4% of your portfolio annually (adjusted for inflation) for a 30-year retirement.',
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

class _Recommendation {
  final IconData icon;
  final Color color;
  final String text;

  const _Recommendation({
    required this.icon,
    required this.color,
    required this.text,
  });
}
