import 'package:hive/hive.dart';

part 'models.g.dart';

@HiveType(typeId: 0)
enum RiskBand {
  @HiveField(0)
  conservative,
  @HiveField(1)
  balanced,
  @HiveField(2)
  growth,
}

@HiveType(typeId: 7)
enum ColorTheme {
  @HiveField(0)
  blue,
  @HiveField(1)
  green,
  @HiveField(2)
  red,
  @HiveField(3)
  purple,
  @HiveField(4)
  orange,
  @HiveField(5)
  teal,
}

@HiveType(typeId: 8)
enum NotificationSeverity {
  @HiveField(0)
  critical,
  @HiveField(1)
  high,
  @HiveField(2)
  medium,
  @HiveField(3)
  low,
  @HiveField(4)
  info,
}

@HiveType(typeId: 9)
enum NotificationType {
  @HiveField(0)
  risk,
  @HiveField(1)
  reminder,
  @HiveField(2)
  insight,
  @HiveField(3)
  system,
}

@HiveType(typeId: 10)
class AppNotification extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String title;
  @HiveField(2)
  String message;
  @HiveField(3)
  NotificationType type;
  @HiveField(4)
  NotificationSeverity severity;
  @HiveField(5)
  DateTime createdAt;
  @HiveField(6)
  bool read;
  @HiveField(7)
  bool dismissed;
  @HiveField(8)
  String? route; // Optional deep link / route
  @HiveField(9)
  Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.createdAt,
    this.read = false,
    this.dismissed = false,
    this.route,
    Map<String, dynamic>? data,
  }) : data = data ?? {};
}

@HiveType(typeId: 1)
class Account extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String
      kind; // cash, savings, brokerage, retirement, realEstateEquity, hsa, _529, crypto, other

  @HiveField(3)
  late double balance;

  @HiveField(4)
  late double pctCash;

  @HiveField(5)
  late double pctBonds;

  @HiveField(6)
  late double pctUsEq;

  @HiveField(7)
  late double pctIntlEq;

  @HiveField(8)
  late double pctRealEstate;

  @HiveField(9)
  late double pctAlt;

  @HiveField(10)
  late DateTime updatedAt;

  @HiveField(11)
  double employerStockPct;

  @HiveField(12)
  bool
      isLocked; // Can't be rebalanced (401k, pension, locked retirement accounts)

  Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.pctCash,
    required this.pctBonds,
    required this.pctUsEq,
    required this.pctIntlEq,
    required this.pctRealEstate,
    required this.pctAlt,
    required this.updatedAt,
    this.employerStockPct = 0.0,
    this.isLocked = false,
  });

  double get totalAllocation =>
      pctCash + pctBonds + pctUsEq + pctIntlEq + pctRealEstate + pctAlt;

  bool get isAllocationValid => (totalAllocation - 1.0).abs() < 0.001;

  /// Can this account be rebalanced? (opposite of isLocked)
  bool get isRebalanceable => !isLocked;

  /// Should this account default to locked based on type?
  static bool isLockedByDefault(String accountKind) {
    return accountKind == 'retirement' ||
        accountKind == 'hsa' ||
        accountKind == '_529';
  }

  Map<String, double> get allocationBreakdown => {
        'cash': balance * pctCash,
        'bonds': balance * pctBonds,
        'usEq': balance * pctUsEq,
        'intlEq': balance * pctIntlEq,
        'realEstate': balance * pctRealEstate,
        'alt': balance * pctAlt,
      };

  // Default allocations by account type
  static Map<String, Map<String, double>> get defaultAllocations => {
        'cash': {
          'cash': 1.0,
          'bonds': 0.0,
          'usEq': 0.0,
          'intlEq': 0.0,
          'realEstate': 0.0,
          'alt': 0.0,
        },
        'savings': {
          'cash': 1.0,
          'bonds': 0.0,
          'usEq': 0.0,
          'intlEq': 0.0,
          'realEstate': 0.0,
          'alt': 0.0,
        },
        'brokerage': {
          'cash': 0.05,
          'bonds': 0.25,
          'usEq': 0.55,
          'intlEq': 0.15,
          'realEstate': 0.0,
          'alt': 0.0,
        },
        'retirement': {
          'cash': 0.05,
          'bonds': 0.30,
          'usEq': 0.50,
          'intlEq': 0.15,
          'realEstate': 0.0,
          'alt': 0.0,
        },
        'realEstateEquity': {
          'cash': 0.0,
          'bonds': 0.0,
          'usEq': 0.0,
          'intlEq': 0.0,
          'realEstate': 1.0,
          'alt': 0.0,
        },
        'hsa': {
          'cash': 0.30,
          'bonds': 0.20,
          'usEq': 0.40,
          'intlEq': 0.10,
          'realEstate': 0.0,
          'alt': 0.0,
        },
        '_529': {
          'cash': 0.10,
          'bonds': 0.30,
          'usEq': 0.50,
          'intlEq': 0.10,
          'realEstate': 0.0,
          'alt': 0.0,
        },
        'crypto': {
          'cash': 0.0,
          'bonds': 0.0,
          'usEq': 0.0,
          'intlEq': 0.0,
          'realEstate': 0.0,
          'alt': 1.0,
        },
        'other': {
          'cash': 0.50,
          'bonds': 0.20,
          'usEq': 0.20,
          'intlEq': 0.10,
          'realEstate': 0.0,
          'alt': 0.0,
        },
      };
}

