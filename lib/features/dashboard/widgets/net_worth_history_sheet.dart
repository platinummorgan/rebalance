import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app.dart';
import '../../../data/models.dart';
import '../../../data/snapshot_service.dart';
import '../../../generated/app_localizations.dart';
import '../../../routes.dart' show AppRouter;
import '../../../utils/currency_formatter.dart';
import '../../../utils/csv_exporter.dart';
import '../../../widgets/currency_text.dart';

class NetWorthHistorySheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const NetWorthHistorySheet({
    super.key,
    required this.scrollController,
  });

  @override
  ConsumerState<NetWorthHistorySheet> createState() =>
      _NetWorthHistorySheetState();
}

class SnapshotDiff {
  final DateTime from;
  final DateTime to;
  final List<BucketDiff> buckets;
  final double assetsFrom;
  final double assetsTo;
  final double liabilitiesFrom;
  final double liabilitiesTo;
  final double netFrom;
  final double netTo;
  final double netDelta;

  SnapshotDiff({
    required this.from,
    required this.to,
    required this.buckets,
    required this.assetsFrom,
    required this.assetsTo,
    required this.liabilitiesFrom,
    required this.liabilitiesTo,
    required this.netFrom,
    required this.netTo,
    required this.netDelta,
  });
}

class BucketDiff {
  final String name;
  final double from;
  final double to;
  final double delta;
  final double
      deltaPct; // Percentage change vs total assets from 'from' snapshot

  BucketDiff({
    required this.name,
    required this.from,
    required this.to,
    required this.delta,
    required this.deltaPct,
  });
}

class SavedComparison {
  final String id;
  final String name;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime createdAt;
  final double netFrom;
  final double netTo;
  final double netDelta;

  SavedComparison({
    required this.id,
    required this.name,
    required this.fromDate,
    required this.toDate,
    required this.createdAt,
    required this.netFrom,
    required this.netTo,
    required this.netDelta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fromDate': fromDate.millisecondsSinceEpoch,
      'toDate': toDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'netFrom': netFrom,
      'netTo': netTo,
      'netDelta': netDelta,
    };
  }

