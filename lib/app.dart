import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme.dart';
import 'routes.dart' show AppRouter;
import 'services/purchase_service.dart';
import 'data/repositories.dart';
import 'data/models.dart';
import 'utils/diagnostics.dart';

class RebalanceApp extends ConsumerWidget {
  const RebalanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Material(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error loading settings: $error'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Collect diagnostics and share
                      final file = await Diagnostics.collectAndWrite();
                      await Diagnostics.shareDiagnosticsFile(file);
                    } catch (e) {
                      debugPrint('Failed to export diagnostics: $e');
                    }
                  },
                  child: const Text('Export diagnostics'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (settings) => MaterialApp.router(
        title: 'Rebalance',
        debugShowCheckedModeBanner: false,

        // Dynamic theme configuration based on user preference
        theme: AppTheme.getLightTheme(settings.colorTheme),
        darkTheme: AppTheme.getDarkTheme(settings.colorTheme),
        themeMode: settings.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,

        // Routing
        routerConfig: AppRouter.router,

        // Localization (US English only for MVP)
        locale: const Locale('en', 'US'),

        // Accessibility
        builder: (context, child) {
          return MediaQuery(
            // Ensure text scaling doesn't break the UI
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

// Provider for theme mode (to be implemented later for Pro feature)
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

// Provider for app initialization
final appInitProvider = FutureProvider<bool>((ref) async {
  try {
    // Initialize Hive and repositories
    await RepositoryService.initialize();

    // Initialize purchase service so in-app purchases are ready
    final purchaseService = ref.read(purchaseServiceProvider);
    await purchaseService.initialize(ref);

    // Attempt to restore purchases on startup to rehydrate any Pro entitlement
    // (important after reinstalls/updates where local settings may have been
    // reset). If restore fails we log the error but do not clear user data.
    try {
      await purchaseService.restorePurchases(ref);
    } catch (restoreError) {
      debugPrint('Restore purchases during init failed: $restoreError');
    }

    return true;
  } catch (e) {
    // Handle initialization errors. IMPORTANT: Do NOT automatically clear
    // user data here. Automatic deletion previously caused legitimate user
    // data to be wiped during startup errors. Instead surface the error so
    // it can be recovered manually or handled with an explicit user action.
    debugPrint('App initialization error: $e');
    rethrow;
  }
});

// Provider to check if onboarding is complete
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  try {
    final settings = await RepositoryService.getSettings();

    // Onboarding is complete if we have essential settings
    return settings.monthlyEssentials > 0;
  } catch (e) {
    return false;
  }
});

// Provider for accounts
final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AsyncValue<List<Account>>>((ref) {
  return AccountsNotifier();
});

class AccountsNotifier extends StateNotifier<AsyncValue<List<Account>>> {
  AccountsNotifier() : super(const AsyncValue.loading()) {
    _loadAccounts();
    // Listen to Hive box changes so any external RepositoryService.saveAccount
    // calls (bypassing addAccount) still trigger UI refresh.
    // Safe because RepositoryService.initialize() is invoked inside getAccounts.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await RepositoryService.initialize();
        final box = Hive.box<Account>('accounts');
        _accountsListenable = box.listenable();
        _accountsListenable!.addListener(_loadAccounts);
      } catch (e) {
        // If initialization fails we silently ignore; manual reloads still work.
        debugPrint('AccountsNotifier listen setup failed: $e');
      }
    });
  }

  ValueListenable<Object?>? _accountsListenable;

  Future<void> _loadAccounts() async {
    try {
      final accounts = await RepositoryService.getAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addAccount(Account account) async {
    try {
      await RepositoryService.saveAccount(account);
      await _loadAccounts(); // Reload the list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reload() async {
    await _loadAccounts();
  }

  @override
  void dispose() {
    _accountsListenable?.removeListener(_loadAccounts);
    super.dispose();
  }
}

// Provider for liabilities
final liabilitiesProvider =
    StateNotifierProvider<LiabilitiesNotifier, AsyncValue<List<Liability>>>(
        (ref) {
  return LiabilitiesNotifier();
});

class LiabilitiesNotifier extends StateNotifier<AsyncValue<List<Liability>>> {
  LiabilitiesNotifier() : super(const AsyncValue.loading()) {
    _loadLiabilities();
  }

  Future<void> _loadLiabilities() async {
    try {
      final liabilities = await RepositoryService.getLiabilities();
      state = AsyncValue.data(liabilities);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addLiability(Liability liability) async {
    try {
      await RepositoryService.saveLiability(liability);
      await _loadLiabilities(); // Reload the list
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reload() async {
    await _loadLiabilities();
  }
}

// Provider for current settings
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<Settings>>((ref) {
  return SettingsNotifier();
});

// Provider for snapshots
final snapshotsProvider =
    StateNotifierProvider<SnapshotsNotifier, AsyncValue<List<Snapshot>>>((ref) {
  return SnapshotsNotifier();
});

class SettingsNotifier extends StateNotifier<AsyncValue<Settings>> {
  SettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await RepositoryService.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSettings(Settings settings) async {
    state = const AsyncValue.loading();
    try {
      await RepositoryService.saveSettings(settings);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reload() async {
    await _loadSettings();
  }
}

class SnapshotsNotifier extends StateNotifier<AsyncValue<List<Snapshot>>> {
  SnapshotsNotifier() : super(const AsyncValue.loading()) {
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    try {
      final snapshots = await RepositoryService.getSnapshots();
      state = AsyncValue.data(snapshots);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addSnapshot(Snapshot snapshot) async {
    try {
      await RepositoryService.saveSnapshot(snapshot);
      final snapshots = await RepositoryService.getSnapshots();
      state = AsyncValue.data(snapshots);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeSnapshot(Snapshot snapshot) async {
    try {
      await RepositoryService.deleteSnapshot(snapshot.at);
      final snapshots = await RepositoryService.getSnapshots();
      state = AsyncValue.data(snapshots);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reload() async {
    await _loadSnapshots();
  }
}

// Notifications Provider (MVP)
final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<AppNotification>>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await RepositoryService.getNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> seedIfEmpty() async {
    final current = state.valueOrNull;
    if (current != null && current.isNotEmpty) return;
    final sample = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'High Concentration Risk',
      message: 'US Equity exposure exceeds target. Consider reallocating.',
      type: NotificationType.risk,
      severity: NotificationSeverity.high,
      createdAt: DateTime.now(),
      route: '/accounts',
      data: {'kind': 'concentration'},
    );
    await RepositoryService.saveNotification(sample);
    await _load();
  }

  int get unreadCount =>
      (state.valueOrNull ?? []).where((n) => !n.read && !n.dismissed).length;

  Future<void> markRead(String id) async {
    await RepositoryService.markNotificationRead(id);
    await _load();
  }

  Future<void> dismiss(String id) async {
    await RepositoryService.dismissNotification(id);
    await _load();
  }

  Future<void> markAllRead() async {
    await RepositoryService.markAllRead();
    await _load();
  }

  // Public refresh so external evaluators can trigger reload without exposing _load
  Future<void> reload() async => _load();
}