@HiveType(typeId: 2)
class Liability extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String kind; // mortgage, creditCard, studentLoan, personalLoan, other

  @HiveField(3)
  late double balance;

  @HiveField(4)
  late double apr;

  @HiveField(5)
  late double minPayment;

  @HiveField(6)
  late DateTime updatedAt;

  @HiveField(7)
  double? creditLimit; // For credit cards

  @HiveField(8)
  DateTime? nextPaymentDate; // When next payment is due

  @HiveField(9)
  int?
      paymentFrequencyDays; // How often payments are due (e.g., 30 for monthly)

  @HiveField(10)
  int? dayOfMonth; // For monthly payments, which day (e.g., 15th)

  Liability({
    required this.id,
    required this.name,
    required this.kind,
    required this.balance,
    required this.apr,
    required this.minPayment,
    required this.updatedAt,
    this.creditLimit,
    this.nextPaymentDate,
    this.paymentFrequencyDays,
    this.dayOfMonth,
  });

  double get creditUtilization =>
      creditLimit != null && creditLimit! > 0 ? balance / creditLimit! : 0.0;

  bool get isRevolvingDebt => kind == 'creditCard';
  bool get isHighApr => apr > 0.20; // 20% threshold

  // Due date utilities
  int? get daysUntilDue {
    if (nextPaymentDate == null) return null;
    final now = DateTime.now();
    final dueDate = DateTime(
      nextPaymentDate!.year,
      nextPaymentDate!.month,
      nextPaymentDate!.day,
    );
    final todayDate = DateTime(now.year, now.month, now.day);
    return dueDate.difference(todayDate).inDays;
  }

  bool get isDueSoon {
    final days = daysUntilDue;
    return days != null && days >= 0 && days <= 7; // Due within 7 days
  }

  bool get isOverdue {
    final days = daysUntilDue;
    return days != null && days < 0;
  }

  bool get hasDueDate => nextPaymentDate != null;

  String get dueDateStatus {
    final days = daysUntilDue;
    if (days == null) return 'No due date';
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days <= 7) return 'Due soon';
    return 'Upcoming';
  }

  // Calculate next payment date based on frequency
  DateTime? calculateNextPaymentDate() {
    if (nextPaymentDate == null || paymentFrequencyDays == null) return null;

    final now = DateTime.now();
    var nextDate = nextPaymentDate!;

    // If the current due date has passed, calculate the next one
    while (nextDate.isBefore(now)) {
      nextDate = nextDate.add(Duration(days: paymentFrequencyDays!));
    }

    return nextDate;
  }

  // Update the next payment date after a payment
  void updateNextPaymentDate() {
    if (paymentFrequencyDays != null && nextPaymentDate != null) {
      nextPaymentDate =
          nextPaymentDate!.add(Duration(days: paymentFrequencyDays!));
    }
  }
}

