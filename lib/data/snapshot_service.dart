import 'models.dart';
import 'repositories.dart';

class SnapshotService {
  static Future<Snapshot> createCurrentSnapshot({
    String source = 'auto',
    String? diversificationMode,
  }) async {
    final accounts = await RepositoryService.getAccounts();
    final liabilities = await RepositoryService.getLiabilities();

    // Calculate totals by allocation bucket
    double cashTotal = 0.0;
    double bondsTotal = 0.0;
    double usEqTotal = 0.0;
    double intlEqTotal = 0.0;
    double reTotal = 0.0;
    double altTotal = 0.0;

    for (final account in accounts) {
      final allocation = account.allocationBreakdown;
      cashTotal += (allocation['cash'] as num).toDouble();
      bondsTotal += (allocation['bonds'] as num).toDouble();
      usEqTotal += (allocation['usEq'] as num).toDouble();
      intlEqTotal += (allocation['intlEq'] as num).toDouble();
      reTotal += (allocation['realEstate'] as num).toDouble();
      altTotal += (allocation['alt'] as num).toDouble();
    }

    // Calculate total liabilities
    double liabilitiesTotal = 0.0;
    for (final liability in liabilities) {
      liabilitiesTotal += liability.balance;
    }

    final assetsTotal =
        cashTotal + bondsTotal + usEqTotal + intlEqTotal + reTotal + altTotal;
    final netWorth = assetsTotal - liabilitiesTotal;

    // If not explicitly provided, read current settings to record mode
    String? modeToRecord = diversificationMode;
    if (modeToRecord == null) {
      try {
        final settings = await RepositoryService.getSettings();
        modeToRecord = settings.globalDiversificationMode;
      } catch (_) {
        modeToRecord = null;
      }
    }

    return Snapshot(
      at: DateTime.now(),
      netWorth: netWorth,
      cashTotal: cashTotal,
      bondsTotal: bondsTotal,
      usEqTotal: usEqTotal,
      intlEqTotal: intlEqTotal,
      reTotal: reTotal,
      altTotal: altTotal,
      liabilitiesTotal: liabilitiesTotal,
      source: source,
      diversificationMode: modeToRecord,
    );
  }

  static Future<void> saveCurrentSnapshot({String source = 'auto'}) async {
    final snapshot = await createCurrentSnapshot(source: source);
    await RepositoryService.saveSnapshot(snapshot);
  }

  /// Creates and saves a manual snapshot, shows success toast
  static Future<Snapshot> createManualSnapshot() async {
    final snapshot = await createCurrentSnapshot(source: 'manual');
    await RepositoryService.saveSnapshot(snapshot);
    return snapshot;
  }

  static Future<List<Snapshot>> getRecentSnapshots({int days = 90}) async {
    final allSnapshots = await RepositoryService.getSnapshots();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return allSnapshots
        .where((snapshot) => snapshot.at.isAfter(cutoffDate))
        .toList();
  }

  static Future<Snapshot?> getLatestSnapshot() async {
    final snapshots = await RepositoryService.getSnapshots();
    if (snapshots.isEmpty) return null;

    snapshots.sort((a, b) => b.at.compareTo(a.at));
    return snapshots.first;
  }

  static Future<double?> getNetWorthTrend({int days = 30}) async {
    final snapshots = await RepositoryService.getSnapshots();
    if (snapshots.length < 2) return null;

    snapshots.sort((a, b) => a.at.compareTo(b.at));

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final recentSnapshots =
        snapshots.where((snapshot) => snapshot.at.isAfter(cutoffDate)).toList();

    if (recentSnapshots.length < 2) return null;

    final oldest = recentSnapshots.first;
    final newest = recentSnapshots.last;

    if (oldest.netWorth == 0) return null;

    return (newest.netWorth - oldest.netWorth) / oldest.netWorth;
  }