  factory SavedComparison.fromMap(Map<String, dynamic> map) {
    return SavedComparison(
      id: map['id'],
      name: map['name'],
      fromDate: DateTime.fromMillisecondsSinceEpoch(map['fromDate']),
      toDate: DateTime.fromMillisecondsSinceEpoch(map['toDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      netFrom: map['netFrom'],
      netTo: map['netTo'],
      netDelta: map['netDelta'],
    );
  }
}

class _NetWorthHistorySheetState extends ConsumerState<NetWorthHistorySheet> {
  String selectedTimeframe = '30d';
  final timeframes = ['7d', '30d', '90d', '1y', 'All'];
  bool isCompareMode = false;
  Snapshot? compareFromSnapshot;
  Snapshot? compareToSnapshot;

  // Helper to get currency
  String get _currency => ref.read(settingsProvider).value?.currency ?? 'USD';

  // Delta calculation based on your specification
  Map<String, dynamic> calculateDelta(
    List<Snapshot> snapshots,
    int horizonDays,
  ) {
    if (snapshots.isEmpty) return {'abs': 0.0, 'pct': 0.0};

    final latest = snapshots.last;
    final cutoff = latest.at.subtract(Duration(days: horizonDays));
    final prior = snapshots.reversed.firstWhere(
      (s) => s.at.isBefore(cutoff) || s.at.isAtSameMomentAs(cutoff),
      orElse: () => snapshots.first,
    );

    final absDelta = latest.netWorth - prior.netWorth;
    final pctDelta =
        absDelta / (prior.netWorth.abs() < 1 ? 1 : prior.netWorth.abs());

    return {'abs': absDelta, 'pct': pctDelta};
  }

  int getHorizonDays(String timeframe) {
    switch (timeframe) {
      case '7d':
        return 7;
      case '30d':
        return 30;
      case '90d':
        return 90;
      case '1y':
        return 365;
      default:
        return 30;
    }
  }

  String _getDeltaTimeframe(List<Snapshot> snapshots, int currentIndex) {
    // Find the closest prior snapshot within 30 days or use the nearest prior
    final current = snapshots[currentIndex];
    final thirtyDaysAgo = current.at.subtract(const Duration(days: 30));

    // Look for closest snapshot within 30 days
    Snapshot? priorSnapshot;
    for (int i = currentIndex + 1; i < snapshots.length; i++) {
      final candidate = snapshots[i];
      if (candidate.at.isAfter(thirtyDaysAgo)) {
        priorSnapshot = candidate;
        break;
      }
    }

    // If no snapshot within 30 days, use the nearest prior
    priorSnapshot ??= (currentIndex + 1 < snapshots.length)
        ? snapshots[currentIndex + 1]
        : null;

    if (priorSnapshot == null) return '1d';

    final daysDiff = current.at.difference(priorSnapshot.at).inDays;
    if (daysDiff <= 1) return '1d';
    if (daysDiff <= 7) return '7d';
    if (daysDiff <= 30) return '30d';
    return '${daysDiff}d';
  }

  @override
  Widget build(BuildContext context) {
    final snapshotsAsync = ref.watch(snapshotsProvider);

    return snapshotsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (snapshots) => _buildContent(context, snapshots),
    );
  }

  Widget _buildContent(BuildContext context, List<Snapshot> snapshots) {
    final currency = _currency;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Worth History',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshots.length} snapshots tracked',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons row
          Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final snapshotsAsync = ref.watch(snapshotsProvider);
                  final snapshots = snapshotsAsync.maybeWhen(
                    data: (data) => data,
                    orElse: () => <Snapshot>[],
                  );
                  final hasEnoughSnapshots = snapshots.length >= 2;

                  return Tooltip(
                    message: hasEnoughSnapshots
                        ? 'Compare snapshots'
                        : 'Create another snapshot to compare',
                    child: OutlinedButton.icon(
                      onPressed: hasEnoughSnapshots
                          ? () => _showCompareDialog(context)
                          : null,
                      icon: Icon(
                        Icons.compare_arrows,
                        size: 18,
                        color: hasEnoughSnapshots
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: .4),
                      ),
                      label: const Text('Compare'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        foregroundColor: hasEnoughSnapshots
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                        side: BorderSide(
                          color: hasEnoughSnapshots
                              ? Theme.of(context).colorScheme.outline
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, _) => OutlinedButton.icon(
                  onPressed: () => _createManualSnapshot(context, ref),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Create'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showSavedComparisonsDialog(context),
                icon: const Icon(Icons.bookmark, size: 18),
                label: const Text('Saved'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeframe filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: timeframes.map((timeframe) {
                final isSelected = selectedTimeframe == timeframe;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(timeframe),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedTimeframe = timeframe;
                        });
                      }
                    },
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Snapshots list
          Expanded(
            child: snapshots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No history yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Snapshots are automatically created\nwhen you update your accounts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: snapshots.length,
                    itemBuilder: (context, index) {
                      final snapshot = snapshots[
                          snapshots.length - 1 - index]; // Reverse order
                      final isLatest = index == 0;

                      // Calculate delta for this snapshot
                      final horizonDays = selectedTimeframe == 'All'
                          ? 99999
                          : getHorizonDays(selectedTimeframe);
                      final delta = calculateDelta(
                        snapshots.take(snapshots.length - index).toList(),
                        horizonDays,
                      );
                      final deltaAbs = delta['abs'] as double;
                      final isPositive = deltaAbs >= 0;

                      // Get recent snapshots for sparkline (6-12 most recent including this one)
                      final sparklineSnapshots = snapshots
                          .take(snapshots.length - index)
                          .toList()
                          .reversed
                          .take(12)
                          .toList()
                          .reversed
                          .toList();

                      final isSelected = isCompareMode &&
                          (compareFromSnapshot == snapshot ||
                              compareToSnapshot == snapshot);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        surfaceTintColor:
                            Theme.of(context).colorScheme.surfaceTint,
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.5)
                            : null,
                        child: ListTile(
                          onTap: () => isCompareMode
                              ? _handleCompareSelection(snapshot)
                              : _showSnapshotDetail(context, snapshot),
                          onLongPress: () =>
                              _showSnapshotContextMenu(context, snapshot),
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(
                                        snapshot.netWorth,
                                        currency,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, yyyy • h:mm a')
                                          .format(snapshot.at),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    // Delta indicator under timestamp
                                    if (deltaAbs.abs() > 0.01) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '${isPositive ? '▲' : '▼'} ${isPositive ? '+' : '−'}${CurrencyFormatter.formatCompact(deltaAbs.abs(), currency)} (${_getDeltaTimeframe(snapshots, index)})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isPositive
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Latest or Manual badge
                                  if (isLatest)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Latest',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else if (snapshot.source == 'manual')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Manual',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: sparklineSnapshots.length > 1
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SizedBox(
                                    height: 20,
                                    child: _buildTinyRowSparkline(
                                      sparklineSnapshots,
                                      isPositive,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyRowSparkline(List<Snapshot> snapshots, bool isPositive) {
    return CustomPaint(
      painter: TinySparklinePainter(
        snapshots: snapshots,
        color: isPositive ? Colors.green : Colors.red,
      ),
      size: const Size(60, 20),
    );
  }

  void _createManualSnapshot(BuildContext context, WidgetRef ref) async {
    try {
      // Create snapshot using the same service as automatic snapshots
      final snapshot = await SnapshotService.createCurrentSnapshot();

      // Add to state using ref
      await ref.read(snapshotsProvider.notifier).addSnapshot(snapshot);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Snapshot saved · ${DateFormat('MMM d, h:mm a').format(DateTime.now())}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to create snapshot: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create snapshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSnapshotDetail(BuildContext context, Snapshot snapshot) {
    // Find prior snapshot for delta calculations
    final snapshotsAsync = ref.watch(snapshotsProvider);
    final snapshots = snapshotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Snapshot>[],
    );
    final currentIndex = snapshots.indexOf(snapshot);
    final priorSnapshot = currentIndex > 0 ? snapshots[currentIndex - 1] : null;

    // Calculate totals and validation
    final assetsTotal = snapshot.assetsTotal;
    final expectedTotal = snapshot.cashTotal +
        snapshot.bondsTotal +
        snapshot.usEqTotal +
        snapshot.intlEqTotal +
        snapshot.reTotal +
        snapshot.altTotal;
    final hasMathError = (assetsTotal - expectedTotal).abs() >= 1.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Snapshot Detail'),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // As-of + source row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at)} • ${snapshot.source.substring(0, 1).toUpperCase()}${snapshot.source.substring(1)}',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Delta vs prior snapshot
                          Consumer(
                            builder: (context, ref, _) {
                              final snapshots = ref.watch(snapshotsProvider);
                              return snapshots.when(
                                data: (snapshotList) {
                                  final currentIndex = snapshotList
                                      .indexWhere((s) => s.at == snapshot.at);
                                  if (currentIndex < snapshotList.length - 1) {
                                    final priorSnapshot =
                                        snapshotList[currentIndex + 1];
                                    return _buildDeltaVsPrior(
                                      context,
                                      snapshot,
                                      priorSnapshot,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (snapshot.note != null && snapshot.note!.isNotEmpty)
                      IconButton(
                        onPressed: () => _showSnapshotNote(context, snapshot),
                        icon: Icon(
                          Icons.note_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: 'View note',
                      ),
                  ],
                ),

                // Delta vs prior snapshot
                if (priorSnapshot != null) ...[
                  const SizedBox(height: 8),
                  _buildDeltaVsPrior(context, snapshot, priorSnapshot),
                ],

                const SizedBox(height: 20),

                // Assets section
                Text(
                  'Assets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Values and % of total assets',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                _buildEnhancedAssetRow(
                  context,
                  'Cash',
                  snapshot.cashTotal,
                  assetsTotal,
                  priorSnapshot?.cashTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Bonds',
                  snapshot.bondsTotal,
                  assetsTotal,
                  priorSnapshot?.bondsTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'US Equity',
                  snapshot.usEqTotal,
                  assetsTotal,
                  priorSnapshot?.usEqTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Intl Equity',
                  snapshot.intlEqTotal,
                  assetsTotal,
                  priorSnapshot?.intlEqTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Real Estate',
                  snapshot.reTotal,
                  assetsTotal,
                  priorSnapshot?.reTotal,
                ),
                _buildEnhancedAssetRow(
                  context,
                  'Alternatives',
                  snapshot.altTotal,
                  assetsTotal,
                  priorSnapshot?.altTotal,
                ),

                const SizedBox(height: 16),

                // Assets total with validation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Assets Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (hasMathError) ...[
                            const SizedBox(width: 8),
                            Tooltip(
                              message:
                                  'Doesn\'t add up - rounding difference detected',
                              child: Icon(
                                Icons.warning_outlined,
                                size: 16,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(assetsTotal, _currency),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (priorSnapshot != null) ...[
                            const SizedBox(height: 2),
                            _buildDeltaText(
                              assetsTotal - priorSnapshot.assetsTotal,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liabilities section
                Text(
                  'Liabilities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                _buildEnhancedAssetRow(
                  context,
                  'Liabilities',
                  snapshot.liabilitiesTotal,
                  assetsTotal,
                  priorSnapshot?.liabilitiesTotal,
                  isLiability: true,
                ),

                const SizedBox(height: 16),

                // Net Worth total
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Worth',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(
                              snapshot.netWorth,
                              _currency,
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: snapshot.netWorth < 0
                                  ? Colors.red.shade700
                                  : null,
                            ),
                          ),
                          if (priorSnapshot != null) ...[
                            const SizedBox(height: 2),
                            _buildDeltaText(
                              snapshot.netWorth - priorSnapshot.netWorth,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Text(
                  'Educational info only. Not financial advice.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Export buttons
          Consumer(
            builder: (context, ref, child) {
              final snapshotsAsync = ref.watch(snapshotsProvider);
              final snapshots = snapshotsAsync.maybeWhen(
                data: (data) => data,
                orElse: () => <Snapshot>[],
              );
              final hasEnoughSnapshots = snapshots.length >= 2;

              return TextButton.icon(
                onPressed: hasEnoughSnapshots
                    ? () => _exportSnapshotCSV(context, ref, snapshot)
                    : null,
                icon: Icon(
                  Icons.download,
                  size: 16,
                  color: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
                label: Text(
                  'CSV',
                  style: TextStyle(
                    color: hasEnoughSnapshots
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: .4),
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
              );
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final settingsAsync = ref.watch(settingsProvider);
              final isPro = settingsAsync.value?.isPro ?? false;
              final snapshotsAsync = ref.watch(snapshotsProvider);
              final snapshots = snapshotsAsync.maybeWhen(
                data: (data) => data,
                orElse: () => <Snapshot>[],
              );
              final hasEnoughSnapshots = snapshots.length >= 2;

              return TextButton.icon(
                onPressed: hasEnoughSnapshots
                    ? (isPro
                        ? () => _exportSnapshotPDF(context, snapshot)
                        : () => _showProRequiredDialog(context, 'PDF Export'))
                    : null,
                icon: Icon(
                  Icons.picture_as_pdf,
                  size: 16,
                  color: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: .4),
                ),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: hasEnoughSnapshots
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isPro) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: hasEnoughSnapshots
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                style: TextButton.styleFrom(
                  foregroundColor: hasEnoughSnapshots
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.4),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAssetRow(
    BuildContext context,
    String label,
    double value,
    double assetsTotal,
    double? priorValue, {
    bool isLiability = false,
  }) {
    final currency = _currency;

    // Calculate percentage (vs assets, not net worth)
    final percentage = assetsTotal > 0 ? (value / assetsTotal * 100) : 0.0;
    final percentageText =
        assetsTotal > 0 ? '${percentage.toStringAsFixed(1)}%' : '—';

    // Calculate delta vs prior
    final delta = priorValue != null ? value - priorValue : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _navigateToFilteredAccounts(context, label),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyFormatter.format(
                          isLiability ? value : value,
                          currency,
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isLiability ? Colors.red.shade700 : null,
                        ),
                      ),
                      if (!isLiability) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• $percentageText',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (delta != null && delta.abs() > 0.01) ...[
                    const SizedBox(height: 2),
                    _buildDeltaText(delta),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ...existing code...

  Widget _buildDeltaText(double delta) {
    return CurrencyText(
      delta,
      compact: true,
      showSign: true,
      useAbsoluteValue: true,
      style: TextStyle(
        fontSize: 11,
        color: Theme.of(context)
            .colorScheme
            .onSurfaceVariant
            .withValues(alpha: .7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildDeltaVsPrior(
    BuildContext context,
    Snapshot current,
    Snapshot prior,
  ) {
    // Calculate delta
    final deltaAbs = current.netWorth - prior.netWorth;
    final isPositive = deltaAbs >= 0;

    // Calculate time horizon
    final daysDiff = current.at.difference(prior.at).inDays;
    final horizon = daysDiff <= 7 ? '7d' : '30d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            '${isPositive ? '▲ +' : '▼ '}${CurrencyFormatter.formatCompact(deltaAbs.abs(), _currency)} ($horizon)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnapshotNote(BuildContext context, Snapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snapshot Note'),
        content: Text(snapshot.note ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredAccounts(BuildContext context, String assetType) {
    // Find the current snapshot being viewed (we need to pass this info)
    // For now, we'll use a query parameter to indicate we came from a snapshot

    // Close the snapshot detail dialog first
    Navigator.pop(context);

    // Then navigate to accounts screen with asset type filter and snapshot context
    context.push(
      '/accounts?assetType=${Uri.encodeComponent(assetType)}&fromSnapshot=true',
    );
  }

  void _exportSnapshotCSV(
    BuildContext context,
    WidgetRef ref,
    Snapshot snapshot,
  ) async {
    try {
      final csvData = StringBuffer();
      final now = DateTime.now();
      final timezone = now.timeZoneName;

      csvData.writeln('# Rebalance Snapshots Export');
      csvData.writeln('# Generated: ${now.toUtc().toIso8601String()}');
      csvData.writeln('# Timezone: $timezone');
      csvData.writeln('');
      csvData.writeln(
        'timestamp,source,assets_total,liabilities_total,net_worth,cash,bonds,us_equity,intl_equity,real_estate,alternatives',
      );

      final snapshotsAsync = ref.read(snapshotsProvider);
      final snapshots = snapshotsAsync.asData?.value ?? const <Snapshot>[];
      for (final snap in snapshots.reversed) {
        csvData.writeln(
          [
            snap.at.toUtc().toIso8601String(),
            snap.source,
            snap.assetsTotal.toStringAsFixed(2),
            snap.liabilitiesTotal.toStringAsFixed(2),
            snap.netWorth.toStringAsFixed(2),
            snap.cashTotal.toStringAsFixed(2),
            snap.bondsTotal.toStringAsFixed(2),
            snap.usEqTotal.toStringAsFixed(2),
            snap.intlEqTotal.toStringAsFixed(2),
            snap.reTotal.toStringAsFixed(2),
            snap.altTotal.toStringAsFixed(2),
          ].join(','),
        );
      }

      final today = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileBaseName = 'rebalance_snapshots_$today';
      await CsvExporter.save(
        fileName: fileBaseName,
        csvContent: csvData.toString(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads/$fileBaseName.csv'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] Snapshot CSV export failed: $e');
      debugPrint('[Dashboard] Snapshot CSV stack: $stackTrace');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _exportSnapshotPDF(BuildContext context, Snapshot snapshot) {
    // PDF export is a Pro feature that's not yet implemented
    // This function should only be called if user is Pro
    Navigator.pop(context); // Close the snapshot detail dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export coming soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showProRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.proFeature),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!
                  .isAvailableWithRebalancePro(feature),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.upgradeForPdfExports,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.maybeLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Would navigate to Pro screen
            },
            child: Text(AppLocalizations.of(context)!.upgradeToProTitle),
          ),
        ],
      ),
    );
  }

  void _showSnapshotContextMenu(BuildContext context, Snapshot snapshot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            Text(
              'Snapshot Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Compare option
            ListTile(
              leading: Icon(
                Icons.compare_arrows,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Start Compare'),
              subtitle:
                  const Text('Select this as starting point for comparison'),
              onTap: () {
                Navigator.pop(context);
                _enterCompareMode(snapshot);
              },
            ),

            // Delete option
            Consumer(
              builder: (context, ref, _) {
                final snapshotsAsync = ref.watch(snapshotsProvider);
                final snapshots = snapshotsAsync.maybeWhen(
                  data: (data) => data,
                  orElse: () => <Snapshot>[],
                );
                final canDelete = snapshots.length > 1;

                return ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: canDelete ? Colors.red : Colors.grey,
                  ),
                  title: Text(
                    'Delete Snapshot',
                    style: TextStyle(
                      color: canDelete ? Colors.red : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    canDelete
                        ? 'Remove this snapshot permanently'
                        : 'Cannot delete the only remaining snapshot',
                    style: TextStyle(
                      color: canDelete ? null : Colors.grey,
                    ),
                  ),
                  onTap: canDelete
                      ? () {
                          Navigator.pop(context);
                          _confirmDeleteSnapshot(context, snapshot);
                        }
                      : null,
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSnapshot(BuildContext context, Snapshot snapshot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snapshot?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this snapshot?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a')
                              .format(snapshot.at),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                        Text(
                          'Net Worth: ${CurrencyFormatter.format(snapshot.netWorth, _currency)}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          Consumer(
            builder: (context, ref, _) => FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteSnapshot(context, ref, snapshot);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSnapshot(
    BuildContext context,
    WidgetRef ref,
    Snapshot snapshot,
  ) async {
    try {
      // Update the provider (this will handle both repository and state updates)
      await ref.read(snapshotsProvider.notifier).removeSnapshot(snapshot);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Snapshot deleted • ${DateFormat('MMM d, h:mm a').format(snapshot.at)}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete snapshot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _enterCompareMode(Snapshot snapshot) {
    setState(() {
      isCompareMode = true;
      compareFromSnapshot = snapshot;
      compareToSnapshot = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Compare mode: Select another snapshot to compare with ${DateFormat('MMM d').format(snapshot.at)}',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () => _exitCompareMode(),
        ),
      ),
    );
  }

  void _handleCompareSelection(Snapshot snapshot) {
    if (compareFromSnapshot == snapshot) {
      // Same snapshot selected, exit compare mode
      _exitCompareMode();
      return;
    }

    setState(() {
      compareToSnapshot = snapshot;
    });

    _showSnapshotComparison();
  }

  void _exitCompareMode() {
    setState(() {
      isCompareMode = false;
      compareFromSnapshot = null;
      compareToSnapshot = null;
    });
  }

  void _showSnapshotComparison() {
    if (compareFromSnapshot == null || compareToSnapshot == null) return;

    final diff =
        _calculateSnapshotDiff(compareFromSnapshot!, compareToSnapshot!);

    showDialog(
      context: context,
      builder: (context) => _CompareSnapshotsDialog(
        diff: diff,
        onSaveComparison: () => _saveComparison(diff),
        currency: _currency,
      ),
    );

    _exitCompareMode();
  }

  SnapshotDiff _calculateSnapshotDiff(Snapshot from, Snapshot to) {
    // Calculate total assets from 'from' snapshot for percentage calculations
    final assetsFrom = from.cashTotal +
        from.bondsTotal +
        from.usEqTotal +
        from.intlEqTotal +
        from.reTotal +
        from.altTotal;

    double calculateBucketPct(double delta) {
      return assetsFrom > 0 ? delta / assetsFrom : 0.0;
    }

    final buckets = <BucketDiff>[
      BucketDiff(
        name: 'Cash',
        from: from.cashTotal,
        to: to.cashTotal,
        delta: to.cashTotal - from.cashTotal,
        deltaPct: calculateBucketPct(to.cashTotal - from.cashTotal),
      ),
      BucketDiff(
        name: 'Bonds',
        from: from.bondsTotal,
        to: to.bondsTotal,
        delta: to.bondsTotal - from.bondsTotal,
        deltaPct: calculateBucketPct(to.bondsTotal - from.bondsTotal),
      ),
      BucketDiff(
        name: 'US Equity',
        from: from.usEqTotal,
        to: to.usEqTotal,
        delta: to.usEqTotal - from.usEqTotal,
        deltaPct: calculateBucketPct(to.usEqTotal - from.usEqTotal),
      ),
      BucketDiff(
        name: 'Intl Equity',
        from: from.intlEqTotal,
        to: to.intlEqTotal,
        delta: to.intlEqTotal - from.intlEqTotal,
        deltaPct: calculateBucketPct(to.intlEqTotal - from.intlEqTotal),
      ),
      BucketDiff(
        name: 'Real Estate',
        from: from.reTotal,
        to: to.reTotal,
        delta: to.reTotal - from.reTotal,
        deltaPct: calculateBucketPct(to.reTotal - from.reTotal),
      ),
      BucketDiff(
        name: 'Alternatives',
        from: from.altTotal,
        to: to.altTotal,
        delta: to.altTotal - from.altTotal,
        deltaPct: calculateBucketPct(to.altTotal - from.altTotal),
      ),
    ];

    return SnapshotDiff(
      from: from.at,
      to: to.at,
      buckets: buckets,
      assetsFrom: from.assetsTotal,
      assetsTo: to.assetsTotal,
      liabilitiesFrom: from.liabilitiesTotal,
      liabilitiesTo: to.liabilitiesTotal,
      netFrom: from.netWorth,
      netTo: to.netWorth,
      netDelta: to.netWorth - from.netWorth,
    );
  }

  void _showCompareDialog(BuildContext context) {
    final snapshotsAsync = ref.read(snapshotsProvider);
    final snapshots = snapshotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Snapshot>[],
    );
    showDialog(
      context: context,
      builder: (context) => _CompareSnapshotsPickerDialog(
        snapshots: snapshots,
        onSaveComparison: _saveComparison,
      ),
    );
  }

  void _saveComparison(SnapshotDiff diff) async {
    if (!mounted) return;
    await _showSaveComparisonDialog(diff);
  }

  Future<void> _showSaveComparisonDialog(SnapshotDiff diff) async {
    if (!mounted) return;

    final TextEditingController nameController = TextEditingController();
    final fromDate = DateFormat('MMM d, yyyy').format(diff.from);
    final toDate = DateFormat('MMM d, yyyy').format(diff.to);

    // Suggest a default name
    nameController.text = '$fromDate to $toDate';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Comparison'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Save this comparison for quick access later.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Comparison Name',
                    hintText: 'Enter a descriptive name',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 50,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Comparison Details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: $fromDate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'To: $toDate',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Net Change: ${CurrencyFormatter.format(diff.netDelta, _currency)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a name for the comparison'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final savedComparison = SavedComparison(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  fromDate: diff.from,
                  toDate: diff.to,
                  createdAt: DateTime.now(),
                  netFrom: diff.netFrom,
                  netTo: diff.netTo,
                  netDelta: diff.netDelta,
                );

                await _storeSavedComparison(savedComparison);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Saved comparison "$name"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _storeSavedComparison(SavedComparison comparison) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing saved comparisons
      final savedComparisonsJson =
          prefs.getStringList('saved_comparisons') ?? [];

      // Add the new comparison
      savedComparisonsJson.add(jsonEncode(comparison.toMap()));

      // Save back to preferences
      await prefs.setStringList('saved_comparisons', savedComparisonsJson);
    } catch (e) {
      // Handle storage error
      debugPrint('Error saving comparison: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save comparison: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSavedComparisonsDialog(BuildContext context) async {
    final savedComparisons = await _loadSavedComparisons();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Saved Comparisons'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: savedComparisons.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No saved comparisons yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Save interesting comparisons for quick access',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: savedComparisons.length,
                    itemBuilder: (context, index) {
                      final comparison = savedComparisons[index];
                      final fromDate =
                          DateFormat('MMM d, yyyy').format(comparison.fromDate);
                      final toDate =
                          DateFormat('MMM d, yyyy').format(comparison.toDate);
                      final delta = comparison.netDelta;
                      final deltaColor = delta >= 0 ? Colors.green : Colors.red;
                      final deltaPrefix = delta >= 0 ? '+' : '';
                      final createdDate = DateFormat('MMM d, yyyy')
                          .format(comparison.createdAt);

                      return Card(
                        surfaceTintColor:
                            Theme.of(context).colorScheme.surfaceTint,
                        elevation: 1,
                        child: ListTile(
                          leading:
                              const Icon(Icons.bookmark, color: Colors.blue),
                          title: Text(
                            comparison.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$fromDate → $toDate'),
                              Text(
                                '$deltaPrefix${CurrencyFormatter.format(delta, _currency)}',
                                style: TextStyle(
                                  color: deltaColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Saved: $createdDate',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'load') {
                                if (context.mounted) {
                                  Navigator.of(context)
                                      .pop(); // Close saved comparisons dialog first
                                }
                                await _loadComparison(comparison);
                              } else if (value == 'delete') {
                                await _deleteSavedComparison(comparison.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  _showSavedComparisonsDialog(context);
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'load',
                                child: Row(
                                  children: [
                                    Icon(Icons.compare_arrows, size: 18),
                                    SizedBox(width: 8),
                                    Text('Load Comparison'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<List<SavedComparison>> _loadSavedComparisons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedComparisonsJson =
          prefs.getStringList('saved_comparisons') ?? [];

      return savedComparisonsJson
          .map((json) => SavedComparison.fromMap(jsonDecode(json)))
          .toList()
        ..sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        ); // Sort by creation date, newest first
    } catch (e) {
      debugPrint('Error loading saved comparisons: $e');
      return [];
    }
  }

  Future<void> _loadComparison(SavedComparison comparison) async {
    // Find snapshots that match the saved comparison dates
    final snapshotsAsync = ref.read(snapshotsProvider);
    final snapshots = snapshotsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Snapshot>[],
    );

    // Find the closest snapshots to the saved dates
    Snapshot? fromSnapshot;
    Snapshot? toSnapshot;

    for (final snapshot in snapshots) {
      if (fromSnapshot == null ||
          (snapshot.at.difference(comparison.fromDate).abs() <
              fromSnapshot.at.difference(comparison.fromDate).abs())) {
        if (snapshot.at.difference(comparison.fromDate).abs().inDays <= 1) {
          fromSnapshot = snapshot;
        }
      }

      if (toSnapshot == null ||
          (snapshot.at.difference(comparison.toDate).abs() <
              toSnapshot.at.difference(comparison.toDate).abs())) {
        if (snapshot.at.difference(comparison.toDate).abs().inDays <= 1) {
          toSnapshot = snapshot;
        }
      }
    }

    if (fromSnapshot != null && toSnapshot != null) {
      final diff = _calculateSnapshotDiff(fromSnapshot, toSnapshot);

      // Add a small delay to ensure the saved comparisons dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _CompareSnapshotsDialog(
            diff: diff,
            onSaveComparison: () => _saveComparison(diff),
            currency: _currency,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded comparison: ${comparison.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Could not find matching snapshots for this comparison'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteSavedComparison(String comparisonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedComparisonsJson =
          prefs.getStringList('saved_comparisons') ?? [];

      // Remove the comparison with the matching ID
      savedComparisonsJson.removeWhere((json) {
        final comparison = SavedComparison.fromMap(jsonDecode(json));
        return comparison.id == comparisonId;
      });

      // Save back to preferences
      await prefs.setStringList('saved_comparisons', savedComparisonsJson);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleted saved comparison'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting saved comparison: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete comparison: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Tiny sparkline painter for individual rows
class TinySparklinePainter extends CustomPainter {
  final List<Snapshot> snapshots;
  final Color color;

  TinySparklinePainter({required this.snapshots, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();

    // Find min/max for scaling
    final values = snapshots.map((s) => s.netWorth).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;

    if (range == 0) {
      // Draw flat line if all values are the same
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    // Draw the line
    for (int i = 0; i < snapshots.length; i++) {
      final x = (i / (snapshots.length - 1)) * size.width;
      final normalizedValue = (snapshots[i].netWorth - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Onboarding Steps Sheet Widget
class _CompareSnapshotsDialog extends StatelessWidget {
  final SnapshotDiff diff;
  final VoidCallback? onSaveComparison;
  final String currency;

  const _CompareSnapshotsDialog({
    required this.diff,
    this.onSaveComparison,
    this.currency = 'USD',
  });

  @override
  Widget build(BuildContext context) {
    final daysDiff = diff.to.difference(diff.from).inDays;
    final netDeltaPct =
        diff.netFrom.abs() > 0 ? diff.netDelta / diff.netFrom.abs() : 0.0;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            child: Text(
              'Compare Snapshots',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional header with time context
            Text(
              '${DateFormat('MMM d, yyyy').format(diff.from)} → ${DateFormat('MMM d, yyyy').format(diff.to)} • ${daysDiff == 0 ? '0 days' : daysDiff == 1 ? '1 day' : '$daysDiff days'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),

            // Net Worth summary box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Worth',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${CurrencyFormatter.format(diff.netFrom, currency)} → ${CurrencyFormatter.format(diff.netTo, currency)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    () {
                      // Apply rounding rules to net worth delta
                      final displayNetDelta =
                          diff.netDelta.abs() < 1.0 ? 0.0 : diff.netDelta;
                      final displayNetPct = (netDeltaPct * 100).abs() < 0.05
                          ? 0.0
                          : netDeltaPct * 100;
                      return 'Δ ${displayNetDelta >= 0 ? '+' : ''}${CurrencyFormatter.format(displayNetDelta.round().toDouble(), currency)} (${displayNetPct.toStringAsFixed(1)}%)';
                    }(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: daysDiff == 0
                          ? Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6)
                          : (diff.netDelta >= 0
                              ? Colors.green.shade600
                              : Colors.red.shade600),
                    ),
                  ),
                  if (daysDiff == 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Pick a different date to see changes.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Asset Changes section
            Text(
              'Asset Changes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (diff.buckets.every((b) => b.delta.abs() < 1.0))
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No change detected between these dates.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...diff.buckets
                          .where((bucket) => bucket.delta.abs() >= 1.0)
                          .map(
                            (bucket) =>
                                _buildComparisonRow(context, bucket, currency),
                          ),

                    const SizedBox(height: 16),
                    const Divider(),

                    // Assets Total
                    _buildComparisonRow(
                      context,
                      BucketDiff(
                        name: 'Assets Total',
                        from: diff.assetsFrom,
                        to: diff.assetsTo,
                        delta: diff.assetsTo - diff.assetsFrom,
                        deltaPct: diff.assetsFrom > 0
                            ? (diff.assetsTo - diff.assetsFrom) /
                                diff.assetsFrom
                            : 0.0,
                      ),
                      currency,
                      isBold: true,
                    ),

                    // Liabilities
                    _buildComparisonRow(
                      context,
                      BucketDiff(
                        name: 'Liabilities',
                        from: diff.liabilitiesFrom,
                        to: diff.liabilitiesTo,
                        delta: diff.liabilitiesTo - diff.liabilitiesFrom,
                        deltaPct: diff.liabilitiesFrom.abs() > 0
                            ? (diff.liabilitiesTo - diff.liabilitiesFrom) /
                                diff.liabilitiesFrom.abs()
                            : 0.0,
                      ),
                      currency,
                      isLiability: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Sticky footer with net summary and actions
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                () {
                  // Apply rounding rules to sticky footer
                  final displayNetDelta =
                      diff.netDelta.abs() < 1.0 ? 0.0 : diff.netDelta;
                  final displayNetPct = (netDeltaPct * 100).abs() < 0.05
                      ? 0.0
                      : netDeltaPct * 100;
                  return 'Net: ${CurrencyFormatter.format(diff.netFrom, currency)} → ${CurrencyFormatter.format(diff.netTo, currency)} | Δ ${displayNetDelta >= 0 ? '+' : ''}${CurrencyFormatter.format(displayNetDelta.round().toDouble(), currency)} (${displayNetPct.toStringAsFixed(1)}%)';
                }(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: diff.netDelta >= 0
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (onSaveComparison != null)
                            TextButton.icon(
                              onPressed: onSaveComparison,
                              icon: const Icon(Icons.bookmark_add, size: 16),
                              label: Text(AppLocalizations.of(context)!.save),
                            ),
                          if (onSaveComparison != null)
                            const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _exportComparisonCSV(context, diff),
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('CSV'),
                          ),
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, _) {
                              final settingsAsync = ref.watch(settingsProvider);
                              final isPro = settingsAsync.maybeWhen(
                                data: (s) => s.isPro,
                                orElse: () => false,
                              );

                              return IconButton(
                                onPressed: isPro
                                    ? () => _exportComparisonPDF(context, diff)
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                              AppLocalizations.of(context)!
                                                  .proFeature,
                                            ),
                                            content: Text(
                                              AppLocalizations.of(context)!
                                                  .pdfExportProMessage,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  AppLocalizations.of(
                                                    context,
                                                  )!
                                                      .maybeLater,
                                                ),
                                              ),
                                              FilledButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  context.push(AppRouter.pro);
                                                },
                                                child: Text(
                                                  AppLocalizations.of(context)!
                                                      .upgradeToProTitle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.picture_as_pdf),
                                tooltip:
                                    isPro ? 'Export PDF' : 'PDF Export (Pro)',
                                iconSize: 20,
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _exportComparisonCSV(BuildContext context, SnapshotDiff diff) async {
    try {
      final fromDate = DateFormat('yyyy-MM-dd').format(diff.from);
      final toDate = DateFormat('yyyy-MM-dd').format(diff.to);
      final fileBaseName = 'rebalance_compare_${fromDate}_to_$toDate';
      final now = DateTime.now();

      final csvData = StringBuffer();
      csvData.writeln('# Rebalance Compare Export');
      csvData.writeln(
        '# From: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(diff.from)}',
      );
      csvData.writeln(
        '# To: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(diff.to)}',
      );
      csvData.writeln('# Generated: ${now.toUtc().toIso8601String()}');
      csvData.writeln('');
      csvData.writeln(
        'asset_class,from_amount,to_amount,delta_amount,delta_percent',
      );
      for (final bucket in diff.buckets) {
        if (bucket.delta.abs() >= 1.0) {
          csvData.writeln(
            [
              bucket.name,
              bucket.from.toStringAsFixed(2),
              bucket.to.toStringAsFixed(2),
              bucket.delta.toStringAsFixed(2),
              (bucket.deltaPct * 100).toStringAsFixed(2),
            ].join(','),
          );
        }
      }

      csvData.writeln(
        [
          'Assets Total',
          diff.assetsFrom.toStringAsFixed(2),
          diff.assetsTo.toStringAsFixed(2),
          (diff.assetsTo - diff.assetsFrom).toStringAsFixed(2),
          diff.assetsFrom > 0
              ? ((diff.assetsTo - diff.assetsFrom) / diff.assetsFrom * 100)
                  .toStringAsFixed(2)
              : '0.00',
        ].join(','),
      );
      csvData.writeln(
        [
          'Net Worth',
          diff.netFrom.toStringAsFixed(2),
          diff.netTo.toStringAsFixed(2),
          diff.netDelta.toStringAsFixed(2),
          diff.netFrom.abs() > 0
              ? (diff.netDelta / diff.netFrom.abs() * 100).toStringAsFixed(2)
              : '0.00',
        ].join(','),
      );

      await CsvExporter.save(
        fileName: fileBaseName,
        csvContent: csvData.toString(),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to Downloads/$fileBaseName.csv'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[Dashboard] Comparison CSV export failed: $e');
      debugPrint('[Dashboard] Comparison CSV stack: $stackTrace');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _exportComparisonPDF(BuildContext context, SnapshotDiff diff) {
    // PDF export is a Pro feature that's not yet implemented
    // This function should only be called if user is Pro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export coming soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    BucketDiff bucket,
    String currency, {
    bool isBold = false,
    bool isLiability = false,
  }) {
    // Apply rounding rules: collapse jitter if |Δ| < $1 or < 0.05%
    final displayDelta = bucket.delta.abs() < 1.0 ? 0.0 : bucket.delta;
    final displayPct =
        (bucket.deltaPct * 100).abs() < 0.05 ? 0.0 : bucket.deltaPct * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              bucket.name,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: isLiability ? Colors.red.shade700 : null,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              '${CurrencyFormatter.format(bucket.from, currency)} → ${CurrencyFormatter.format(bucket.to, currency)}',
              style: TextStyle(
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '${displayDelta >= 0 ? '+' : ''}${CurrencyFormatter.format(displayDelta.round().toDouble(), currency)}\n(${displayPct.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: bucket.name == 'Net Worth'
                    ? (displayDelta >= 0
                        ? Colors.green.shade600
                        : Colors.red.shade600)
                    : Theme.of(context)
                        .colorScheme
                        .onSurface, // Neutral for asset buckets
                fontSize: 12,
                height: 1.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareSnapshotsPickerDialog extends StatefulWidget {
  final List<Snapshot> snapshots;
  final Function(SnapshotDiff)? onSaveComparison;

  const _CompareSnapshotsPickerDialog({
    required this.snapshots,
    this.onSaveComparison,
  });

  @override
  State<_CompareSnapshotsPickerDialog> createState() =>
      _CompareSnapshotsPickerDialogState();
}

class _CompareSnapshotsPickerDialogState
    extends State<_CompareSnapshotsPickerDialog> {
  Snapshot? fromSnapshot;
  Snapshot? toSnapshot;

  @override
  Widget build(BuildContext context) {
    final canCompare = fromSnapshot != null &&
        toSnapshot != null &&
        fromSnapshot != toSnapshot;
    final hasSufficientSnapshots = widget.snapshots.length >= 2;

    return AlertDialog(
      title: const Text('Compare Snapshots'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasSufficientSnapshots)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create another snapshot to compare.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Quick preset buttons
              Text(
                'Quick Comparisons:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildPresetButton('7d', 7),
                  _buildPresetButton('1m', 30),
                  _buildPresetButton('3m', 90),
                  _buildPresetButton('6m', 180),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Custom Selection:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              // From dropdown
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('From:')),
                  Expanded(
                    child: DropdownButton<Snapshot>(
                      isExpanded: true,
                      value: fromSnapshot,
                      hint: const Text('Select starting snapshot'),
                      items: widget.snapshots.asMap().entries.map((entry) {
                        final snapshot = entry.value;
                        return DropdownMenuItem(
                          value: snapshot,
                          child: Text(
                            '${DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at)} ${snapshot.source == 'manual' ? '(Manual)' : ''}',
                          ),
                        );
                      }).toList(),
                      onChanged: (snapshot) =>
                          setState(() => fromSnapshot = snapshot),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // To dropdown
              Row(
                children: [
                  const SizedBox(width: 60, child: Text('To:')),
                  Expanded(
                    child: DropdownButton<Snapshot>(
                      isExpanded: true,
                      value: toSnapshot,
                      hint: const Text('Select ending snapshot'),
                      items: widget.snapshots.asMap().entries.map((entry) {
                        final snapshot = entry.value;
                        return DropdownMenuItem(
                          value: snapshot,
                          child: Text(
                            '${DateFormat('MMM d, yyyy • h:mm a').format(snapshot.at)} ${snapshot.source == 'manual' ? '(Manual)' : ''}',
                          ),
                        );
                      }).toList(),
                      onChanged: (snapshot) =>
                          setState(() => toSnapshot = snapshot),
                    ),
                  ),
                ],
              ),
              // Same-snapshot warning
              if (fromSnapshot != null &&
                  toSnapshot != null &&
                  fromSnapshot == toSnapshot)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Same snapshot selected - no changes will be shown.',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: canCompare
              ? () {
                  Navigator.pop(context);
                  _showComparison(context, fromSnapshot!, toSnapshot!);
                }
              : null,
          child: Text(
            !hasSufficientSnapshots
                ? 'Need 2+ snapshots'
                : fromSnapshot != null &&
                        toSnapshot != null &&
                        fromSnapshot == toSnapshot
                    ? 'No Change'
                    : 'Compare',
          ),
        ),
      ],
    );
  }

  void _showComparison(BuildContext context, Snapshot from, Snapshot to) {
    final diff = _calculateSnapshotDiff(from, to);
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final currency = ref.read(settingsProvider).value?.currency ?? 'USD';
          return _CompareSnapshotsDialog(
            diff: diff,
            onSaveComparison: widget.onSaveComparison != null
                ? () => widget.onSaveComparison!(diff)
                : null,
            currency: currency,
          );
        },
      ),
    );
  }

  SnapshotDiff _calculateSnapshotDiff(Snapshot from, Snapshot to) {
    // Calculate total assets from 'from' snapshot for percentage calculations
    final assetsFrom = from.cashTotal +
        from.bondsTotal +
        from.usEqTotal +
        from.intlEqTotal +
        from.reTotal +
        from.altTotal;

    double calculateBucketPct(double delta) {
      return assetsFrom > 0 ? delta / assetsFrom : 0.0;
    }

    final buckets = <BucketDiff>[
      BucketDiff(
        name: 'Cash',
        from: from.cashTotal,
        to: to.cashTotal,
        delta: to.cashTotal - from.cashTotal,
        deltaPct: calculateBucketPct(to.cashTotal - from.cashTotal),
      ),
      BucketDiff(
        name: 'Bonds',
        from: from.bondsTotal,
        to: to.bondsTotal,
        delta: to.bondsTotal - from.bondsTotal,
        deltaPct: calculateBucketPct(to.bondsTotal - from.bondsTotal),
      ),
      BucketDiff(
        name: 'US Equity',
        from: from.usEqTotal,
        to: to.usEqTotal,
        delta: to.usEqTotal - from.usEqTotal,
        deltaPct: calculateBucketPct(to.usEqTotal - from.usEqTotal),
      ),
      BucketDiff(
        name: 'Intl Equity',
        from: from.intlEqTotal,
        to: to.intlEqTotal,
        delta: to.intlEqTotal - from.intlEqTotal,
        deltaPct: calculateBucketPct(to.intlEqTotal - from.intlEqTotal),
      ),
      BucketDiff(
        name: 'Real Estate',
        from: from.reTotal,
        to: to.reTotal,
        delta: to.reTotal - from.reTotal,
        deltaPct: calculateBucketPct(to.reTotal - from.reTotal),
      ),
      BucketDiff(
        name: 'Alternatives',
        from: from.altTotal,
        to: to.altTotal,
        delta: to.altTotal - from.altTotal,
        deltaPct: calculateBucketPct(to.altTotal - from.altTotal),
      ),
    ];

    return SnapshotDiff(
      from: from.at,
      to: to.at,
      buckets: buckets,
      assetsFrom: from.assetsTotal,
      assetsTo: to.assetsTotal,
      liabilitiesFrom: from.liabilitiesTotal,
      liabilitiesTo: to.liabilitiesTotal,
      netFrom: from.netWorth,
      netTo: to.netWorth,
      netDelta: to.netWorth - from.netWorth,
    );
  }

  Widget _buildPresetButton(String label, int days) {
    return FilledButton.tonal(
      onPressed: () => _applyPreset(days),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  void _applyPreset(int days) {
    final label = days == 7
        ? '7 days'
        : days == 30
            ? '1 month'
            : days == 90
                ? '3 months'
                : '6 months';
    final now = DateTime.now();
    final targetDate = now.subtract(Duration(days: days));

    // Find the closest snapshots to the target dates
    Snapshot? closestFrom;
    Snapshot? closestTo;

    // Find closest snapshot to the target date (from)
    double minFromDiff = double.infinity;
    for (final snapshot in widget.snapshots) {
      final diff = (snapshot.at.difference(targetDate)).abs().inDays.toDouble();
      if (diff < minFromDiff) {
        minFromDiff = diff;
        closestFrom = snapshot;
      }
    }

    // Find the most recent snapshot (to)
    DateTime mostRecentDate = DateTime(1900);
    for (final snapshot in widget.snapshots) {
      if (snapshot.at.isAfter(mostRecentDate)) {
        mostRecentDate = snapshot.at;
        closestTo = snapshot;
      }
    }

    // Only apply if we found valid snapshots and they're different
    if (closestFrom != null && closestTo != null && closestFrom != closestTo) {
      setState(() {
        fromSnapshot = closestFrom;
        toSnapshot = closestTo;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected comparison: $label'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Progress Ring Painter for the financial health score