@HiveType(typeId: 3)
class Settings extends HiveObject {
  @HiveField(0)
  late RiskBand riskBand;

  @HiveField(1)
  late double monthlyEssentials;

  @HiveField(2)
  double driftThresholdPct;

  @HiveField(3)
  bool notificationsEnabled;

  @HiveField(4)
  double usEquityTargetPct; // Default 0.8 (80% US, 20% Intl)

  @HiveField(5)
  bool isPro;

  @HiveField(6)
  bool biometricLockEnabled;

  @HiveField(7)
  bool darkModeEnabled;

  @HiveField(8)
  ColorTheme colorTheme;

  @HiveField(9)
  double liquidityBondHaircut;

  @HiveField(10)
  double bucketCap;

  @HiveField(11)
  double employerStockThreshold;

  @HiveField(12)
  double? monthlyIncome;

  @HiveField(13)
  double incomeMultiplierFallback;

  @HiveField(14)
  int? schemaVersion; // Track schema version for migrations

  @HiveField(15)
  DateTime?
      concentrationRiskSnoozedUntil; // When concentration risk alert is snoozed until

  @HiveField(16)
  double?
      concentrationRiskResolvedAt; // The concentration % when user marked as resolved

  // --- New fields for global diversification control ---
  @HiveField(17)
  String
      homeCountry; // e.g. 'US', 'CA' — used to classify international holdings

  @HiveField(18)
  String globalDiversificationMode; // 'standard' | 'light' | 'off'

  @HiveField(19)
  double? intlTargetOverride; // Optional override for intl target (0.0..1.0)

  @HiveField(20)
  double intlTolerancePct; // e.g., 0.05

  @HiveField(21)
  double intlFloorPct; // score floor e.g., 60.0

  @HiveField(22)
  double intlPenaltyScale; // penalty scale (e.g., 60.0)

  Settings({
    required this.riskBand,
    required this.monthlyEssentials,
    this.driftThresholdPct = 0.05, // 5%
    this.notificationsEnabled = true,
    this.usEquityTargetPct = 0.8,
    this.isPro = false,
    this.biometricLockEnabled = false,
    this.darkModeEnabled = false,
    this.colorTheme = ColorTheme.green, // Default to green (current)
    this.liquidityBondHaircut = 0.5, // 50% haircut on bonds for liquidity
    this.bucketCap = 0.20, // 20% cap per asset class
    this.employerStockThreshold = 0.10, // 10% employer stock threshold
    this.monthlyIncome, // Optional explicit monthly income
    this.incomeMultiplierFallback = 3.0, // Fallback multiplier for essentials
    this.schemaVersion, // Track schema version
    this.concentrationRiskSnoozedUntil, // Alert snooze timestamp
    this.concentrationRiskResolvedAt, // Concentration % when marked resolved
    this.homeCountry = 'US',
    this.globalDiversificationMode = 'standard',
    this.intlTargetOverride,
    this.intlTolerancePct = 0.05,
    this.intlFloorPct = 60.0,
    this.intlPenaltyScale = 60.0,
  });

  // Target bond allocation based on risk band
  double get targetBondPct {
    switch (riskBand) {
      case RiskBand.conservative:
        return 0.60; // 40/60 stocks/bonds
      case RiskBand.balanced:
        return 0.40; // 60/40 stocks/bonds
      case RiskBand.growth:
        return 0.20; // 80/20 stocks/bonds
    }
  }

  double get targetStockPct => 1.0 - targetBondPct;
}

@HiveType(typeId: 4)
class Snapshot extends HiveObject {
  @HiveField(0)
  late DateTime at;

  @HiveField(1)
  late double netWorth;

  @HiveField(2)
  late double cashTotal;

  @HiveField(3)
  late double bondsTotal;

