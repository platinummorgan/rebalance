import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class HouseholdDataMoveResult {
  final int accountsMoved;
  final int liabilitiesMoved;
  final int incomesMoved;
  final int expensesMoved;
  final int goalsMoved;

  const HouseholdDataMoveResult({
    required this.accountsMoved,
    required this.liabilitiesMoved,
    required this.incomesMoved,
    required this.expensesMoved,
    this.goalsMoved = 0,
  });

  int get totalMoved =>
      accountsMoved +
      liabilitiesMoved +
      incomesMoved +
      expensesMoved +
      goalsMoved;
}

class HouseholdProfileFinancialCounts {
  final int accounts;
  final int liabilities;
  final int incomes;
  final int expenses;
  final int goals;

  const HouseholdProfileFinancialCounts({
    required this.accounts,
    required this.liabilities,
    required this.incomes,
    required this.expenses,
    this.goals = 0,
  });

  int get total => accounts + liabilities + incomes + expenses + goals;

  bool get hasFinancialData => total > 0;
}

class HouseholdProfileFinancialSummary {
  final HouseholdProfileFinancialCounts counts;
  final double totalAssets;
  final double totalLiabilities;
  final double monthlyIncome;
  final double monthlyExpenses;

  const HouseholdProfileFinancialSummary({
    required this.counts,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.monthlyIncome,
    required this.monthlyExpenses,
  });

  double get netWorth => totalAssets - totalLiabilities;
  double get monthlyCashFlow => monthlyIncome - monthlyExpenses;
}

class RepositoryService {
  static const _encryptionKeyKey = 'wealth_dial_encryption_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static late Box<Account> _accountsBox;
  static late Box<Liability> _liabilitiesBox;
  static late Box<Income> _incomesBox;
  static late Box<MonthlyExpense> _expensesBox;
  static late Box<String> _accountOwnersBox;
  static late Box<String> _liabilityOwnersBox;
  static late Box<String> _incomeOwnersBox;
  static late Box<String> _expenseOwnersBox;
  static late Box<Settings> _settingsBox;
  static late Box<Snapshot> _snapshotsBox;
  static late Box<ActionCard> _actionCardsBox;
  static late Box<Payment> _paymentsBox;
  static late Box<AppNotification> _notificationsBox;
  static late Box<Map> _workflowImpactLogsBox;
  static late Box<HouseholdProfile> _householdProfilesBox;
  static late Box<String> _householdMetaBox;
  static late Box<HouseholdGoal> _householdGoalsBox;

  static const _activeHouseholdProfileKey = 'active_profile_id';
  static const _defaultHouseholdProfileId = 'primary';
  static const _defaultHouseholdProfileName = 'Primary';

