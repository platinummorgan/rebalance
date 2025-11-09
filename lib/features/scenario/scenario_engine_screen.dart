import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../services/monte_carlo.dart';
import '../../routes.dart' show AppRouter;
import '../../app.dart';
import '../../utils/currency_formatter.dart';
import '../../services/exchange_rate_service.dart';
import '../../generated/app_localizations.dart';

// --- Providers ---
class ScenarioInputs {
  final double monthlyContribution;
  final double expectedReturn; // annual expected return (0-1)
  final double volatility; // annual stdev (0-1)
  final double goalAmount;
  final int years;
  ScenarioInputs({
    required this.monthlyContribution,
    required this.expectedReturn,
    required this.volatility,
    required this.goalAmount,
    required this.years,
  });
  ScenarioInputs copyWith({
    double? monthlyContribution,
    double? expectedReturn,
    double? volatility,
    double? goalAmount,
    int? years,
  }) =>
      ScenarioInputs(
        monthlyContribution: monthlyContribution ?? this.monthlyContribution,
        expectedReturn: expectedReturn ?? this.expectedReturn,
        volatility: volatility ?? this.volatility,
        goalAmount: goalAmount ?? this.goalAmount,
        years: years ?? this.years,
      );
}

// Use StateProvider for Scenario A inputs so they persist when Compare is enabled
final _scenarioInputsProvider = StateProvider<ScenarioInputs?>((ref) => null);

// Provider that computes default values from accounts
final _defaultScenarioInputsProvider = Provider<ScenarioInputs>((ref) {
  final accounts = ref.watch(accountsProvider).maybeWhen(
        data: (a) => a,
        orElse: () => <Account>[],
      );
  final startingBalance = accounts.fold<double>(0, (s, a) => s + a.balance);
  // Heuristic defaults
  final monthlyContribution =
      (startingBalance * 0.002).clamp(100, 1500); // ~0.2% of assets
  return ScenarioInputs(
    monthlyContribution: monthlyContribution.toDouble(),
    expectedReturn: 0.07,
    volatility: 0.15,
    goalAmount: (startingBalance * 3).clamp(50000, 1000000),
    years: 30,
  );
});

// Combined provider that returns current state or defaults
final scenarioInputsProvider = Provider<ScenarioInputs>((ref) {
  return ref.watch(_scenarioInputsProvider) ??
      ref.watch(_defaultScenarioInputsProvider);
});

