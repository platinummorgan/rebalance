import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';

// Simple heuristic yields (could be refined later or user-configurable)
const _defaultYields = <String, double>{
  'cash': 0.005,
  'bonds': 0.04,
  'usEq': 0.02, // dividend yield portion taxed
  'intlEq': 0.03,
  'realEstate': 0.04,
  'alt': 0.03,
};

// Tax rate assumptions (ordinary vs qualified/long-term)
class TaxAssumptions {
  final double ordinaryRate; // e.g. 24%
  final double qualifiedDivRate; // e.g. 15%
  const TaxAssumptions(
      {this.ordinaryRate = 0.24, this.qualifiedDivRate = 0.15,});
}

// Classification of account kind -> tax bucket
enum TaxBucket { taxable, taxDeferred, taxFree }

TaxBucket classifyAccount(String kind) {
  // crude mapping for MVP
  if (kind == 'retirement' || kind == 'hsa' || kind == '_529') {
    return TaxBucket.taxDeferred; // treat HSA/529 similarly for drag removal
  }
  // Could differentiate Roth vs Traditional later. For simplicity we treat all as taxDeferred (no current drag) except we might model Roth as taxFree later.
  return TaxBucket.taxable;
}

class TaxSmartMove {
  final String description;
  final double annualImpact; // positive = savings
  TaxSmartMove({required this.description, required this.annualImpact});
}

class TaxSmartAnalysis {
  final double currentDrag;
  final double optimizedDrag;
  final double savings;
  final List<TaxSmartMove> moves;
  final NumberFormat currencyFmt;
  final String assumptionsText;

  TaxSmartAnalysis({
    required this.currentDrag,
    required this.optimizedDrag,
    required this.savings,
    required this.moves,
    required this.currencyFmt,
    required this.assumptionsText,
  });

  double get dragReductionRatio =>
      currentDrag == 0 ? 0 : (currentDrag - optimizedDrag) / currentDrag;
}

final taxAssumptionsProvider =
    Provider<TaxAssumptions>((_) => const TaxAssumptions());