  static bool _initialized = false;
  static const int _currentSchemaVersion =
      2; // Increment when adding new fields - v2: Added currency field

  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RiskBandAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AccountAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LiabilityAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SnapshotAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(ActionCardAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(PaymentAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(ColorThemeAdapter());
    }
    // Register notification-related adapters
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(NotificationSeverityAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(NotificationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(IncomeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(MonthlyExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(HouseholdProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(HouseholdGoalAdapter());
    }

    // Get or generate encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // Open encrypted boxes with error recovery
    // If we encounter BadPaddingException (decryption failure), it means the
    // encryption key doesn't match the stored data. This can happen after
    // app reinstalls or OS updates. We need to recover by clearing corrupted data.
    bool encryptionError = false;

    try {
      _accountsBox = await Hive.openBox<Account>(
        'accounts',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "accounts" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in accounts box');
      } else {
        rethrow;
      }
    }

    try {
      _liabilitiesBox = await Hive.openBox<Liability>(
        'liabilities',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "liabilities" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in liabilities box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _incomesBox = await Hive.openBox<Income>(
        'incomes',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "incomes" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in incomes box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _expensesBox = await Hive.openBox<MonthlyExpense>(
        'expenses',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "expenses" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in expenses box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _settingsBox = await Hive.openBox<Settings>(
        'settings',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "settings" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in settings box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _snapshotsBox = await Hive.openBox<Snapshot>(
        'snapshots',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "snapshots" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in snapshots box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _actionCardsBox = await Hive.openBox<ActionCard>(
        'actionCards',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "actionCards" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in actionCards box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _paymentsBox = await Hive.openBox<Payment>(
        'payments',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "payments" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint('[Repository] Detected encryption error in payments box');
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _notificationsBox = await Hive.openBox<AppNotification>(
        'notifications',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "notifications" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in notifications box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _workflowImpactLogsBox = await Hive.openBox<Map>(
        'workflowImpactLogs',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "workflowImpactLogs" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in workflowImpactLogs box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _accountOwnersBox = await Hive.openBox<String>(
        'accountOwners',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "accountOwners" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in accountOwners box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _liabilityOwnersBox = await Hive.openBox<String>(
        'liabilityOwners',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "liabilityOwners" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in liabilityOwners box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _incomeOwnersBox = await Hive.openBox<String>(
        'incomeOwners',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "incomeOwners" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in incomeOwners box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _expenseOwnersBox = await Hive.openBox<String>(
        'expenseOwners',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "expenseOwners" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in expenseOwners box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _householdProfilesBox = await Hive.openBox<HouseholdProfile>(
        'householdProfiles',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "householdProfiles" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in householdProfiles box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _householdMetaBox = await Hive.openBox<String>(
        'householdMeta',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "householdMeta" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in householdMeta box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    try {
      _householdGoalsBox = await Hive.openBox<HouseholdGoal>(
        'householdGoals',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "householdGoals" box: $e');
      if (e.toString().contains('BadPaddingException') ||
          e.toString().contains('BAD_DECRYPT')) {
        encryptionError = true;
        debugPrint(
          '[Repository] Detected encryption error in householdGoals box',
        );
      } else if (!encryptionError) {
        rethrow;
      }
    }

    // If we detected encryption errors, DO NOT automatically delete user data.
    // This can happen after app updates when the encryption key changes.
    // Surface the error to the user with recovery instructions.
    if (encryptionError) {
      debugPrint('[Repository] CRITICAL: Encryption key mismatch detected');
      debugPrint(
        '[Repository] This usually happens after OS updates or app reinstalls',
      );
      debugPrint(
        '[Repository] User data exists but cannot be decrypted with current key',
      );

      // Throw error with user-friendly message instead of auto-deleting data
      throw Exception(
          'Unable to access your financial data due to encryption key changes. '
          'This can happen after system updates. Your data is still stored safely. '
          'Please try restarting the app. If the problem persists, contact support for data recovery. '
          'DO NOT uninstall the app as this will permanently delete your data.');
    }

    _initialized = true;

    // Run any necessary data migrations
    await _runMigrations();
    await _ensureHouseholdDefaults();
    await _ensureEntityOwnershipDefaults();
    await _ensureHouseholdGoalDefaults();
  }

  /// Read the stored encryption key value if it exists (base64 encoded).
  /// Returns null if no key is stored. This does NOT create a new key.
  static Future<String?> _readEncryptionKeyBase64() async {
    try {
      return await _secureStorage.read(key: _encryptionKeyKey);
    } catch (e) {
      debugPrint(
        '[Repository] Error reading encryption key from secure storage: $e',
      );
      return null;
    }
  }

  /// Collect diagnostic information about local storage and settings.
  /// This attempts to open boxes read-only where possible and captures
  /// errors instead of performing destructive recovery.
  static Future<Map<String, dynamic>> collectDiagnostics() async {
    final Map<String, dynamic> result = {};
    result['collectedAt'] = DateTime.now().toIso8601String();

    // Encryption key presence and safe hash
    final keyBase64 = await _readEncryptionKeyBase64();
    result['encryptionKeyPresent'] = keyBase64 != null;
    if (keyBase64 != null) {
      // Only hash the stored base64 string so we don't leak the key
      try {
        final bytes = utf8.encode(keyBase64);
        final digest = sha256.convert(bytes).toString();
        result['encryptionKeyHash'] = digest;
      } catch (e) {
        result['encryptionKeyHashError'] = e.toString();
      }
    }

    // Helper to probe a box non-destructively
    Future<void> probeBox(String name) async {
      try {
        final Uint8List? encryptionKeyBytes =
            keyBase64 != null ? base64Decode(keyBase64) : null;
        Box? b;
        if (encryptionKeyBytes != null) {
          b = await Hive.openBox(
            name,
            encryptionCipher: HiveAesCipher(encryptionKeyBytes),
          );
        } else {
          b = await Hive.openBox(name);
        }
        result['boxes'] ??= {};
        result['boxes'][name] = {
          'status': 'open',
          'length': b.length,
        };
        await b.close();
      } catch (e) {
        result['boxes'] ??= {};
        result['boxes'][name] = {
          'status': 'error',
          'error': e.toString(),
        };
      }
    }

    final boxNames = [
      'accounts',
      'liabilities',
      'incomes',
      'expenses',
      'accountOwners',
      'liabilityOwners',
      'incomeOwners',
      'expenseOwners',
      'settings',
      'snapshots',
      'actionCards',
      'payments',
      'notifications',
      'householdProfiles',
      'householdMeta',
      'householdGoals',
    ];

    for (final name in boxNames) {
      await probeBox(name);
    }

    // Try to grab the stored settings (if possible)
    try {
      final settings = await getSettings();
      result['settings'] = _settingsToJson(settings);
    } catch (e) {
      result['settingsError'] = e.toString();
    }

    return result;
  }

  /// Runs data migrations for schema updates
  /// This ensures existing data is updated when new fields are added
  static Future<void> _runMigrations() async {
    final settings = await getSettings();
    final schemaVersion = settings.schemaVersion ?? 0;

    if (schemaVersion < _currentSchemaVersion) {
      debugPrint(
        '[Migration] Running migrations from v$schemaVersion to v$_currentSchemaVersion',
      );

      // Migration v0 → v1: Added isLocked field to Account
      if (schemaVersion < 1) {
        debugPrint('[Migration] v1: Migrating accounts for isLocked field');
        final accounts = _accountsBox.values.toList();
        for (final account in accounts) {
          // The isLocked field will auto-default to false for existing records
          // but we want to set correct defaults based on account type
          if (account.isLocked == false &&
              Account.isLockedByDefault(account.kind)) {
            // Update retirement/HSA/529 accounts to be locked by default
            final updatedAccount = Account(
              id: account.id,
              name: account.name,
              kind: account.kind,
              balance: account.balance,
              pctCash: account.pctCash,
              pctBonds: account.pctBonds,
              pctUsEq: account.pctUsEq,
              pctIntlEq: account.pctIntlEq,
              pctRealEstate: account.pctRealEstate,
              pctAlt: account.pctAlt,
              updatedAt: account.updatedAt,
              employerStockPct: account.employerStockPct,
              isLocked: true, // Apply correct default
            );
            await _accountsBox.put(account.id, updatedAccount);
          }
        }
        debugPrint('[Migration] v1: Migrated ${accounts.length} accounts');
      }

      // Migration v1 → v2: Added currency field to Settings
      // No action needed - defaults to 'USD' in constructor

      // Update schema version in settings
      final updatedSettings = Settings(
        riskBand: settings.riskBand,
        monthlyEssentials: settings.monthlyEssentials,
        driftThresholdPct: settings.driftThresholdPct,
        notificationsEnabled: settings.notificationsEnabled,
        usEquityTargetPct: settings.usEquityTargetPct,
        isPro: settings.isPro,
        biometricLockEnabled: settings.biometricLockEnabled,
        darkModeEnabled: settings.darkModeEnabled,
        colorTheme: settings.colorTheme,
        liquidityBondHaircut: settings.liquidityBondHaircut,
        bucketCap: settings.bucketCap,
        employerStockThreshold: settings.employerStockThreshold,
        monthlyIncome: settings.monthlyIncome,
        incomeMultiplierFallback: settings.incomeMultiplierFallback,
        schemaVersion: _currentSchemaVersion,
        concentrationRiskSnoozedUntil: settings.concentrationRiskSnoozedUntil,
        concentrationRiskResolvedAt: settings.concentrationRiskResolvedAt,
        homeCountry: settings.homeCountry,
        globalDiversificationMode: settings.globalDiversificationMode,
        intlTargetOverride: settings.intlTargetOverride,
        intlTolerancePct: settings.intlTolerancePct,
        intlFloorPct: settings.intlFloorPct,
        intlPenaltyScale: settings.intlPenaltyScale,
        financialHealthBaseline: settings.financialHealthBaseline,
        financialHealthGlobalScale: settings.financialHealthGlobalScale,
        currency: settings.currency, // Will default to 'USD' for existing users
        proBannerDismissed: settings.proBannerDismissed,
        language: settings.language, // Keep existing language
      );
      await _settingsBox.put('main', updatedSettings);

      debugPrint('[Migration] Schema updated to v$_currentSchemaVersion');
    }
  }

  static Future<void> _ensureHouseholdDefaults() async {
    if (_householdProfilesBox.isEmpty) {
      final primary = HouseholdProfile(
        id: _defaultHouseholdProfileId,
        name: _defaultHouseholdProfileName,
        createdAt: DateTime.now(),
      );
      await _householdProfilesBox.put(primary.id, primary);
    }

    final currentActive = _householdMetaBox.get(_activeHouseholdProfileKey);
    if (currentActive != null &&
        _householdProfilesBox.containsKey(currentActive)) {
      return;
    }

    final fallback = _householdProfilesBox.values.first.id;
    await _householdMetaBox.put(_activeHouseholdProfileKey, fallback);
  }

  static Future<void> _ensureEntityOwnershipDefaults() async {
    await _ensureHouseholdDefaults();
    const defaultProfileId = _defaultHouseholdProfileId;

    for (final account in _accountsBox.values) {
      final owner = _accountOwnersBox.get(account.id);
      if (owner == null || !_householdProfilesBox.containsKey(owner)) {
        await _accountOwnersBox.put(account.id, defaultProfileId);
      }
    }
    for (final liability in _liabilitiesBox.values) {
      final owner = _liabilityOwnersBox.get(liability.id);
      if (owner == null || !_householdProfilesBox.containsKey(owner)) {
        await _liabilityOwnersBox.put(liability.id, defaultProfileId);
      }
    }
    for (final income in _incomesBox.values) {
      final owner = _incomeOwnersBox.get(income.id);
      if (owner == null || !_householdProfilesBox.containsKey(owner)) {
        await _incomeOwnersBox.put(income.id, defaultProfileId);
      }
    }
    for (final expense in _expensesBox.values) {
      final owner = _expenseOwnersBox.get(expense.id);
      if (owner == null || !_householdProfilesBox.containsKey(owner)) {
        await _expenseOwnersBox.put(expense.id, defaultProfileId);
      }
    }
  }

  static Future<void> _ensureHouseholdGoalDefaults() async {
    await _ensureHouseholdDefaults();

    const defaultProfileId = _defaultHouseholdProfileId;
    final profileIds =
        _householdProfilesBox.keys.map((k) => k.toString()).toList();
    final updates = <String, HouseholdGoal>{};

    for (final goal in _householdGoalsBox.values) {
      var needsSave = false;
      if (goal.isShared) {
        if (goal.ownerProfileId != null) {
          goal.ownerProfileId = null;
          needsSave = true;
        }
        final normalizedSplits = _normalizeContributionSplits(
          contributionSplits: goal.contributionSplits,
          profileIds: profileIds,
        );
        if (!_mapsEqual(goal.contributionSplits, normalizedSplits)) {
          goal.contributionSplits = normalizedSplits;
          needsSave = true;
        }
      } else {
        final ownerId = goal.ownerProfileId;
        if (ownerId == null || !_householdProfilesBox.containsKey(ownerId)) {
          goal.ownerProfileId = defaultProfileId;
          needsSave = true;
        }
        if (goal.contributionSplits != null) {
          goal.contributionSplits = null;
          needsSave = true;
        }
      }

      if (goal.currentAmount.isNaN || goal.currentAmount.isInfinite) {
        goal.currentAmount = 0;
        needsSave = true;
      } else if (goal.currentAmount < 0) {
        goal.currentAmount = 0;
        needsSave = true;
      }

      if (needsSave) {
        goal.updatedAt = DateTime.now();
        updates[goal.id] = goal;
      }
    }

    if (updates.isNotEmpty) {
      await _householdGoalsBox.putAll(updates);
    }
  }

  static Map<String, double> _normalizeContributionSplits({
    required Map<String, double>? contributionSplits,
    required List<String> profileIds,
  }) {
    if (profileIds.isEmpty) return const {};
    final sanitized = <String, double>{};
    if (contributionSplits != null) {
      for (final entry in contributionSplits.entries) {
        final profileId = entry.key;
        final value = entry.value;
        if (!profileIds.contains(profileId)) continue;
        if (value.isNaN || value.isInfinite || value < 0) continue;
        sanitized[profileId] = value;
      }
    }

    var sum = 0.0;
    for (final value in sanitized.values) {
      sum += value;
    }

    if (sum <= 0) {
      final equal = 1.0 / profileIds.length;
      return {for (final id in profileIds) id: equal};
    }

    final normalized = <String, double>{};
    for (final id in profileIds) {
      final value = sanitized[id] ?? 0.0;
      normalized[id] = value / sum;
    }
    return normalized;
  }

  static bool _mapsEqual(
    Map<String, double>? a,
    Map<String, double>? b,
  ) {
    final left = a ?? const <String, double>{};
    final right = b ?? const <String, double>{};
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      final rightValue = right[entry.key];
      if (rightValue == null) return false;
      if ((entry.value - rightValue).abs() > 0.000001) return false;
    }
    return true;
  }

  static Future<Map<String, String>> _stringBoxToMap(Box<String> box) async {
    await initialize();
    return box.toMap().map(
          (key, value) => MapEntry(key.toString(), value),
        );
  }

  static Future<void> _importOwnerMap(
    dynamic value,
    Box<String> targetBox,
  ) async {
    if (value is! Map) return;
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final ownerId = entry.value?.toString();
      if (key.isEmpty || ownerId == null || ownerId.isEmpty) continue;
      await targetBox.put(key, ownerId);
    }
  }

  static Future<int> _moveOwnershipBetweenProfiles({
    required Box<String> ownerBox,
    required Box dataBox,
    required String fromProfileId,
    required String toProfileId,
  }) async {
    final updates = <dynamic, String>{};
    final staleKeys = <dynamic>[];
    var movedCount = 0;

    for (final entry in ownerBox.toMap().entries) {
      final key = entry.key;
      final ownerProfileId = entry.value;
      if (!dataBox.containsKey(key)) {
        staleKeys.add(key);
        continue;
      }
      if (ownerProfileId == fromProfileId) {
        updates[key] = toProfileId;
        movedCount++;
      }
    }

    if (staleKeys.isNotEmpty) {
      await ownerBox.deleteAll(staleKeys);
    }
    if (updates.isNotEmpty) {
      await ownerBox.putAll(updates);
    }
    return movedCount;
  }

  static Future<int> _moveAllOwnershipToProfile({
    required Box<String> ownerBox,
    required Box dataBox,
    required String targetProfileId,
  }) async {
    final updates = <dynamic, String>{};
    final staleKeys = <dynamic>[];
    var movedCount = 0;

    for (final entry in ownerBox.toMap().entries) {
      final key = entry.key;
      final ownerProfileId = entry.value;
      if (!dataBox.containsKey(key)) {
        staleKeys.add(key);
        continue;
      }
      if (ownerProfileId != targetProfileId) {
        updates[key] = targetProfileId;
        movedCount++;
      }
    }

    if (staleKeys.isNotEmpty) {
      await ownerBox.deleteAll(staleKeys);
    }
    if (updates.isNotEmpty) {
      await ownerBox.putAll(updates);
    }
    return movedCount;
  }

  static Future<int> _moveGoalsBetweenProfiles({
    required String fromProfileId,
    required String toProfileId,
  }) async {
    final updates = <String, HouseholdGoal>{};
    var movedCount = 0;
    for (final goal in _householdGoalsBox.values) {
      if (goal.isShared) continue;
      if (goal.ownerProfileId == fromProfileId) {
        goal.ownerProfileId = toProfileId;
        goal.updatedAt = DateTime.now();
        updates[goal.id] = goal;
        movedCount++;
      }
    }
    if (updates.isNotEmpty) {
      await _householdGoalsBox.putAll(updates);
    }
    return movedCount;
  }

  static Future<int> _moveAllGoalsToProfile({
    required String targetProfileId,
  }) async {
    final updates = <String, HouseholdGoal>{};
    var movedCount = 0;
    for (final goal in _householdGoalsBox.values) {
      if (goal.isShared) continue;
      if (goal.ownerProfileId != targetProfileId) {
        goal.ownerProfileId = targetProfileId;
        goal.updatedAt = DateTime.now();
        updates[goal.id] = goal;
        movedCount++;
      }
    }
    if (updates.isNotEmpty) {
      await _householdGoalsBox.putAll(updates);
    }
    return movedCount;
  }

  static Map<String, int> _countByOwner({
    required Box dataBox,
    required Box<String> ownerBox,
  }) {
    final counts = <String, int>{};
    for (final key in dataBox.keys) {
      final ownerId = ownerBox.get(key);
      if (ownerId == null || ownerId.isEmpty) continue;
      counts[ownerId] = (counts[ownerId] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> _countGoalsByProfile() {
    final counts = <String, int>{};
    final profileIds =
        _householdProfilesBox.keys.map((k) => k.toString()).toList();
    for (final goal in _householdGoalsBox.values) {
      if (goal.isShared) {
        for (final profileId in profileIds) {
          counts[profileId] = (counts[profileId] ?? 0) + 1;
        }
        continue;
      }
      final ownerId = goal.ownerProfileId;
      if (ownerId == null || ownerId.isEmpty) continue;
      counts[ownerId] = (counts[ownerId] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, double> _sumByOwner<T>({
    required Box<T> dataBox,
    required Box<String> ownerBox,
    required String Function(T item) idOf,
    required double Function(T item) amountOf,
  }) {
    final totals = <String, double>{};
    for (final item in dataBox.values) {
      final key = idOf(item);
      final ownerId = ownerBox.get(key);
      if (ownerId == null || ownerId.isEmpty) continue;
      totals[ownerId] = (totals[ownerId] ?? 0.0) + amountOf(item);
    }
    return totals;
  }

  static Future<Uint8List> _getOrCreateEncryptionKey() async {
    String? keyString = await _secureStorage.read(key: _encryptionKeyKey);

    if (keyString != null) {
      return base64Decode(keyString);
    }

    // Generate new key
    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _encryptionKeyKey,
      value: base64Encode(key),
    );

    return Uint8List.fromList(key);
  }

  // Database recovery method
  static Future<void> clearAllData() async {
    try {
      // Close existing boxes if open
      if (_initialized) {
        await _accountsBox.close();
        await _liabilitiesBox.close();
        await _incomesBox.close();
        await _expensesBox.close();
        await _accountOwnersBox.close();
        await _liabilityOwnersBox.close();
        await _incomeOwnersBox.close();
        await _expenseOwnersBox.close();
        await _settingsBox.close();
        await _snapshotsBox.close();
        await _actionCardsBox.close();
        await _paymentsBox.close();
        await _notificationsBox.close();
        await _workflowImpactLogsBox.close();
        await _householdProfilesBox.close();
        await _householdMetaBox.close();
        await _householdGoalsBox.close();
      }

      // Delete all box files
      await Hive.deleteBoxFromDisk('accounts');
      await Hive.deleteBoxFromDisk('liabilities');
      await Hive.deleteBoxFromDisk('incomes');
      await Hive.deleteBoxFromDisk('expenses');
      await Hive.deleteBoxFromDisk('accountOwners');
      await Hive.deleteBoxFromDisk('liabilityOwners');
      await Hive.deleteBoxFromDisk('incomeOwners');
      await Hive.deleteBoxFromDisk('expenseOwners');
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('snapshots');
      await Hive.deleteBoxFromDisk('actionCards');
      await Hive.deleteBoxFromDisk('payments');
      await Hive.deleteBoxFromDisk('notifications');
      await Hive.deleteBoxFromDisk('workflowImpactLogs');
      await Hive.deleteBoxFromDisk('householdProfiles');
      await Hive.deleteBoxFromDisk('householdMeta');
      await Hive.deleteBoxFromDisk('householdGoals');

      // Reset initialization flag
      _initialized = false;
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  // Account Repository
  static Future<List<Account>> getAccounts() async {
    await initialize();
    final activeProfileId = await getActiveHouseholdProfileId();
    return _accountsBox.values
        .where(
          (account) => _accountOwnersBox.get(account.id) == activeProfileId,
        )
        .toList();
  }

  static Future<void> saveAccount(Account account) async {
    await initialize();
    debugPrint(
      '[Repo::saveAccount] Saving account id=${account.id} name=${account.name} kind=${account.kind} balance=${account.balance}',
    );
    await _accountsBox.put(account.id, account);
    if (!_accountOwnersBox.containsKey(account.id)) {
      final activeProfileId = await getActiveHouseholdProfileId();
      await _accountOwnersBox.put(account.id, activeProfileId);
    }
    debugPrint(
      '[Repo::saveAccount] Box length after save: ${_accountsBox.length}',
    );
  }

  static Future<void> deleteAccount(String id) async {
    await initialize();
    await _accountsBox.delete(id);
    await _accountOwnersBox.delete(id);
  }

  // Liability Repository
  static Future<List<Liability>> getLiabilities() async {
    await initialize();
    final activeProfileId = await getActiveHouseholdProfileId();
    return _liabilitiesBox.values
        .where(
          (liability) =>
              _liabilityOwnersBox.get(liability.id) == activeProfileId,
        )
        .toList();
  }

  static Future<void> saveLiability(Liability liability) async {
    await initialize();
    await _liabilitiesBox.put(liability.id, liability);
    if (!_liabilityOwnersBox.containsKey(liability.id)) {
      final activeProfileId = await getActiveHouseholdProfileId();
      await _liabilityOwnersBox.put(liability.id, activeProfileId);
    }
  }

  static Future<void> deleteLiability(String id) async {
    await initialize();
    await _liabilitiesBox.delete(id);
    await _liabilityOwnersBox.delete(id);
  }

  // Income Repository
  static Future<List<Income>> getIncomes() async {
    await initialize();
    final activeProfileId = await getActiveHouseholdProfileId();
    return _incomesBox.values
        .where((income) => _incomeOwnersBox.get(income.id) == activeProfileId)
        .toList();
  }

  static Future<void> saveIncome(Income income) async {
    await initialize();
    debugPrint(
      '[Repo::saveIncome] Saving income id=${income.id} name=${income.name} kind=${income.kind} monthlyGross=${income.monthlyGross}',
    );
    await _incomesBox.put(income.id, income);
    if (!_incomeOwnersBox.containsKey(income.id)) {
      final activeProfileId = await getActiveHouseholdProfileId();
      await _incomeOwnersBox.put(income.id, activeProfileId);
    }
  }

  static Future<void> deleteIncome(String id) async {
    await initialize();
    await _incomesBox.delete(id);
    await _incomeOwnersBox.delete(id);
  }

  // Monthly Expense Repository
  static Future<List<MonthlyExpense>> getExpenses() async {
    await initialize();
    final activeProfileId = await getActiveHouseholdProfileId();
    return _expensesBox.values
        .where(
          (expense) => _expenseOwnersBox.get(expense.id) == activeProfileId,
        )
        .toList();
  }

  static Future<void> saveExpense(MonthlyExpense expense) async {
    await initialize();
    debugPrint(
      '[Repo::saveExpense] Saving expense id=${expense.id} name=${expense.name} amount=${expense.amount}',
    );
    await _expensesBox.put(expense.id, expense);
    if (!_expenseOwnersBox.containsKey(expense.id)) {
      final activeProfileId = await getActiveHouseholdProfileId();
      await _expenseOwnersBox.put(expense.id, activeProfileId);
    }
  }

  static Future<void> deleteExpense(String id) async {
    await initialize();
    await _expensesBox.delete(id);
    await _expenseOwnersBox.delete(id);
  }

  // Settings Repository
  static Future<Settings> getSettings() async {
    await initialize();

    if (_settingsBox.isEmpty) {
      // Create default settings
      final defaultSettings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0,
        isPro: false, // Ensure Pro is disabled by default
      );
      await _settingsBox.put('main', defaultSettings);
      return defaultSettings;
    }

    final settings = _settingsBox.get('main')!;

    // NOTE: Previously there was a one-time migration here that forcibly
    // reset `settings.isPro = false` on startup. That caused legitimately
    // purchased Pro access to be cleared on each app start. The migration
    // has been removed so Pro purchases persist in the settings box.

    return settings;
  }

  static Future<void> saveSettings(Settings settings) async {
    await initialize();
    await _settingsBox.put('main', settings);
  }

  // Household Profiles Repository
  static Future<List<HouseholdProfile>> getHouseholdProfiles() async {
    await initialize();
    final profiles = _householdProfilesBox.values.toList();
    profiles.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return profiles;
  }

  static Future<String> getActiveHouseholdProfileId() async {
    await initialize();
    await _ensureHouseholdDefaults();
    return _householdMetaBox.get(_activeHouseholdProfileKey) ??
        _defaultHouseholdProfileId;
  }

  static Future<HouseholdProfile?> getActiveHouseholdProfile() async {
    await initialize();
    final activeId = await getActiveHouseholdProfileId();
    return _householdProfilesBox.get(activeId);
  }

  static Future<void> setActiveHouseholdProfile(String profileId) async {
    await initialize();
    if (!_householdProfilesBox.containsKey(profileId)) {
      throw Exception('Profile not found');
    }
    await _householdMetaBox.put(_activeHouseholdProfileKey, profileId);
  }

  static Future<Map<String, HouseholdProfileFinancialCounts>>
      getHouseholdProfileFinancialCounts() async {
    await initialize();
    await _ensureEntityOwnershipDefaults();

    final profileIds =
        _householdProfilesBox.keys.map((k) => k.toString()).toSet();
    final accountCounts =
        _countByOwner(dataBox: _accountsBox, ownerBox: _accountOwnersBox);
    final liabilityCounts =
        _countByOwner(dataBox: _liabilitiesBox, ownerBox: _liabilityOwnersBox);
    final incomeCounts =
        _countByOwner(dataBox: _incomesBox, ownerBox: _incomeOwnersBox);
    final expenseCounts =
        _countByOwner(dataBox: _expensesBox, ownerBox: _expenseOwnersBox);
    final goalCounts = _countGoalsByProfile();

    return {
      for (final profileId in profileIds)
        profileId: HouseholdProfileFinancialCounts(
          accounts: accountCounts[profileId] ?? 0,
          liabilities: liabilityCounts[profileId] ?? 0,
          incomes: incomeCounts[profileId] ?? 0,
          expenses: expenseCounts[profileId] ?? 0,
          goals: goalCounts[profileId] ?? 0,
        ),
    };
  }

  static Future<Map<String, HouseholdProfileFinancialSummary>>
      getHouseholdProfileFinancialSummaries() async {
    await initialize();
    await _ensureEntityOwnershipDefaults();

    final profileIds =
        _householdProfilesBox.keys.map((k) => k.toString()).toSet();
    final accountCounts =
        _countByOwner(dataBox: _accountsBox, ownerBox: _accountOwnersBox);
    final liabilityCounts =
        _countByOwner(dataBox: _liabilitiesBox, ownerBox: _liabilityOwnersBox);
    final incomeCounts =
        _countByOwner(dataBox: _incomesBox, ownerBox: _incomeOwnersBox);
    final expenseCounts =
        _countByOwner(dataBox: _expensesBox, ownerBox: _expenseOwnersBox);
    final goalCounts = _countGoalsByProfile();

    final assetTotals = _sumByOwner<Account>(
      dataBox: _accountsBox,
      ownerBox: _accountOwnersBox,
      idOf: (account) => account.id,
      amountOf: (account) => account.balance,
    );
    final liabilityTotals = _sumByOwner<Liability>(
      dataBox: _liabilitiesBox,
      ownerBox: _liabilityOwnersBox,
      idOf: (liability) => liability.id,
      amountOf: (liability) => liability.balance,
    );
    final incomeTotals = _sumByOwner<Income>(
      dataBox: _incomesBox,
      ownerBox: _incomeOwnersBox,
      idOf: (income) => income.id,
      amountOf: (income) => income.monthlyNet,
    );
    final expenseTotals = _sumByOwner<MonthlyExpense>(
      dataBox: _expensesBox,
      ownerBox: _expenseOwnersBox,
      idOf: (expense) => expense.id,
      amountOf: (expense) => expense.amount,
    );

    return {
      for (final profileId in profileIds)
        profileId: HouseholdProfileFinancialSummary(
          counts: HouseholdProfileFinancialCounts(
            accounts: accountCounts[profileId] ?? 0,
            liabilities: liabilityCounts[profileId] ?? 0,
            incomes: incomeCounts[profileId] ?? 0,
            expenses: expenseCounts[profileId] ?? 0,
            goals: goalCounts[profileId] ?? 0,
          ),
          totalAssets: assetTotals[profileId] ?? 0,
          totalLiabilities: liabilityTotals[profileId] ?? 0,
          monthlyIncome: incomeTotals[profileId] ?? 0,
          monthlyExpenses: expenseTotals[profileId] ?? 0,
        ),
    };
  }

  static Future<HouseholdProfile> addHouseholdProfile(String name) async {
    await initialize();
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw Exception('Profile name cannot be empty');
    }

    final duplicate = _householdProfilesBox.values.any(
      (profile) => profile.name.toLowerCase() == normalized.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('A profile with this name already exists');
    }

    final profile = HouseholdProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: normalized,
      createdAt: DateTime.now(),
    );
    await _householdProfilesBox.put(profile.id, profile);
    await _ensureHouseholdDefaults();
    return profile;
  }

  static Future<void> renameHouseholdProfile(
    String profileId,
    String name,
  ) async {
    await initialize();
    final existing = _householdProfilesBox.get(profileId);
    if (existing == null) {
      throw Exception('Profile not found');
    }

    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw Exception('Profile name cannot be empty');
    }

    final duplicate = _householdProfilesBox.values.any(
      (profile) =>
          profile.id != profileId &&
          profile.name.toLowerCase() == normalized.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('A profile with this name already exists');
    }

    existing.name = normalized;
    await _householdProfilesBox.put(profileId, existing);
  }

  static Future<void> deleteHouseholdProfile(String profileId) async {
    await initialize();
    if (!_householdProfilesBox.containsKey(profileId)) {
      return;
    }
    if (_householdProfilesBox.length <= 1) {
      throw Exception('At least one profile is required');
    }

    final hasFinancialData = _accountsBox.values
            .any((a) => _accountOwnersBox.get(a.id) == profileId) ||
        _liabilitiesBox.values
            .any((l) => _liabilityOwnersBox.get(l.id) == profileId) ||
        _incomesBox.values
            .any((i) => _incomeOwnersBox.get(i.id) == profileId) ||
        _expensesBox.values
            .any((e) => _expenseOwnersBox.get(e.id) == profileId) ||
        _householdGoalsBox.values.any(
          (g) => !g.isShared && g.ownerProfileId == profileId,
        );
    if (hasFinancialData) {
      throw Exception(
        'Profile still has financial data. Move or delete its data first.',
      );
    }

    await _householdProfilesBox.delete(profileId);
    final activeId = _householdMetaBox.get(_activeHouseholdProfileKey);
    if (activeId == profileId) {
      final fallbackId = _householdProfilesBox.values.first.id;
      await _householdMetaBox.put(_activeHouseholdProfileKey, fallbackId);
    }
  }

  static Future<HouseholdDataMoveResult> moveFinancialDataToProfile({
    required String fromProfileId,
    required String toProfileId,
    bool moveAccounts = true,
    bool moveLiabilities = true,
    bool moveIncomes = true,
    bool moveExpenses = true,
    bool moveGoals = true,
  }) async {
    await initialize();
    if (fromProfileId == toProfileId) {
      throw Exception('Source and target profiles must be different');
    }
    if (!moveAccounts &&
        !moveLiabilities &&
        !moveIncomes &&
        !moveExpenses &&
        !moveGoals) {
      throw Exception('Select at least one data type to move');
    }
    if (!_householdProfilesBox.containsKey(fromProfileId)) {
      throw Exception('Source profile not found');
    }
    if (!_householdProfilesBox.containsKey(toProfileId)) {
      throw Exception('Target profile not found');
    }

    final accountsMoved = moveAccounts
        ? await _moveOwnershipBetweenProfiles(
            ownerBox: _accountOwnersBox,
            dataBox: _accountsBox,
            fromProfileId: fromProfileId,
            toProfileId: toProfileId,
          )
        : 0;
    final liabilitiesMoved = moveLiabilities
        ? await _moveOwnershipBetweenProfiles(
            ownerBox: _liabilityOwnersBox,
            dataBox: _liabilitiesBox,
            fromProfileId: fromProfileId,
            toProfileId: toProfileId,
          )
        : 0;
    final incomesMoved = moveIncomes
        ? await _moveOwnershipBetweenProfiles(
            ownerBox: _incomeOwnersBox,
            dataBox: _incomesBox,
            fromProfileId: fromProfileId,
            toProfileId: toProfileId,
          )
        : 0;
    final expensesMoved = moveExpenses
        ? await _moveOwnershipBetweenProfiles(
            ownerBox: _expenseOwnersBox,
            dataBox: _expensesBox,
            fromProfileId: fromProfileId,
            toProfileId: toProfileId,
          )
        : 0;
    final goalsMoved = moveGoals
        ? await _moveGoalsBetweenProfiles(
            fromProfileId: fromProfileId,
            toProfileId: toProfileId,
          )
        : 0;

    return HouseholdDataMoveResult(
      accountsMoved: accountsMoved,
      liabilitiesMoved: liabilitiesMoved,
      incomesMoved: incomesMoved,
      expensesMoved: expensesMoved,
      goalsMoved: goalsMoved,
    );
  }

  static Future<HouseholdDataMoveResult> moveAllFinancialDataToProfile({
    required String targetProfileId,
  }) async {
    await initialize();
    if (!_householdProfilesBox.containsKey(targetProfileId)) {
      throw Exception('Target profile not found');
    }

    final accountsMoved = await _moveAllOwnershipToProfile(
      ownerBox: _accountOwnersBox,
      dataBox: _accountsBox,
      targetProfileId: targetProfileId,
    );
    final liabilitiesMoved = await _moveAllOwnershipToProfile(
      ownerBox: _liabilityOwnersBox,
      dataBox: _liabilitiesBox,
      targetProfileId: targetProfileId,
    );
    final incomesMoved = await _moveAllOwnershipToProfile(
      ownerBox: _incomeOwnersBox,
      dataBox: _incomesBox,
      targetProfileId: targetProfileId,
    );
    final expensesMoved = await _moveAllOwnershipToProfile(
      ownerBox: _expenseOwnersBox,
      dataBox: _expensesBox,
      targetProfileId: targetProfileId,
    );
    final goalsMoved = await _moveAllGoalsToProfile(
      targetProfileId: targetProfileId,
    );

    return HouseholdDataMoveResult(
      accountsMoved: accountsMoved,
      liabilitiesMoved: liabilitiesMoved,
      incomesMoved: incomesMoved,
      expensesMoved: expensesMoved,
      goalsMoved: goalsMoved,
    );
  }

  // Household Goals Repository
  static Future<List<HouseholdGoal>> getAllHouseholdGoals() async {
    await initialize();
    await _ensureHouseholdGoalDefaults();
    final goals = _householdGoalsBox.values.toList();
    goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return goals;
  }

  static Future<List<HouseholdGoal>> getHouseholdGoals({
    String? profileId,
    bool includeShared = true,
  }) async {
    await initialize();
    await _ensureHouseholdGoalDefaults();
    final resolvedProfileId = profileId ?? await getActiveHouseholdProfileId();
    final goals = _householdGoalsBox.values.where((goal) {
      if (goal.isShared) return includeShared;
      return goal.ownerProfileId == resolvedProfileId;
    }).toList();
    goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return goals;
  }

  static Future<HouseholdGoal> addHouseholdGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    bool isShared = false,
    String? ownerProfileId,
    Map<String, double>? contributionSplits,
    String? notes,
  }) async {
    await initialize();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw Exception('Goal name cannot be empty');
    }
    if (targetAmount < 0) {
      throw Exception('Goal target amount cannot be negative');
    }
    if (currentAmount < 0) {
      throw Exception('Goal current amount cannot be negative');
    }

    final resolvedOwnerId = isShared
        ? null
        : (ownerProfileId ?? await getActiveHouseholdProfileId());
    if (!isShared &&
        (resolvedOwnerId == null ||
            !_householdProfilesBox.containsKey(resolvedOwnerId))) {
      throw Exception('Goal owner profile not found');
    }
    final profileIds =
        _householdProfilesBox.keys.map((k) => k.toString()).toList();
    final normalizedSplits = isShared
        ? _normalizeContributionSplits(
            contributionSplits: contributionSplits,
            profileIds: profileIds,
          )
        : null;

    final now = DateTime.now();
    final goal = HouseholdGoal(
      id: now.microsecondsSinceEpoch.toString(),
      name: normalizedName,
      targetAmount: targetAmount,
      createdAt: now,
      updatedAt: now,
      isShared: isShared,
      ownerProfileId: resolvedOwnerId,
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      currentAmount: currentAmount,
      contributionSplits: normalizedSplits,
    );
    await _householdGoalsBox.put(goal.id, goal);
    await _ensureHouseholdGoalDefaults();
    return goal;
  }

  static Future<void> saveHouseholdGoal(HouseholdGoal goal) async {
    await initialize();
    final normalizedName = goal.name.trim();
    if (normalizedName.isEmpty) {
      throw Exception('Goal name cannot be empty');
    }
    if (goal.targetAmount < 0) {
      throw Exception('Goal target amount cannot be negative');
    }
    if (goal.currentAmount < 0) {
      throw Exception('Goal current amount cannot be negative');
    }
    goal.name = normalizedName;
    if (goal.isShared) {
      goal.ownerProfileId = null;
      final profileIds =
          _householdProfilesBox.keys.map((k) => k.toString()).toList();
      goal.contributionSplits = _normalizeContributionSplits(
        contributionSplits: goal.contributionSplits,
        profileIds: profileIds,
      );
    } else {
      final ownerId =
          goal.ownerProfileId ?? await getActiveHouseholdProfileId();
      if (!_householdProfilesBox.containsKey(ownerId)) {
        throw Exception('Goal owner profile not found');
      }
      goal.ownerProfileId = ownerId;
      goal.contributionSplits = null;
    }
    goal.updatedAt = DateTime.now();
    await _householdGoalsBox.put(goal.id, goal);
  }

  static Future<void> deleteHouseholdGoal(String goalId) async {
    await initialize();
    await _householdGoalsBox.delete(goalId);
  }

  // Snapshot Repository
  static Future<List<Snapshot>> getSnapshots() async {
    await initialize();
    final snapshots = _snapshotsBox.values.toList();
    snapshots.sort((a, b) => a.at.compareTo(b.at));
    return snapshots;
  }

  static Future<void> saveSnapshot(Snapshot snapshot) async {
    await initialize();
    await _snapshotsBox.put(
      snapshot.at.millisecondsSinceEpoch.toString(),
      snapshot,
    );
  }

  static Future<void> deleteSnapshot(DateTime date) async {
    await initialize();
    await _snapshotsBox.delete(date.millisecondsSinceEpoch.toString());
  }

  // Action Card Repository
  static Future<List<ActionCard>> getActiveActionCards() async {
    await initialize();
    return _actionCardsBox.values.where((card) => card.isActive).toList();
  }

  static Future<List<ActionCard>> getAllActionCards() async {
    await initialize();
    return _actionCardsBox.values.toList();
  }

  static Future<void> saveActionCard(ActionCard card) async {
    await initialize();
    await _actionCardsBox.put(card.id, card);
  }

  static Future<void> deleteActionCard(String id) async {
    await initialize();
    await _actionCardsBox.delete(id);
  }

  // Workflow Impact Repository
  static Future<List<Map<String, dynamic>>> getWorkflowImpactLogs() async {
    await initialize();
    final logs = _workflowImpactLogsBox.values
        .map((entry) => _toStringDynamicMap(entry))
        .toList();
    logs.sort((a, b) {
      final aStarted = _toDateTime(a['startedAt']);
      final bStarted = _toDateTime(b['startedAt']);
      if (aStarted == null && bStarted == null) return 0;
      if (aStarted == null) return 1;
      if (bStarted == null) return -1;
      return bStarted.compareTo(aStarted);
    });
    return logs;
  }

  static Future<void> saveWorkflowImpactLog(Map<String, dynamic> log) async {
    await initialize();
    final id = log['id']?.toString().trim() ?? '';
    if (id.isEmpty) {
      throw Exception('Workflow impact log id is required');
    }
    final normalized = _toStringDynamicMap(log);
    normalized['id'] = id;
    await _workflowImpactLogsBox.put(id, normalized);
  }

  static Future<void> deleteWorkflowImpactLog(String id) async {
    await initialize();
    await _workflowImpactLogsBox.delete(id);
  }

  // Notifications Repository
  static Future<List<AppNotification>> getNotifications() async {
    await initialize();
    final list = _notificationsBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<void> saveNotification(AppNotification n) async {
    await initialize();
    await _notificationsBox.put(n.id, n);
  }

  static Future<void> saveNotifications(List<AppNotification> list) async {
    await initialize();
    await _notificationsBox.putAll({for (var n in list) n.id: n});
  }

  static Future<void> deleteNotification(String id) async {
    await initialize();
    await _notificationsBox.delete(id);
  }

  static Future<void> markNotificationRead(String id) async {
    await initialize();
    final n = _notificationsBox.get(id);
    if (n != null) {
      n.read = true;
      await n.save();
    }
  }

  static Future<void> dismissNotification(String id) async {
    await initialize();
    final n = _notificationsBox.get(id);
    if (n != null) {
      n.dismissed = true;
      await n.save();
    }
  }

  static Future<void> markAllRead() async {
    await initialize();
    for (final notification in _notificationsBox.values) {
      if (!notification.read) {
        notification.read = true;
        await notification.save();
      }
    }
  }

  // Utility methods
  static Future<Map<String, dynamic>> exportData() async {
    await initialize();

    return {
      'backupSchemaVersion': 4,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': _accountsBox.values.map((a) => _accountToJson(a)).toList(),
      'liabilities':
          _liabilitiesBox.values.map((l) => _liabilityToJson(l)).toList(),
      'incomes': _incomesBox.values.map((i) => _incomeToJson(i)).toList(),
      'expenses': _expensesBox.values.map((e) => _expenseToJson(e)).toList(),
      'accountOwners': await _stringBoxToMap(_accountOwnersBox),
      'liabilityOwners': await _stringBoxToMap(_liabilityOwnersBox),
      'incomeOwners': await _stringBoxToMap(_incomeOwnersBox),
      'expenseOwners': await _stringBoxToMap(_expenseOwnersBox),
      'settings': _settingsToJson(await getSettings()),
      'snapshots': _snapshotsBox.values.map((s) => _snapshotToJson(s)).toList(),
      'actionCards':
          _actionCardsBox.values.map((c) => _actionCardToJson(c)).toList(),
      'payments': _paymentsBox.values.map((p) => _paymentToJson(p)).toList(),
      'notifications':
          _notificationsBox.values.map((n) => _notificationToJson(n)).toList(),
      'workflowImpactLogs':
          _workflowImpactLogsBox.values.map(_toStringDynamicMap).toList(),
      'householdProfiles': _householdProfilesBox.values
          .map((p) => _householdProfileToJson(p))
          .toList(),
      'activeHouseholdProfileId':
          _householdMetaBox.get(_activeHouseholdProfileKey),
      'householdGoals': _householdGoalsBox.values
          .map((g) => _householdGoalToJson(g))
          .toList(),
    };
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    await initialize();

    // Clear existing data first, then restore all supported domains.
    await clearAllData();

    for (final accountData in _asMapList(data['accounts'])) {
      await saveAccount(_accountFromJson(accountData));
    }

    for (final liabilityData in _asMapList(data['liabilities'])) {
      await saveLiability(_liabilityFromJson(liabilityData));
    }

    for (final incomeData in _asMapList(data['incomes'])) {
      await saveIncome(_incomeFromJson(incomeData));
    }

    for (final expenseData in _asMapList(data['expenses'])) {
      await saveExpense(_expenseFromJson(expenseData));
    }

    await _importOwnerMap(data['accountOwners'], _accountOwnersBox);
    await _importOwnerMap(data['liabilityOwners'], _liabilityOwnersBox);
    await _importOwnerMap(data['incomeOwners'], _incomeOwnersBox);
    await _importOwnerMap(data['expenseOwners'], _expenseOwnersBox);

    final settingsData = _asMapOrNull(data['settings']);
    if (settingsData != null) {
      await saveSettings(_settingsFromJson(settingsData));
    }

    for (final profileData in _asMapList(data['householdProfiles'])) {
      final profile = _householdProfileFromJson(profileData);
      await _householdProfilesBox.put(profile.id, profile);
    }

    final activeProfileId = data['activeHouseholdProfileId']?.toString();
    if (activeProfileId != null && activeProfileId.isNotEmpty) {
      await _householdMetaBox.put(_activeHouseholdProfileKey, activeProfileId);
    }
    await _ensureHouseholdDefaults();
    await _ensureEntityOwnershipDefaults();

    for (final goalData in _asMapList(data['householdGoals'])) {
      final goal = _householdGoalFromJson(goalData);
      await _householdGoalsBox.put(goal.id, goal);
    }
    await _ensureHouseholdGoalDefaults();

    for (final snapshotData in _asMapList(data['snapshots'])) {
      await saveSnapshot(_snapshotFromJson(snapshotData));
    }

    for (final cardData in _asMapList(data['actionCards'])) {
      await saveActionCard(_actionCardFromJson(cardData));
    }

    for (final paymentData in _asMapList(data['payments'])) {
      await savePayment(_paymentFromJson(paymentData));
    }

    for (final notificationData in _asMapList(data['notifications'])) {
      await saveNotification(_notificationFromJson(notificationData));
    }

    for (final logData in _asMapList(data['workflowImpactLogs'])) {
      await saveWorkflowImpactLog(logData);
    }
  }

  // Payment Repository
  static Future<List<Payment>> getPayments() async {
    await initialize();
    final payments = _paymentsBox.values.toList();
    payments
        .sort((a, b) => b.paidDate.compareTo(a.paidDate)); // Most recent first
    return payments;
  }

  static Future<List<Payment>> getPaymentsForLiability(
    String liabilityId,
  ) async {
    await initialize();
    final payments = _paymentsBox.values
        .where((payment) => payment.liabilityId == liabilityId)
        .toList();
    payments
        .sort((a, b) => b.paidDate.compareTo(a.paidDate)); // Most recent first
    return payments;
  }

  static Future<void> savePayment(Payment payment) async {
    await initialize();
    await _paymentsBox.put(payment.id, payment);
  }

  static Future<void> deletePayment(String id) async {
    await initialize();
    await _paymentsBox.delete(id);
  }

  static Future<Payment?> getPayment(String id) async {
    await initialize();
    return _paymentsBox.get(id);
  }

  // JSON serialization helpers
  static Map<String, dynamic> _accountToJson(Account account) => {
        'id': account.id,
        'name': account.name,
        'kind': account.kind,
        'balance': account.balance,
        'pctCash': account.pctCash,
        'pctBonds': account.pctBonds,
        'pctUsEq': account.pctUsEq,
        'pctIntlEq': account.pctIntlEq,
        'pctRealEstate': account.pctRealEstate,
        'pctAlt': account.pctAlt,
        'updatedAt': account.updatedAt.toIso8601String(),
        'employerStockPct': account.employerStockPct,
        'isLocked': account.isLocked,
        'originalCurrency': account.originalCurrency,
        'originalBalance': account.originalBalance,
      };

  static Account _accountFromJson(Map<String, dynamic> json) => Account(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        kind: (json['kind'] ?? 'other').toString(),
        balance: _toDouble(json['balance']),
        pctCash: _toDouble(json['pctCash']),
        pctBonds: _toDouble(json['pctBonds']),
        pctUsEq: _toDouble(json['pctUsEq']),
        pctIntlEq: _toDouble(json['pctIntlEq']),
        pctRealEstate: _toDouble(json['pctRealEstate']),
        pctAlt: _toDouble(json['pctAlt']),
        updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
        employerStockPct: _toDouble(json['employerStockPct']),
        isLocked: _toBool(json['isLocked']),
        originalCurrency: json['originalCurrency']?.toString(),
        originalBalance: _toDoubleOrNull(json['originalBalance']),
      );

  static Map<String, dynamic> _liabilityToJson(Liability liability) => {
        'id': liability.id,
        'name': liability.name,
        'kind': liability.kind,
        'balance': liability.balance,
        'apr': liability.apr,
        'minPayment': liability.minPayment,
        'creditLimit': liability.creditLimit,
        'nextPaymentDate': liability.nextPaymentDate?.toIso8601String(),
        'paymentFrequencyDays': liability.paymentFrequencyDays,
        'dayOfMonth': liability.dayOfMonth,
        'updatedAt': liability.updatedAt.toIso8601String(),
        'originalCurrency': liability.originalCurrency,
        'originalBalance': liability.originalBalance,
        'originalMinPayment': liability.originalMinPayment,
        'originalCreditLimit': liability.originalCreditLimit,
      };

  static Liability _liabilityFromJson(Map<String, dynamic> json) => Liability(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        kind: (json['kind'] ?? 'other').toString(),
        balance: _toDouble(json['balance']),
        apr: _toDouble(json['apr']),
        minPayment: _toDouble(json['minPayment']),
        creditLimit: _toDoubleOrNull(json['creditLimit']),
        nextPaymentDate: _toDateTime(json['nextPaymentDate']),
        paymentFrequencyDays: _toIntOrNull(json['paymentFrequencyDays']),
        dayOfMonth: _toIntOrNull(json['dayOfMonth']),
        updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
        originalCurrency: json['originalCurrency']?.toString(),
        originalBalance: _toDoubleOrNull(json['originalBalance']),
        originalMinPayment: _toDoubleOrNull(json['originalMinPayment']),
        originalCreditLimit: _toDoubleOrNull(json['originalCreditLimit']),
      );

  static Map<String, dynamic> _incomeToJson(Income income) => {
        'id': income.id,
        'name': income.name,
        'kind': income.kind,
        'grossAmount': income.grossAmount,
        'frequency': income.frequency,
        'updatedAt': income.updatedAt.toIso8601String(),
        'federalTax': income.federalTax,
        'stateTax': income.stateTax,
        'socialSecurityTax': income.socialSecurityTax,
        'medicareTax': income.medicareTax,
        'retirement401k': income.retirement401k,
        'healthInsurance': income.healthInsurance,
        'otherDeductions': income.otherDeductions,
        'originalCurrency': income.originalCurrency,
        'originalAmount': income.originalAmount,
      };

  static Income _incomeFromJson(Map<String, dynamic> json) => Income(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        kind: (json['kind'] ?? 'other').toString(),
        grossAmount: _toDouble(json['grossAmount']),
        frequency: (json['frequency'] ?? 'monthly').toString(),
        updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
        federalTax: _toDoubleOrNull(json['federalTax']),
        stateTax: _toDoubleOrNull(json['stateTax']),
        socialSecurityTax: _toDoubleOrNull(json['socialSecurityTax']),
        medicareTax: _toDoubleOrNull(json['medicareTax']),
        retirement401k: _toDoubleOrNull(json['retirement401k']),
        healthInsurance: _toDoubleOrNull(json['healthInsurance']),
        otherDeductions: _toDoubleOrNull(json['otherDeductions']),
        originalCurrency: json['originalCurrency']?.toString(),
        originalAmount: _toDoubleOrNull(json['originalAmount']),
      );

  static Map<String, dynamic> _expenseToJson(MonthlyExpense expense) => {
        'id': expense.id,
        'name': expense.name,
        'amount': expense.amount,
        'updatedAt': expense.updatedAt.toIso8601String(),
        'dueDay': expense.dueDay,
        'category': expense.category,
        'originalCurrency': expense.originalCurrency,
        'originalAmount': expense.originalAmount,
      };

  static MonthlyExpense _expenseFromJson(Map<String, dynamic> json) =>
      MonthlyExpense(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        amount: _toDouble(json['amount']),
        updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
        dueDay: _toIntOrNull(json['dueDay']),
        category: json['category']?.toString(),
        originalCurrency: json['originalCurrency']?.toString(),
        originalAmount: _toDoubleOrNull(json['originalAmount']),
      );

  static Map<String, dynamic> _settingsToJson(Settings settings) => {
        'riskBand': settings.riskBand.name,
        'monthlyEssentials': settings.monthlyEssentials,
        'driftThresholdPct': settings.driftThresholdPct,
        'notificationsEnabled': settings.notificationsEnabled,
        'usEquityTargetPct': settings.usEquityTargetPct,
        'isPro': settings.isPro,
        'biometricLockEnabled': settings.biometricLockEnabled,
        'darkModeEnabled': settings.darkModeEnabled,
        'colorTheme': settings.colorTheme.name,
        'liquidityBondHaircut': settings.liquidityBondHaircut,
        'bucketCap': settings.bucketCap,
        'employerStockThreshold': settings.employerStockThreshold,
        'monthlyIncome': settings.monthlyIncome,
        'incomeMultiplierFallback': settings.incomeMultiplierFallback,
        'schemaVersion': settings.schemaVersion,
        'concentrationRiskSnoozedUntil':
            settings.concentrationRiskSnoozedUntil?.toIso8601String(),
        'concentrationRiskResolvedAt': settings.concentrationRiskResolvedAt,
        'homeCountry': settings.homeCountry,
        'globalDiversificationMode': settings.globalDiversificationMode,
        'intlTargetOverride': settings.intlTargetOverride,
        'intlTolerancePct': settings.intlTolerancePct,
        'intlFloorPct': settings.intlFloorPct,
        'intlPenaltyScale': settings.intlPenaltyScale,
        'financialHealthBaseline': settings.financialHealthBaseline,
        'financialHealthGlobalScale': settings.financialHealthGlobalScale,
        'currency': settings.currency,
        'baseCurrency': settings.baseCurrency,
        'proBannerDismissed': settings.proBannerDismissed,
        'language': settings.language,
        'proExpiryDate': settings.proExpiryDate?.toIso8601String(),
      };

  static Settings _settingsFromJson(Map<String, dynamic> json) {
    final modeRaw =
        (json['globalDiversificationMode'] ?? 'off').toString().toLowerCase();
    final mode =
        (modeRaw == 'standard' || modeRaw == 'light' || modeRaw == 'off')
            ? modeRaw
            : 'off';
    return Settings(
      riskBand: _parseRiskBand(json['riskBand']),
      monthlyEssentials: _toDouble(json['monthlyEssentials'], fallback: 0.0),
      driftThresholdPct: _toRatio(json['driftThresholdPct'], fallback: 0.05),
      notificationsEnabled:
          _toBool(json['notificationsEnabled'], fallback: true),
      usEquityTargetPct: _toRatio(json['usEquityTargetPct'], fallback: 0.8),
      isPro: _toBool(json['isPro']),
      proExpiryDate: _toDateTime(json['proExpiryDate']),
      biometricLockEnabled: _toBool(json['biometricLockEnabled']),
      darkModeEnabled: _toBool(json['darkModeEnabled']),
      colorTheme: _parseColorTheme(json['colorTheme']),
      liquidityBondHaircut:
          _toRatio(json['liquidityBondHaircut'], fallback: 0.5),
      bucketCap: _toRatio(json['bucketCap'], fallback: 0.2),
      employerStockThreshold:
          _toRatio(json['employerStockThreshold'], fallback: 0.10),
      monthlyIncome: _toDoubleOrNull(json['monthlyIncome']),
      incomeMultiplierFallback:
          _toDouble(json['incomeMultiplierFallback'], fallback: 3.0),
      schemaVersion: _toIntOrNull(json['schemaVersion']),
      concentrationRiskSnoozedUntil:
          _toDateTime(json['concentrationRiskSnoozedUntil']),
      concentrationRiskResolvedAt:
          _toDoubleOrNull(json['concentrationRiskResolvedAt']),
      homeCountry: (json['homeCountry'] ?? 'US').toString(),
      globalDiversificationMode: mode,
      intlTargetOverride: _toDoubleOrNull(json['intlTargetOverride']),
      intlTolerancePct: _toRatio(json['intlTolerancePct'], fallback: 0.05),
      intlFloorPct: _toDouble(json['intlFloorPct'], fallback: 60.0),
      intlPenaltyScale: _toDouble(json['intlPenaltyScale'], fallback: 60.0),
      financialHealthBaseline:
          _toDouble(json['financialHealthBaseline'], fallback: 75.0),
      financialHealthGlobalScale:
          _toDouble(json['financialHealthGlobalScale'], fallback: 0.6),
      currency: (json['currency'] ?? 'USD').toString(),
      baseCurrency: (json['baseCurrency'] ?? 'USD').toString(),
      proBannerDismissed: json['proBannerDismissed'] as bool?,
      language: (json['language'] ?? 'en').toString(),
    );
  }

  static Map<String, dynamic> _householdProfileToJson(
    HouseholdProfile profile,
  ) =>
      {
        'id': profile.id,
        'name': profile.name,
        'createdAt': profile.createdAt.toIso8601String(),
      };

  static HouseholdProfile _householdProfileFromJson(
    Map<String, dynamic> json,
  ) =>
      HouseholdProfile(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Profile').toString(),
        createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
      );

  static Map<String, dynamic> _householdGoalToJson(HouseholdGoal goal) => {
        'id': goal.id,
        'name': goal.name,
        'targetAmount': goal.targetAmount,
        'currentAmount': goal.currentAmount,
        'createdAt': goal.createdAt.toIso8601String(),
        'updatedAt': goal.updatedAt.toIso8601String(),
        'isShared': goal.isShared,
        'ownerProfileId': goal.ownerProfileId,
        'notes': goal.notes,
        'contributionSplits': goal.contributionSplits,
      };

  static HouseholdGoal _householdGoalFromJson(Map<String, dynamic> json) =>
      HouseholdGoal(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Goal').toString(),
        targetAmount: _toDouble(json['targetAmount']),
        currentAmount: _toDouble(json['currentAmount']),
        createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
        updatedAt: _toDateTime(json['updatedAt']) ?? DateTime.now(),
        isShared: _toBool(json['isShared']),
        ownerProfileId: json['ownerProfileId']?.toString(),
        notes: json['notes']?.toString(),
        contributionSplits: _toStringDoubleMap(json['contributionSplits']),
      );

  static Map<String, dynamic> _snapshotToJson(Snapshot snapshot) => {
        'at': snapshot.at.toIso8601String(),
        'netWorth': snapshot.netWorth,
        'cashTotal': snapshot.cashTotal,
        'bondsTotal': snapshot.bondsTotal,
        'usEqTotal': snapshot.usEqTotal,
        'intlEqTotal': snapshot.intlEqTotal,
        'reTotal': snapshot.reTotal,
        'altTotal': snapshot.altTotal,
        'liabilitiesTotal': snapshot.liabilitiesTotal,
        'note': snapshot.note,
        'source': snapshot.source,
        'diversificationMode': snapshot.diversificationMode,
      };

  static Snapshot _snapshotFromJson(Map<String, dynamic> json) => Snapshot(
        at: _toDateTime(json['at']) ?? DateTime.now(),
        netWorth: _toDouble(json['netWorth']),
        cashTotal: _toDouble(json['cashTotal']),
        bondsTotal: _toDouble(json['bondsTotal']),
        usEqTotal: _toDouble(json['usEqTotal']),
        intlEqTotal: _toDouble(json['intlEqTotal']),
        reTotal: _toDouble(json['reTotal']),
        altTotal: _toDouble(json['altTotal']),
        liabilitiesTotal: _toDouble(json['liabilitiesTotal']),
        note: json['note']?.toString(),
        source: (json['source'] ?? 'auto').toString(),
        diversificationMode: json['diversificationMode']?.toString(),
      );

  static Map<String, dynamic> _actionCardToJson(ActionCard card) => {
        'id': card.id,
        'type': card.type,
        'title': card.title,
        'description': card.description,
        'createdAt': card.createdAt.toIso8601String(),
        'completedAt': card.completedAt?.toIso8601String(),
        'hiddenUntil': card.hiddenUntil?.toIso8601String(),
        'data': card.data,
      };

  static ActionCard _actionCardFromJson(Map<String, dynamic> json) =>
      ActionCard(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
        completedAt: _toDateTime(json['completedAt']),
        hiddenUntil: _toDateTime(json['hiddenUntil']),
        data: _toStringDynamicMap(json['data']),
      );

  static Map<String, dynamic> _paymentToJson(Payment payment) => {
        'id': payment.id,
        'liabilityId': payment.liabilityId,
        'amount': payment.amount,
        'paidDate': payment.paidDate.toIso8601String(),
        'paymentType': payment.paymentType,
        'notes': payment.notes,
        'createdAt': payment.createdAt.toIso8601String(),
        'previousBalance': payment.previousBalance,
        'newBalance': payment.newBalance,
      };

  static Payment _paymentFromJson(Map<String, dynamic> json) => Payment(
        id: (json['id'] ?? '').toString(),
        liabilityId: (json['liabilityId'] ?? '').toString(),
        amount: _toDouble(json['amount']),
        paidDate: _toDateTime(json['paidDate']) ?? DateTime.now(),
        paymentType: (json['paymentType'] ?? 'custom').toString(),
        notes: json['notes']?.toString(),
        createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
        previousBalance: _toDoubleOrNull(json['previousBalance']),
        newBalance: _toDoubleOrNull(json['newBalance']),
      );

  static Map<String, dynamic> _notificationToJson(AppNotification n) => {
        'id': n.id,
        'title': n.title,
        'message': n.message,
        'type': n.type.name,
        'severity': n.severity.name,
        'createdAt': n.createdAt.toIso8601String(),
        'read': n.read,
        'dismissed': n.dismissed,
        'route': n.route,
        'data': n.data,
      };

  static AppNotification _notificationFromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
        type: _parseNotificationType(json['type']),
        severity: _parseNotificationSeverity(json['severity']),
        createdAt: _toDateTime(json['createdAt']) ?? DateTime.now(),
        read: _toBool(json['read']),
        dismissed: _toBool(json['dismissed']),
        route: json['route']?.toString(),
        data: _toStringDynamicMap(json['data']),
      );

  // Parsing helpers
  static Map<String, dynamic> _toStringDynamicMap(dynamic value) {
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return {};
  }

  static Map<String, double>? _toStringDoubleMap(dynamic value) {
    if (value is! Map) return null;
    final result = <String, double>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      final mapValue = entry.value;
      if (key.isEmpty || mapValue == null) continue;
      final parsed = _toDoubleOrNull(mapValue);
      if (parsed == null) continue;
      result[key] = parsed;
    }
    return result;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => item.map(
              (key, mapValue) => MapEntry(key.toString(), mapValue),
            ),
          )
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic>? _asMapOrNull(dynamic value) {
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry(key.toString(), mapValue));
    }
    return null;
  }

  static double _toDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  // Accept both ratio (0..1) and percent-style (0..100) legacy values.
  static double _toRatio(dynamic value, {required double fallback}) {
    final parsed = _toDouble(value, fallback: fallback);
    if (parsed > 1.0 && parsed <= 100.0) return parsed / 100.0;
    return parsed;
  }

  static RiskBand _parseRiskBand(dynamic value) {
    final raw = (value ?? '').toString();
    final normalized =
        raw.contains('.') ? raw.substring(raw.lastIndexOf('.') + 1) : raw;
    return RiskBand.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => RiskBand.balanced,
    );
  }

  static ColorTheme _parseColorTheme(dynamic value) {
    final raw = (value ?? '').toString();
    final normalized =
        raw.contains('.') ? raw.substring(raw.lastIndexOf('.') + 1) : raw;
    return ColorTheme.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => ColorTheme.green,
    );
  }

  static NotificationType _parseNotificationType(dynamic value) {
    final raw = (value ?? '').toString();
    final normalized =
        raw.contains('.') ? raw.substring(raw.lastIndexOf('.') + 1) : raw;
    return NotificationType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => NotificationType.system,
    );
  }

  static NotificationSeverity _parseNotificationSeverity(dynamic value) {
    final raw = (value ?? '').toString();
    final normalized =
        raw.contains('.') ? raw.substring(raw.lastIndexOf('.') + 1) : raw;
    return NotificationSeverity.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => NotificationSeverity.info,
    );
  }
}