final scenarioResultProvider = FutureProvider<MonteCarloResult?>((ref) async {
  final inputs = ref.watch(scenarioInputsProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final baseCurrency = settings?.baseCurrency ?? 'USD';
  final displayCurrency = settings?.currency ?? 'USD';

  return accountsAsync.maybeWhen(
    data: (accounts) async {
      final baseBalance = accounts.fold<double>(0, (s, a) => s + a.balance);

      // Convert balance if needed
      double starting = baseBalance;
      if (baseCurrency != displayCurrency) {
        final exchangeService = ref.watch(exchangeRateServiceProvider);
        final rate =
            await exchangeService.getRate(baseCurrency, displayCurrency);
        starting = baseBalance * rate;
      }

      if (starting <= 0) return null;
      return MonteCarloEngine.run(
        startingBalance: starting,
        monthlyContribution: inputs.monthlyContribution,
        expectedReturn: inputs.expectedReturn,
        stdev: inputs.volatility,
        years: inputs.years,
        goalAmount: inputs.goalAmount,
        simulations: 750,
      );
    },
    orElse: () async => null,
  );
});

// --- Scenario B (Comparison) Support ---
final compareEnabledProvider = StateProvider<bool>((_) => false);

final _scenarioInputsBProvider = StateProvider<ScenarioInputs?>((ref) {
  // Start as a clone of A when comparison first enabled; null means disabled
  return null;
});

final scenarioResultBProvider = FutureProvider<MonteCarloResult?>((ref) async {
  final enabled = ref.watch(compareEnabledProvider);
  if (!enabled) return null;
  final inputsB = ref.watch(_scenarioInputsBProvider);
  if (inputsB == null) return null;
  final accountsAsync = ref.watch(accountsProvider);
  final settings = ref.watch(settingsProvider).valueOrNull;
  final baseCurrency = settings?.baseCurrency ?? 'USD';
  final displayCurrency = settings?.currency ?? 'USD';

  return accountsAsync.maybeWhen(
    data: (accounts) async {
      final baseBalance = accounts.fold<double>(0, (s, a) => s + a.balance);

      // Convert balance if needed
      double starting = baseBalance;
      if (baseCurrency != displayCurrency) {
        final exchangeService = ref.watch(exchangeRateServiceProvider);
        final rate =
            await exchangeService.getRate(baseCurrency, displayCurrency);
        starting = baseBalance * rate;
      }

      if (starting <= 0) return null;
      return MonteCarloEngine.run(
        startingBalance: starting,
        monthlyContribution: inputsB.monthlyContribution,
        expectedReturn: inputsB.expectedReturn,
        stdev: inputsB.volatility,
        years: inputsB.years,
        goalAmount: inputsB.goalAmount,
        simulations: 750,
      );
    },
    orElse: () async => null,
  );
});

class _ComparisonDeltas {
  final double successDelta;
  final double medianDelta;
  final double p10Delta;
  final double p90Delta;
  const _ComparisonDeltas({
    required this.successDelta,
    required this.medianDelta,
    required this.p10Delta,
    required this.p90Delta,
  });
}

final scenarioComparisonDeltasProvider = Provider<_ComparisonDeltas?>((ref) {
  final aAsync = ref.watch(scenarioResultProvider);
  final bAsync = ref.watch(scenarioResultBProvider);

  final a = aAsync.valueOrNull;
  final b = bAsync.valueOrNull;

  if (a == null || b == null) return null;
  return _ComparisonDeltas(
    successDelta: b.successProbability - a.successProbability,
    medianDelta: b.medianEnding - a.medianEnding,
    p10Delta: b.p10Ending - a.p10Ending,
    p90Delta: b.p90Ending - a.p90Ending,
  );
});

class ScenarioEngineScreen extends ConsumerWidget {
  const ScenarioEngineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.scenarioEngine)),
        body: Center(child: Text('Error: $e')),
      ),
      data: (settings) {
        if (!settings.isPro) {
          return _buildUpgradeGate(context);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('What-If Scenario Engine'),
            actions: [
              IconButton(
                tooltip: 'Back to Dashboard',
                onPressed: () => context.go(AppRouter.dashboard),
                icon: const Icon(Icons.home_outlined),
              ),
            ],
          ),
          body: const _ScenarioBody(),
        );
      },
    );
  }

  Widget _buildUpgradeGate(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('What-If Scenario Engine')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.psychology, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Unlock Scenario Modeling',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Answer: "Am I on track?" • See probability of hitting your goals and how small changes compound.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.push(AppRouter.pro),
                child: Text(AppLocalizations.of(context)!.upgradeToProTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScenarioBody extends ConsumerWidget {
  const _ScenarioBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputs = ref.watch(scenarioInputsProvider);
    final resultAsync = ref.watch(scenarioResultProvider);
    final compareEnabled = ref.watch(compareEnabledProvider);
    final resultBAsync = ref.watch(scenarioResultBProvider);
    final deltas = ref.watch(scenarioComparisonDeltasProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout flag reserved for future responsive enhancements
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _InputCard(
                    inputs: inputs,
                    label: 'Scenario A',
                    onCloneToB: () {
                      ref.read(compareEnabledProvider.notifier).state = true;
                      ref.read(_scenarioInputsBProvider.notifier).state =
                          inputs.copyWith();
                    },
                  ),
                  resultAsync.when(
                    data: (result) => result != null
                        ? _ResultsCard(result: result, label: 'A')
                        : const SizedBox(),
                    loading: () => const SizedBox(
                      width: 360,
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(),
                  ),
                  if (compareEnabled)
                    _InputCard(
                      inputs: ref.watch(_scenarioInputsBProvider) ?? inputs,
                      label: 'Scenario B',
                      onDisable: () {
                        ref.read(compareEnabledProvider.notifier).state = false;
                        ref.read(_scenarioInputsBProvider.notifier).state =
                            null;
                      },
                      isSecondary: true,
                      onChanged: (updated) => ref
                          .read(_scenarioInputsBProvider.notifier)
                          .state = updated,
                    ),
                  if (compareEnabled)
                    resultBAsync.when(
                      data: (resultB) => resultB != null
                          ? _ResultsCard(result: resultB, label: 'B')
                          : const SizedBox(),
                      loading: () => const SizedBox(
                        width: 360,
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                  if (deltas != null)
                    _DeltaCard(
                      deltas: deltas,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              resultAsync.when(
                data: (result) {
                  if (result == null) return const SizedBox();
                  return _DistributionPreview(
                    result: result,
                    altResult: resultBAsync.valueOrNull,
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InputCard extends ConsumerWidget {
  final ScenarioInputs inputs;
  final String label;
  final bool isSecondary;
  final VoidCallback? onCloneToB;
  final VoidCallback? onDisable;
  final ValueChanged<ScenarioInputs>? onChanged; // for secondary editing
  const _InputCard({
    required this.inputs,
    this.label = 'Inputs',
    this.isSecondary = false,
    this.onCloneToB,
    this.onDisable,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.maybeWhen(
      data: (settings) => settings.currency,
      orElse: () => 'USD',
    );

    return SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (!isSecondary && onCloneToB != null)
                    TextButton.icon(
                      onPressed: onCloneToB,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Compare'),
                    ),
                  if (isSecondary && onDisable != null)
                    IconButton(
                      tooltip: 'Remove comparison',
                      icon: const Icon(Icons.close),
                      onPressed: onDisable,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _slider(
                label: 'Monthly Contribution',
                value: inputs.monthlyContribution,
                min: 50,
                max: 5000,
                format: (v) => CurrencyFormatter.format(v, currency),
                onChanged: (v) {
                  final updated =
                      inputs.copyWith(monthlyContribution: v.roundToDouble());
                  if (isSecondary && onChanged != null) {
                    onChanged!(updated);
                  } else {
                    ref.read(_scenarioInputsProvider.notifier).state = updated;
                  }
                },
              ),
              _slider(
                label: 'Expected Return',
                value: inputs.expectedReturn * 100,
                min: 2,
                max: 12,
                format: (v) => '${v.toStringAsFixed(1)}%',
                onChanged: (v) {
                  final updated = inputs.copyWith(expectedReturn: v / 100);
                  if (isSecondary && onChanged != null) {
                    onChanged!(updated);
                  } else {
                    ref.read(_scenarioInputsProvider.notifier).state = updated;
                  }
                },
              ),
              _slider(
                label: 'Volatility',
                value: inputs.volatility * 100,
                min: 5,
                max: 30,
                format: (v) => '${v.toStringAsFixed(0)}%',
                onChanged: (v) {
                  final updated = inputs.copyWith(volatility: v / 100);
                  if (isSecondary && onChanged != null) {
                    onChanged!(updated);
                  } else {
                    ref.read(_scenarioInputsProvider.notifier).state = updated;
                  }
                },
              ),
              _slider(
                label: 'Years',
                value: inputs.years.toDouble(),
                min: 5,
                max: 50,
                format: (v) => v.toStringAsFixed(0),
                onChanged: (v) {
                  final updated = inputs.copyWith(years: v.round());
                  if (isSecondary && onChanged != null) {
                    onChanged!(updated);
                  } else {
                    ref.read(_scenarioInputsProvider.notifier).state = updated;
                  }
                },
              ),
              _slider(
                label: 'Goal Amount',
                value: inputs.goalAmount,
                min: 20000,
                max: 2000000,
                format: (v) => CurrencyFormatter.format(v, currency),
                onChanged: (v) {
                  final updated =
                      inputs.copyWith(goalAmount: v.roundToDouble());
                  if (isSecondary && onChanged != null) {
                    onChanged!(updated);
                  } else {
                    ref.read(_scenarioInputsProvider.notifier).state = updated;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              format(value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: format(value),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ResultsCard extends ConsumerWidget {
  final MonteCarloResult result;
  final String label; // A or B
  const _ResultsCard({required this.result, this.label = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const SizedBox();
    final currency = settings.currency;
    final pct = NumberFormat.percentPattern();
    return SizedBox(
      width: 360,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Results ${label.isNotEmpty ? label : ''}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _statRow(
                'Success Probability',
                pct.format(result.successProbability),
              ),
              _statRow(
                'Median Ending',
                CurrencyFormatter.format(result.medianEnding, currency),
              ),
              _statRow(
                '10th Percentile',
                CurrencyFormatter.format(result.p10Ending, currency),
              ),
              _statRow(
                '90th Percentile',
                CurrencyFormatter.format(result.p90Ending, currency),
              ),
              const SizedBox(height: 12),
              Text(
                'Simulations: ${result.simulations}\nYears: ${result.years}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DistributionPreview extends StatelessWidget {
  final MonteCarloResult result;
  final MonteCarloResult? altResult;
  const _DistributionPreview({required this.result, this.altResult});

  @override
  Widget build(BuildContext context) {
    final values = result.endingValues;
    if (values.isEmpty) return const SizedBox();
    final minV = values.first;
    final maxV = values.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribution (sorted outcomes)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _DistributionPainter(
                  values: values,
                  min: minV,
                  max: maxV,
                  altValues: altResult?.endingValues,
                ),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionPainter extends CustomPainter {
  final List<double> values;
  final double min;
  final double max;
  final List<double>? altValues;
  _DistributionPainter({
    required this.values,
    required this.min,
    required this.max,
    this.altValues,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final paint = Paint()
      ..color = Colors.orange.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final norm = (values[i] - min) / (max - min + 1e-9);
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    if (altValues != null && altValues!.isNotEmpty) {
      final sorted = [...altValues!];
      sorted.sort();
      final min2 = sorted.first;
      final max2 = sorted.last;
      final path2 = Path();
      final paint2 = Paint()
        ..color = Colors.blue.shade400
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (int i = 0; i < sorted.length; i++) {
        final x = i / (sorted.length - 1) * size.width;
        final norm = (sorted[i] - min2) / (max2 - min2 + 1e-9);
        final y = size.height - norm * size.height;
        if (i == 0) {
          path2.moveTo(x, y);
        } else {
          path2.lineTo(x, y);
        }
      }
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DeltaCard extends ConsumerWidget {
  final _ComparisonDeltas deltas;
  const _DeltaCard({required this.deltas});

  String _fmtPct(double v) =>
      '${(v * 100).toStringAsFixed(v.abs() < 0.01 ? 2 : 1)}%';
  String _fmtCurrency(double v, String currency) {
    return CurrencyFormatter.format(v.abs() * (v < 0 ? -1 : 1), currency);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    if (settings == null) return const SizedBox();
    final currency = settings.currency;
    Color colorFor(double v) =>
        v >= 0 ? Colors.green.shade600 : Theme.of(context).colorScheme.error;
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deltas (B - A)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _row(
                'Success Prob',
                _fmtPct(deltas.successDelta),
                colorFor(deltas.successDelta),
              ),
              _row(
                'Median',
                _fmtCurrency(deltas.medianDelta, currency),
                colorFor(deltas.medianDelta),
              ),
              _row(
                'P10',
                _fmtCurrency(deltas.p10Delta, currency),
                colorFor(deltas.p10Delta),
              ),
              _row(
                'P90',
                _fmtCurrency(deltas.p90Delta, currency),
                colorFor(deltas.p90Delta),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      );
}
