import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class RepositoryService {
  static const _encryptionKeyKey = 'wealth_dial_encryption_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static late Box<Account> _accountsBox;
  static late Box<Liability> _liabilitiesBox;
  static late Box<Settings> _settingsBox;
  static late Box<Snapshot> _snapshotsBox;
  static late Box<ActionCard> _actionCardsBox;
  static late Box<Payment> _paymentsBox;
  static late Box<AppNotification> _notificationsBox;

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

    // Get or generate encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // Open encrypted boxes with error recovery
    try {
      _accountsBox = await Hive.openBox<Account>(
        'accounts',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      // Do NOT automatically delete the user's data on open failure.
      // Record the failure and rethrow so callers can surface diagnostics
      debugPrint('[Repository] Failed to open "accounts" box: $e');
      rethrow;
    }

    try {
      _liabilitiesBox = await Hive.openBox<Liability>(
        'liabilities',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "liabilities" box: $e');
      rethrow;
    }

    try {
      _settingsBox = await Hive.openBox<Settings>(
        'settings',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "settings" box: $e');
      rethrow;
    }

    try {
      _snapshotsBox = await Hive.openBox<Snapshot>(
        'snapshots',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "snapshots" box: $e');
      rethrow;
    }

    try {
      _actionCardsBox = await Hive.openBox<ActionCard>(
        'actionCards',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "actionCards" box: $e');
      rethrow;
    }

    try {
      _paymentsBox = await Hive.openBox<Payment>(
        'payments',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "payments" box: $e');
      rethrow;
    }

    try {
      _notificationsBox = await Hive.openBox<AppNotification>(
        'notifications',
        encryptionCipher: HiveAesCipher(encryptionKey),
      );
    } catch (e) {
      debugPrint('[Repository] Failed to open "notifications" box: $e');
      rethrow;
    }

    _initialized = true;

    // Run any necessary data migrations
    await _runMigrations();
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
      'settings',
      'snapshots',
      'actionCards',
      'payments',
      'notifications',
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
      );
      await _settingsBox.put('main', updatedSettings);

      debugPrint('[Migration] Schema updated to v$_currentSchemaVersion');
    }
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
        await _settingsBox.close();
        await _snapshotsBox.close();
        await _actionCardsBox.close();
        await _paymentsBox.close();
        await _notificationsBox.close();
        await Hive.deleteBoxFromDisk('payments');
        await Hive.deleteBoxFromDisk('notifications');
      }

      // Delete all box files
      await Hive.deleteBoxFromDisk('accounts');
      await Hive.deleteBoxFromDisk('liabilities');
      await Hive.deleteBoxFromDisk('settings');
      await Hive.deleteBoxFromDisk('snapshots');
      await Hive.deleteBoxFromDisk('actionCards');
      await Hive.deleteBoxFromDisk('payments');
      await Hive.deleteBoxFromDisk('notifications');

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
    return _accountsBox.values.toList();
  }

  static Future<void> saveAccount(Account account) async {
    await initialize();
    debugPrint(
      '[Repo::saveAccount] Saving account id=${account.id} name=${account.name} kind=${account.kind} balance=${account.balance}',
    );
    await _accountsBox.put(account.id, account);
    debugPrint(
      '[Repo::saveAccount] Box length after save: ${_accountsBox.length}',
    );
  }

  static Future<void> deleteAccount(String id) async {
    await initialize();
    await _accountsBox.delete(id);
  }

  // Liability Repository
  static Future<List<Liability>> getLiabilities() async {
    await initialize();
    return _liabilitiesBox.values.toList();
  }

  static Future<void> saveLiability(Liability liability) async {
    await initialize();
    await _liabilitiesBox.put(liability.id, liability);
  }

  static Future<void> deleteLiability(String id) async {
    await initialize();
    await _liabilitiesBox.delete(id);
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
    // NOTE: Previously a one-time migration reset the Pro flag to false.
    // That behavior caused granted Pro access to be cleared on startup.
    // We intentionally no longer reset the 'isPro' flag here so purchases
    // granted via the purchase service persist in the settings box.
  }

  // Utility methods

  static Future<Map<String, dynamic>> exportData() async {
    await initialize();

    return {
      'accounts': _accountsBox.values.map((a) => _accountToJson(a)).toList(),
      'liabilities':
          _liabilitiesBox.values.map((l) => _liabilityToJson(l)).toList(),
      'settings': _settingsToJson(await getSettings()),
      'snapshots': _snapshotsBox.values.map((s) => _snapshotToJson(s)).toList(),
      'actionCards':
          _actionCardsBox.values.map((c) => _actionCardToJson(c)).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    await initialize();

    // Clear existing data
    await clearAllData();

    // Import accounts
    if (data['accounts'] != null) {
      for (final accountData in data['accounts']) {
        final account = _accountFromJson(accountData);
        await saveAccount(account);
      }
    }

    // Import liabilities
    if (data['liabilities'] != null) {
      for (final liabilityData in data['liabilities']) {
        final liability = _liabilityFromJson(liabilityData);
        await saveLiability(liability);
      }
    }

    // Import settings
    if (data['settings'] != null) {
      final settings = _settingsFromJson(data['settings']);
      await saveSettings(settings);
    }

    // Import snapshots
    if (data['snapshots'] != null) {
      for (final snapshotData in data['snapshots']) {
        final snapshot = _snapshotFromJson(snapshotData);
        await saveSnapshot(snapshot);
      }
    }

    // Import action cards
    if (data['actionCards'] != null) {
      for (final cardData in data['actionCards']) {
        final card = _actionCardFromJson(cardData);
        await saveActionCard(card);
      }
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
        'employerStockPct': account.employerStockPct,
        'updatedAt': account.updatedAt.toIso8601String(),
      };

  static Account _accountFromJson(Map<String, dynamic> json) => Account(
        id: json['id'],
        name: json['name'],
        kind: json['kind'],
        balance: json['balance'].toDouble(),
        pctCash: json['pctCash'].toDouble(),
        pctBonds: json['pctBonds'].toDouble(),
        pctUsEq: json['pctUsEq'].toDouble(),
        pctIntlEq: json['pctIntlEq'].toDouble(),
        pctRealEstate: json['pctRealEstate'].toDouble(),
        pctAlt: json['pctAlt'].toDouble(),
        employerStockPct: json['employerStockPct']?.toDouble() ?? 0.0,
        updatedAt: DateTime.parse(json['updatedAt']),
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
      };

  static Liability _liabilityFromJson(Map<String, dynamic> json) => Liability(
        id: json['id'],
        name: json['name'],
        kind: json['kind'],
        balance: json['balance'].toDouble(),
        apr: json['apr'].toDouble(),
        minPayment: json['minPayment'].toDouble(),
        creditLimit: json['creditLimit']?.toDouble(),
        nextPaymentDate: json['nextPaymentDate'] != null
            ? DateTime.parse(json['nextPaymentDate'])
            : null,
        paymentFrequencyDays: json['paymentFrequencyDays'],
        dayOfMonth: json['dayOfMonth'],
        updatedAt: DateTime.parse(json['updatedAt']),
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
      };

  static Settings _settingsFromJson(Map<String, dynamic> json) => Settings(
        riskBand: RiskBand.values.firstWhere((e) => e.name == json['riskBand']),
        monthlyEssentials: json['monthlyEssentials'].toDouble(),
        driftThresholdPct: json['driftThresholdPct']?.toDouble() ?? 0.05,
        notificationsEnabled: json['notificationsEnabled'] ?? true,
        usEquityTargetPct: json['usEquityTargetPct']?.toDouble() ?? 0.8,
        isPro: json['isPro'] ?? false,
        biometricLockEnabled: json['biometricLockEnabled'] ?? false,
        darkModeEnabled: json['darkModeEnabled'] ?? false,
        colorTheme: ColorTheme.values.firstWhere(
          (e) => e.name == json['colorTheme'],
          orElse: () => ColorTheme.green,
        ),
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
        'diversificationMode': snapshot.diversificationMode,
        'liabilitiesTotal': snapshot.liabilitiesTotal,
      };

  static Snapshot _snapshotFromJson(Map<String, dynamic> json) => Snapshot(
        at: DateTime.parse(json['at']),
        netWorth: json['netWorth'].toDouble(),
        cashTotal: json['cashTotal'].toDouble(),
        bondsTotal: json['bondsTotal'].toDouble(),
        usEqTotal: json['usEqTotal'].toDouble(),
        intlEqTotal: json['intlEqTotal'].toDouble(),
        reTotal: json['reTotal'].toDouble(),
        altTotal: json['altTotal'].toDouble(),
        liabilitiesTotal: json['liabilitiesTotal'].toDouble(),
        diversificationMode: json['diversificationMode'] as String?,
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
        id: json['id'],
        type: json['type'],
        title: json['title'],
        description: json['description'],
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'])
            : null,
        hiddenUntil: json['hiddenUntil'] != null
            ? DateTime.parse(json['hiddenUntil'])
            : null,
        data: Map<String, dynamic>.from(json['data'] ?? {}),
      );
}