  @HiveField(4)
  late double usEqTotal;

  @HiveField(5)
  late double intlEqTotal;

  @HiveField(6)
  late double reTotal;

  @HiveField(7)
  late double altTotal;

  @HiveField(8)
  late double liabilitiesTotal;

  @HiveField(9)
  String? note;

  @HiveField(10)
  late String source; // "auto" or "manual"

  @HiveField(11)
  String? diversificationMode; // Recorded mode at snapshot time for reproducibility

  Snapshot({
    required this.at,
    required this.netWorth,
    required this.cashTotal,
    required this.bondsTotal,
    required this.usEqTotal,
    required this.intlEqTotal,
    required this.reTotal,
    required this.altTotal,
    required this.liabilitiesTotal,
    this.note,
    this.source = 'auto',
    this.diversificationMode,
  });

  double get assetsTotal =>
      cashTotal + bondsTotal + usEqTotal + intlEqTotal + reTotal + altTotal;

  Map<String, double> get allocationPercentages {
    if (assetsTotal == 0) return {};
    return {
      'cash': cashTotal / assetsTotal,
      'bonds': bondsTotal / assetsTotal,
      'usEq': usEqTotal / assetsTotal,
      'intlEq': intlEqTotal / assetsTotal,
      'realEstate': reTotal / assetsTotal,
      'alt': altTotal / assetsTotal,
    };
  }
}

@HiveType(typeId: 5)
class ActionCard extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String
      type; // 'buildCushion', 'reduceConcentration', 'homeBias', 'addBonds', 'highApr'

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  @HiveField(6)
  DateTime? hiddenUntil;

  @HiveField(7)
  Map<String, dynamic> data; // Additional data like amounts, targets, etc.

  ActionCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
    this.completedAt,
    this.hiddenUntil,
    this.data = const {},
  });

  bool get isActive =>
      completedAt == null &&
      (hiddenUntil == null || DateTime.now().isAfter(hiddenUntil!));

  void markComplete() {
    completedAt = DateTime.now();
  }

  void hideFor30Days() {
    hiddenUntil = DateTime.now().add(const Duration(days: 30));
  }
}

@HiveType(typeId: 6)
class Payment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String liabilityId;

  @HiveField(2)
  double amount;

  @HiveField(3)
  DateTime paidDate;

  @HiveField(4)
  String paymentType; // 'minimum', 'full', 'custom', 'extra'

  @HiveField(5)
  String? notes;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  double? previousBalance;

  @HiveField(8)
  double? newBalance;

  Payment({
    required this.id,
    required this.liabilityId,
    required this.amount,
    required this.paidDate,
    required this.paymentType,
    this.notes,
    required this.createdAt,
    this.previousBalance,
    this.newBalance,
  });

  factory Payment.create({
    required String liabilityId,
    required double amount,
    required String paymentType,
    String? notes,
    DateTime? paidDate,
    double? previousBalance,
    double? newBalance,
  }) {
    return Payment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      liabilityId: liabilityId,
      amount: amount,
      paidDate: paidDate ?? DateTime.now(),
      paymentType: paymentType,
      notes: notes,
      createdAt: DateTime.now(),
      previousBalance: previousBalance,
      newBalance: newBalance,
    );
  }

  // Convenience getters
  bool get isMinimumPayment => paymentType == 'minimum';
  bool get isFullPayment => paymentType == 'full';
  bool get isCustomPayment => paymentType == 'custom';
  bool get isExtraPayment => paymentType == 'extra';

  // Helper method to get payment description
  String get paymentDescription {
    switch (paymentType) {
      case 'minimum':
        return 'Minimum Payment';
      case 'full':
        return 'Full Balance';
      case 'custom':
        return 'Custom Amount';
      case 'extra':
        return 'Extra Payment';
      default:
        return 'Payment';
    }
  }

  // Helper method to format payment amount
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  String toString() {
    return 'Payment(id: $id, liabilityId: $liabilityId, amount: $amount, '
        'paymentType: $paymentType, paidDate: $paidDate)';
  }
}
