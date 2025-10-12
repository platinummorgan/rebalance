import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models.dart';
import '../../app.dart';
import '../../data/repositories.dart';

/// Represents a live computed custom alert breach prior to persistence.
class ActiveAlertBreach {
  final String kind; // drift | concentration | employerStock
  final String title;
  final String message;
  final NotificationSeverity severity;
  final double magnitude; // % or absolute delta for ranking
  final Map<String, dynamic> data;
  ActiveAlertBreach({
    required this.kind,
    required this.title,
    required this.message,
    required this.severity,
    required this.magnitude,
    required this.data,
  });
}

/// Provider that evaluates current accounts + settings and produces breaches (not yet saved)
final alertBreachesProvider = Provider<List<ActiveAlertBreach>>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final settingsAsync = ref.watch(settingsProvider);
  final breaches = <ActiveAlertBreach>[];
  if (!accountsAsync.hasValue || !settingsAsync.hasValue) return breaches;
  final accounts = accountsAsync.value!;
  final settings = settingsAsync.value!;
  if (accounts.isEmpty) return breaches;

  // Aggregate allocation
  double total = accounts.fold(0, (s, a) => s + a.balance);
  if (total <= 0) return breaches;

  double cash = 0,
      bonds = 0,
      us = 0,
      intl = 0,
      re = 0,
      alt = 0,
      employerStockTotal = 0;
  for (final a in accounts) {
    cash += a.balance * a.pctCash;
    bonds += a.balance * a.pctBonds;
    us += a.balance * a.pctUsEq;
    intl += a.balance * a.pctIntlEq;
    re += a.balance * a.pctRealEstate;
    alt += a.balance * a.pctAlt;
    employerStockTotal += a.balance * a.employerStockPct;
  }
  final alloc = {
    'cash': cash / total,
    'bonds': bonds / total,
    'usEq': us / total,
    'intlEq': intl / total,
    'realEstate': re / total,
    'alt': alt / total,
  };

  // Drift: compare US equity weight vs settings.usEquityTargetPct
  final drift = (alloc['usEq'] ?? 0) - settings.usEquityTargetPct;
  if (drift.abs() >= settings.driftThresholdPct) {
    final over = drift > 0;
    breaches.add(ActiveAlertBreach(
      kind: 'drift',
      title: over ? 'US Equity Overweight' : 'US Equity Underweight',
      message:
          'US equity is ${(drift * 100).abs().toStringAsFixed(1)}% ${over ? 'above' : 'below'} target.',
      severity: drift.abs() > settings.driftThresholdPct * 1.5
          ? NotificationSeverity.high
          : NotificationSeverity.medium,
      magnitude: drift.abs(),
      data: {
        'driftPct': drift,
        'target': settings.usEquityTargetPct,
      },
    ),);
  }

  // Concentration: any single bucket above bucketCap
  final cap = settings.bucketCap;
  for (final entry in alloc.entries) {
    if (entry.value > cap) {
      breaches.add(ActiveAlertBreach(
        kind: 'concentration',
        title: 'High ${_label(entry.key)} Concentration',
        message:
            '${_label(entry.key)} at ${(entry.value * 100).toStringAsFixed(1)}% exceeds ${(cap * 100).toStringAsFixed(0)}% cap.',
        severity: entry.value > cap * 1.25
            ? NotificationSeverity.high
            : NotificationSeverity.medium,
        magnitude: entry.value - cap,
        data: {'bucket': entry.key, 'weight': entry.value},
      ),);
    }
  }

  // Employer stock concentration
  final employerPct = employerStockTotal / total;
  if (employerPct > settings.employerStockThreshold) {
    breaches.add(ActiveAlertBreach(
      kind: 'employerStock',
      title: 'Employer Stock Concentration',
      message:
          'Employer stock at ${(employerPct * 100).toStringAsFixed(1)}% exceeds ${(settings.employerStockThreshold * 100).toStringAsFixed(0)}% threshold.',
      severity: employerPct > settings.employerStockThreshold * 1.5
          ? NotificationSeverity.high
          : NotificationSeverity.medium,
      magnitude: employerPct - settings.employerStockThreshold,
      data: {'employerPct': employerPct},
    ),);
  }

  // Sort by severity then magnitude desc
  breaches.sort((a, b) {
    int sev(NotificationSeverity s) {
      switch (s) {
        case NotificationSeverity.critical:
          return 4;
        case NotificationSeverity.high:
          return 3;
        case NotificationSeverity.medium:
          return 2;
        case NotificationSeverity.low:
          return 1;
        case NotificationSeverity.info:
          return 0;
      }
    }

    final c = sev(b.severity) - sev(a.severity);
    if (c != 0) return c;
    return b.magnitude.compareTo(a.magnitude);
  });

  return breaches;
});

String _label(String k) {
  switch (k) {
    case 'usEq':
      return 'US Equity';
    case 'intlEq':
      return 'International Equity';
    case 'realEstate':
      return 'Real Estate';
    case 'alt':
      return 'Alternatives';
    default:
      return k[0].toUpperCase() + k.substring(1);
  }
}

/// Persist breaches as notifications (dedupe by kind+bucket)
final alertSyncProvider = FutureProvider<void>((ref) async {
  final breaches = ref.watch(alertBreachesProvider);
  final existingAsync = ref.watch(notificationsProvider);
  if (!existingAsync.hasValue) return;
  final existing = existingAsync.value!;
  final existingKeys = existing
      .where((n) => !n.dismissed)
      .map((n) => n.data['kindKey'] as String? ?? '')
      .toSet();
  for (final b in breaches) {
    final key = _breachKey(b);
    if (existingKeys.contains(key)) {
      continue; // Already have active notification
    }
    final n = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString() + key,
      title: b.title,
      message: b.message,
      type: NotificationType.risk,
      severity: b.severity,
      createdAt: DateTime.now(),
      route: '/accounts',
      data: {
        ...b.data,
        'kind': b.kind,
        'kindKey': key,
      },
    );
    await RepositoryService.saveNotification(n);
  }
  // Reload notifications provider after persistence
  await ref.read(notificationsProvider.notifier).reload();
});

String _breachKey(ActiveAlertBreach b) {
  if (b.kind == 'concentration') {
    return 'concentration-${b.data['bucket']}';
  }
  return b.kind;
}
