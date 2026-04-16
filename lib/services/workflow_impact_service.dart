import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models.dart';
import '../data/repositories.dart';

class WorkflowImpactLogEntry {
  final String id;
  final String workflowId;
  final String workflowTitle;
  final String source;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, double> baselineMetrics;
  final Map<String, double>? outcomeMetrics;
  final Map<String, double>? expectedMetrics;
  final String? note;

  const WorkflowImpactLogEntry({
    required this.id,
    required this.workflowId,
    required this.workflowTitle,
    required this.source,
    required this.startedAt,
    required this.completedAt,
    required this.baselineMetrics,
    required this.outcomeMetrics,
    required this.expectedMetrics,
    required this.note,
  });

  bool get isCompleted => completedAt != null;

  double? delta(String metricKey) {
    final before = baselineMetrics[metricKey];
    final after = outcomeMetrics?[metricKey];
    if (before == null || after == null) return null;
    return after - before;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workflowId': workflowId,
      'workflowTitle': workflowTitle,
      'source': source,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'baselineMetrics': baselineMetrics,
      'outcomeMetrics': outcomeMetrics,
      'expectedMetrics': expectedMetrics,
      'note': note,
    };
  }

  factory WorkflowImpactLogEntry.fromMap(Map<String, dynamic> map) {
    final startedAtRaw = map['startedAt']?.toString();
    final completedAtRaw = map['completedAt']?.toString();
    return WorkflowImpactLogEntry(
      id: map['id']?.toString() ?? '',
      workflowId: map['workflowId']?.toString() ?? '',
      workflowTitle: map['workflowTitle']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      startedAt: DateTime.tryParse(startedAtRaw ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(completedAtRaw ?? ''),
      baselineMetrics: _toStringDoubleMap(map['baselineMetrics']),
      outcomeMetrics: _toNullableStringDoubleMap(map['outcomeMetrics']),
      expectedMetrics: _toNullableStringDoubleMap(map['expectedMetrics']),
      note: map['note']?.toString(),
    );
  }

  static Map<String, double> _toStringDoubleMap(dynamic value) {
    if (value is! Map) return <String, double>{};
    final output = <String, double>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final parsed = _toDouble(entry.value);
      if (key.isEmpty || parsed == null) continue;
      output[key] = parsed;
    }
    return output;
  }

  static Map<String, double>? _toNullableStringDoubleMap(dynamic value) {
    if (value == null) return null;
    final map = _toStringDoubleMap(value);
    return map.isEmpty ? null : map;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class WorkflowImpactService {
  static const _boxName = 'workflowImpactLogs';

  static const String sourceCommandCenter = 'command_center';

  static const String workflowShockTest = 'shock_test';
  static const String workflowDebtBlitz = 'debt_blitz';
  static const String workflowRebalanceLift = 'rebalance_lift';
  static const String workflowTaxLens = 'tax_lens';

  static const String metricTotalAssets = 'totalAssets';
  static const String metricTotalLiabilities = 'totalLiabilities';
  static const String metricNetWorth = 'netWorth';
  static const String metricMonthlyIncome = 'monthlyIncome';
  static const String metricMonthlyBurn = 'monthlyBurn';
  static const String metricMonthlySurplus = 'monthlySurplus';
  static const String metricCashBuffer = 'cashBuffer';
  static const String metricCashRunwayMonths = 'cashRunwayMonths';

  static Future<List<WorkflowImpactLogEntry>> getLogs({
    int limit = 8,
    bool completedOnly = false,
  }) async {
    final raw = await _readRawLogs();
    final parsed = raw.map(WorkflowImpactLogEntry.fromMap).where((entry) {
      if (entry.id.isEmpty || entry.workflowId.isEmpty) return false;
      if (completedOnly) return entry.isCompleted;
      return true;
    }).toList()
      ..sort((a, b) {
        final left = a.completedAt ?? a.startedAt;
        final right = b.completedAt ?? b.startedAt;
        return right.compareTo(left);
      });

    if (limit <= 0 || parsed.length <= limit) return parsed;
    return parsed.take(limit).toList();
  }

  static Future<void> startWorkflow({
    required String workflowId,
    required String workflowTitle,
    required String source,
    required Map<String, double> baselineMetrics,
    Map<String, double>? expectedMetrics,
    String? note,
  }) async {
    final now = DateTime.now();
    final entry = WorkflowImpactLogEntry(
      id: '${now.microsecondsSinceEpoch}_$workflowId',
      workflowId: workflowId,
      workflowTitle: workflowTitle,
      source: source,
      startedAt: now,
      completedAt: null,
      baselineMetrics: _normalizedMetrics(baselineMetrics),
      outcomeMetrics: null,
      expectedMetrics: _nullableNormalizedMetrics(expectedMetrics),
      note: note,
    );
    await _saveRawLog(entry.toMap());
  }

  static Future<bool> completeLatestPendingWorkflow({
    required String workflowId,
    required Map<String, double> outcomeMetrics,
    Map<String, double>? expectedMetrics,
    String? note,
  }) async {
    final allLogs = await getLogs(limit: 200, completedOnly: false);
    WorkflowImpactLogEntry? pending;
    for (final log in allLogs) {
      if (log.workflowId == workflowId && !log.isCompleted) {
        pending = log;
        break;
      }
    }
    if (pending == null) return false;

    final updated = WorkflowImpactLogEntry(
      id: pending.id,
      workflowId: pending.workflowId,
      workflowTitle: pending.workflowTitle,
      source: pending.source,
      startedAt: pending.startedAt,
      completedAt: DateTime.now(),
      baselineMetrics: pending.baselineMetrics,
      outcomeMetrics: _normalizedMetrics(outcomeMetrics),
      expectedMetrics: _nullableNormalizedMetrics(
        expectedMetrics ?? pending.expectedMetrics,
      ),
      note: note?.trim().isNotEmpty == true ? note!.trim() : pending.note,
    );

    await _saveRawLog(updated.toMap());
    return true;
  }

  static Future<Map<String, double>> captureCurrentMetrics() async {
    final accounts = await RepositoryService.getAccounts();
    final liabilities = await RepositoryService.getLiabilities();
    final incomes = await RepositoryService.getIncomes();
    final expenses = await RepositoryService.getExpenses();
    final settings = await RepositoryService.getSettings();

    return buildMetricsSnapshot(
      accounts: accounts,
      liabilities: liabilities,
      incomes: incomes,
      expenses: expenses,
      settings: settings,
    );
  }

  static Map<String, double> buildMetricsSnapshot({
    required List<Account> accounts,
    required List<Liability> liabilities,
    required List<Income> incomes,
    required List<MonthlyExpense> expenses,
    required Settings? settings,
  }) {
    final totalAssets = accounts.fold<double>(0, (sum, a) => sum + a.balance);
    final totalLiabilities =
        liabilities.fold<double>(0, (sum, l) => sum + l.balance);
    final monthlyIncome =
        incomes.fold<double>(0, (sum, i) => sum + i.monthlyNet);
    final monthlyTrackedExpenses =
        expenses.fold<double>(0, (sum, e) => sum + e.amount);
    final monthlyEssentials = settings?.monthlyEssentials ?? 0.0;
    final monthlyBurn = max(monthlyTrackedExpenses, monthlyEssentials);
    final monthlySurplus = monthlyIncome - monthlyBurn;

    final cashBuffer = accounts
        .where((a) => a.kind == 'cash' || a.kind == 'savings')
        .fold<double>(0, (sum, a) => sum + a.balance);

    final cashRunwayMonths = monthlyBurn > 0 ? cashBuffer / monthlyBurn : 0.0;

    return {
      metricTotalAssets: totalAssets,
      metricTotalLiabilities: totalLiabilities,
      metricNetWorth: totalAssets - totalLiabilities,
      metricMonthlyIncome: monthlyIncome,
      metricMonthlyBurn: monthlyBurn,
      metricMonthlySurplus: monthlySurplus,
      metricCashBuffer: cashBuffer,
      metricCashRunwayMonths: cashRunwayMonths,
    };
  }

  static Map<String, double> _normalizedMetrics(Map<String, double> metrics) {
    final normalized = <String, double>{};
    for (final entry in metrics.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) continue;
      final value = entry.value;
      if (!value.isFinite) continue;
      normalized[key] = value;
    }
    return normalized;
  }

  static Map<String, double>? _nullableNormalizedMetrics(
    Map<String, double>? metrics,
  ) {
    if (metrics == null) return null;
    final normalized = _normalizedMetrics(metrics);
    return normalized.isEmpty ? null : normalized;
  }

  static Future<List<Map<String, dynamic>>> _readRawLogs() async {
    final box = await _openBox();
    final logs = box.values
        .whereType<Map>()
        .map(_toStringDynamicMap)
        .toList(growable: false);
    logs.sort((a, b) {
      final left = DateTime.tryParse(a['startedAt']?.toString() ?? '');
      final right = DateTime.tryParse(b['startedAt']?.toString() ?? '');
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    return logs;
  }

  static Future<void> _saveRawLog(Map<String, dynamic> rawLog) async {
    final id = rawLog['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw Exception('Workflow impact log id is required');
    }
    final box = await _openBox();
    final normalized = _toStringDynamicMap(rawLog);
    normalized['id'] = id;
    await box.put(id, normalized);
  }

  static Future<Box<Map>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<Map>(_boxName);
    }
    return Hive.openBox<Map>(_boxName);
  }

  static Map<String, dynamic> _toStringDynamicMap(dynamic value) {
    if (value is! Map) return <String, dynamic>{};
    return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
  }
}

final workflowImpactLogsProvider =
    FutureProvider<List<WorkflowImpactLogEntry>>((ref) async {
  return WorkflowImpactService.getLogs(limit: 8, completedOnly: false);
});