// Family provider so screen can pass current accounts cheaply.
final taxSmartAnalysisProvider =
    FutureProvider.family<TaxSmartAnalysis, List<Account>>(
        (ref, accounts) async {
  final assumptions = ref.watch(taxAssumptionsProvider);
  final fmt = NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 0);
  if (accounts.isEmpty) {
    return TaxSmartAnalysis(
      currentDrag: 0,
      optimizedDrag: 0,
      savings: 0,
      moves: const [],
      currencyFmt: fmt,
      assumptionsText: _assumptionsText(assumptions),
    );
  }

  // Aggregate assets by account bucket
  final Map<TaxBucket, Map<String, double>> bucketAlloc = {
    TaxBucket.taxable: {},
    TaxBucket.taxDeferred: {},
    TaxBucket.taxFree: {}, // currently unused but reserved
  };

  void addAlloc(TaxBucket b, String key, double amount) {
    bucketAlloc[b]![key] = (bucketAlloc[b]![key] ?? 0) + amount;
  }

  // totalAssets reserved for future ratio metrics
  double totalAssets = 0; // ignore: unused_local_variable
  for (final a in accounts) {
    totalAssets += a.balance;
    final b = classifyAccount(a.kind);
    addAlloc(b, 'cash', a.balance * a.pctCash);
    addAlloc(b, 'bonds', a.balance * a.pctBonds);
    addAlloc(b, 'usEq', a.balance * a.pctUsEq);
    addAlloc(b, 'intlEq', a.balance * a.pctIntlEq);
    addAlloc(b, 'realEstate', a.balance * a.pctRealEstate);
    addAlloc(b, 'alt', a.balance * a.pctAlt);
  }

  double taxDragForBucket(TaxBucket b, Map<String, double> alloc) {
    double drag = 0;
    alloc.forEach((asset, amount) {
      final y = _defaultYields[asset] ?? 0.0;
      double effectiveRate = 0;
      if (b == TaxBucket.taxable) {
        // Simple rule: bonds, realEstate, alt taxed at ordinary; equities mixed (qualifiedDivRate)
        if (asset == 'bonds' ||
            asset == 'realEstate' ||
            asset == 'alt' ||
            asset == 'cash') {
          effectiveRate = assumptions.ordinaryRate;
        } else {
          // equities
          effectiveRate = assumptions.qualifiedDivRate;
        }
      } else {
        effectiveRate = 0; // no current drag in tax-advantaged for MVP
      }
      drag += amount * y * effectiveRate;
    });
    return drag;
  }

  final currentDrag = bucketAlloc.entries
      .fold<double>(0, (s, e) => s + taxDragForBucket(e.key, e.value));

  // Optimization heuristic: move highest ordinary-income assets currently in taxable into taxDeferred space capacity.
  // Determine capacity: sum of taxDeferred balances (they can host any assets). We'll treat reallocation notionally: we only care about taxable portion reduction.
  final taxableAlloc = bucketAlloc[TaxBucket.taxable]!;
  final taxDeferredAlloc = bucketAlloc[TaxBucket.taxDeferred]!;

  // Identify movable amounts: bonds, realEstate, alt in taxable.
  final movableAssets = ['bonds', 'realEstate', 'alt', 'cash'];
  // Sort by yield * ordinary rate descending (most expensive drag first)
  final candidates = <MapEntry<String, double>>[];
  for (final a in movableAssets) {
    final amt = taxableAlloc[a] ?? 0;
    if (amt > 0) {
      final y = _defaultYields[a] ?? 0.0;
      final dragPerDollar = y * assumptions.ordinaryRate;
      candidates.add(MapEntry(a, dragPerDollar));
    }
  }
  candidates.sort((a, b) => b.value.compareTo(a.value));

  final moves = <TaxSmartMove>[];
  double optimizedDrag = currentDrag;
  // We'll simulate moving each candidate fully into taxDeferred (if any taxDeferred exists; capacity concept simplified)
  final hasTaxDeferred =
      taxDeferredAlloc.values.fold<double>(0, (s, v) => s + v) > 0;
  if (hasTaxDeferred) {
    for (final c in candidates) {
      final asset = c.key;
      final amt = taxableAlloc[asset] ?? 0;
      if (amt <= 0) continue;
      final y = _defaultYields[asset] ?? 0.0;
      final currentAssetDrag = amt *
          y *
          ((asset == 'bonds' ||
                  asset == 'realEstate' ||
                  asset == 'alt' ||
                  asset == 'cash')
              ? assumptions.ordinaryRate
              : assumptions.qualifiedDivRate);
      // After move, assume zero current drag for that amount.
      optimizedDrag -= currentAssetDrag;
      moves.add(TaxSmartMove(
        description:
            'Move ${fmt.format(amt)} of $asset to tax-advantaged account',
        annualImpact: currentAssetDrag,
      ),);
    }
  }

  final savings =
      (currentDrag - optimizedDrag).clamp(0, double.infinity).toDouble();

  return TaxSmartAnalysis(
    currentDrag: currentDrag,
    optimizedDrag: optimizedDrag,
    savings: savings,
    moves: moves,
    currencyFmt: fmt,
    assumptionsText: _assumptionsText(assumptions),
  );
});

String _assumptionsText(TaxAssumptions a) => 'Methodology:\n'
    '- Estimates annual tax drag = asset_amount * yield * effective_tax_rate for taxable accounts only.\n'
    '- Yields used (simplified, can be customized later): bonds 4%, intl 3%, US equity 2%, real estate 4%, alternatives 3%, cash 0.5%.\n'
    '- Ordinary income tax rate: ${(a.ordinaryRate * 100).toStringAsFixed(0)}%; qualified dividend rate: ${(a.qualifiedDivRate * 100).toStringAsFixed(0)}%.\n'
    '- Optimization heuristic: move highest drag assets (bonds/real estate/alts/cash) out of taxable into any tax-advantaged space.\n'
    '- Does not model capital gains realization, wash sale, or foreign tax credits. Savings = reduction in ongoing annual drag only.';