  // Generate sample data for demo purposes
  static Future<void> loadSampleData() async {
    // Clear existing data
    await RepositoryService.clearAllData();

    // Sample settings
    final settings = Settings(
      riskBand: RiskBand.balanced,
      monthlyEssentials: 4500.0,
      isPro: true, // For demo purposes
    );
    await RepositoryService.saveSettings(settings);

    // Sample accounts
    final accounts = [
      Account(
        id: 'checking_001',
        name: 'Primary Checking',
        kind: 'cash',
        balance: 8500.0,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'savings_001',
        name: 'Emergency Fund',
        kind: 'savings',
        balance: 18000.0,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'brokerage_001',
        name: 'Taxable Brokerage',
        kind: 'brokerage',
        balance: 145000.0,
        pctCash: 0.05,
        pctBonds: 0.25,
        pctUsEq: 0.50,
        pctIntlEq: 0.20,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        employerStockPct: 0.15, // 15% employer stock concentration
        updatedAt: DateTime.now(),
      ),
      Account(
        id: '401k_001',
        name: '401k Retirement',
        kind: 'retirement',
        balance: 285000.0,
        pctCash: 0.02,
        pctBonds: 0.30,
        pctUsEq: 0.53,
        pctIntlEq: 0.15,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 'house_001',
        name: 'Primary Residence',
        kind: 'realEstateEquity',
        balance: 180000.0, // Equity portion only
        pctCash: 0.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 1.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    ];

    for (final account in accounts) {
      await RepositoryService.saveAccount(account);
    }

    // Sample liabilities with realistic due dates
    final today = DateTime.now();
    final liabilities = [
      Liability(
        id: 'mortgage_001',
        name: 'Primary Mortgage',
        kind: 'mortgage',
        balance: 320000.0,
        apr: 0.065, // 6.5%
        minPayment: 2100.0,
        nextPaymentDate: DateTime(today.year, today.month, 1)
            .add(const Duration(days: 32)), // 1st of next month
        paymentFrequencyDays: 30,
        dayOfMonth: 1,
        updatedAt: DateTime.now(),
      ),
      Liability(
        id: 'credit_001',
        name: 'Chase Sapphire',
        kind: 'creditCard',
        balance: 2800.0,
        apr: 0.199, // 19.9%
        minPayment: 85.0,
        creditLimit: 15000.0,
        nextPaymentDate: today.add(const Duration(days: 6)), // Due in 6 days
        paymentFrequencyDays: 30,
        dayOfMonth: 20,
        updatedAt: DateTime.now(),
      ),
      Liability(
        id: 'student_001',
        name: 'Student Loans',
        kind: 'studentLoan',
        balance: 18500.0,
        apr: 0.045, // 4.5%
        minPayment: 215.0,
        nextPaymentDate: today.add(const Duration(days: 1)), // Due tomorrow
        paymentFrequencyDays: 30,
        dayOfMonth: 10,
        updatedAt: DateTime.now(),
      ),
    ];

    for (final liability in liabilities) {
      await RepositoryService.saveLiability(liability);
    }

    // Generate historical snapshots (simulate 6 months of data)
    final now = DateTime.now();
    for (int i = 180; i >= 0; i -= 7) {
      // Weekly snapshots
      final date = now.subtract(Duration(days: i));

      // Simulate some growth and volatility
      final growthFactor = 1.0 + (180 - i) * 0.0008; // ~15% annual growth
      final volatility = (i % 14 == 0) ? 0.95 : 1.0; // Occasional dips

      final snapshot = Snapshot(
        at: date,
        netWorth: (636500.0 - 341300.0) *
            growthFactor *
            volatility, // Assets - Liabilities
        cashTotal: 26500.0,
        bondsTotal: 108800.0 * growthFactor * volatility,
        usEqTotal: 223850.0 * growthFactor * volatility,
        intlEqTotal: 71750.0 * growthFactor * volatility,
        reTotal: 180000.0 * growthFactor,
        altTotal: 0.0,
        liabilitiesTotal: 341300.0 - (i * 50), // Gradually paying down debt
      );

      await RepositoryService.saveSnapshot(snapshot);
    }
  }
}
