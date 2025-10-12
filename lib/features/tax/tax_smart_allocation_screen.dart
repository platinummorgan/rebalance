import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app.dart';
import 'package:go_router/go_router.dart';
import '../../data/models.dart';
import '../../routes.dart' show AppRouter;
import 'tax_smart_service.dart';

class TaxSmartAllocationScreen extends ConsumerWidget {
  const TaxSmartAllocationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return settingsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (settings) {
        if (!settings.isPro) {
          return _buildGate(context);
        }
        final accounts = accountsAsync.valueOrNull ?? const <Account>[];
        final analysis = ref.watch(taxSmartAnalysisProvider(accounts));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tax-Smart Allocation'),
            actions: [
              IconButton(
                tooltip: 'Dashboard',
                onPressed: () => context.go(AppRouter.dashboard),
                icon: const Icon(Icons.home_outlined),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: analysis.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
              data: (a) => _BuildAnalysis(a: a),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGate(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tax-Smart Allocation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calculate, size: 72, color: Colors.teal),
              const SizedBox(height: 16),
              const Text('Unlock Tax Optimization',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              const SizedBox(height: 8),
              const Text(
                  'See estimated annual tax drag and how to reduce it with better asset location.',
                  textAlign: TextAlign.center,),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.push(AppRouter.pro),
                child: const Text('Upgrade to Pro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildAnalysis extends StatelessWidget {
  final TaxSmartAnalysis a;
  const _BuildAnalysis({required this.a});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryHeader(a: a),
        const SizedBox(height: 16),
        _Recommendations(a: a),
        const SizedBox(height: 24),
        _Assumptions(a: a),
      ],
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final TaxSmartAnalysis a;
  const _SummaryHeader({required this.a});

  @override
  Widget build(BuildContext context) {
    final currency = a.currencyFmt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated Annual Tax Savings',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(currency.format(a.currentDrag),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.redAccent,),),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 18),
                const SizedBox(width: 12),
                Text(currency.format(a.optimizedDrag),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,),),
              ],
            ),
            const SizedBox(height: 8),
            Text('Potential Savings: ${currency.format(a.savings)} / yr',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.green,),),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: a.dragReductionRatio.clamp(0, 1),
              backgroundColor: Colors.red.withValues(alpha: .2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _Recommendations extends StatelessWidget {
  final TaxSmartAnalysis a;
  const _Recommendations({required this.a});

  @override
  Widget build(BuildContext context) {
    if (a.moves.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Your assets are already tax-efficiently located. 👍',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,),),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Suggested Reallocation',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),),
            const SizedBox(height: 8),
            for (final m in a.moves)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz),
                title: Text(m.description),
                subtitle: Text(
                    'Est. yearly impact: ${a.currencyFmt.format(m.annualImpact)}',),
              ),
          ],
        ),
      ),
    );
  }
}

class _Assumptions extends StatelessWidget {
  final TaxSmartAnalysis a;
  const _Assumptions({required this.a});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Assumptions & Methodology'),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Text(a.assumptionsText,
            style: const TextStyle(fontSize: 12, height: 1.4),),
      ],
    );
  }
}
