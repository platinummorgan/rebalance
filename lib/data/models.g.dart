// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 10;

  @override
  AppNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppNotification(
      id: fields[0] as String,
      title: fields[1] as String,
      message: fields[2] as String,
      type: fields[3] as NotificationType,
      severity: fields[4] as NotificationSeverity,
      createdAt: fields[5] as DateTime,
      read: fields[6] as bool,
      dismissed: fields[7] as bool,
      route: fields[8] as String?,
      data: (fields[9] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.severity)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.read)
      ..writeByte(7)
      ..write(obj.dismissed)
      ..writeByte(8)
      ..write(obj.route)
      ..writeByte(9)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 1;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      name: fields[1] as String,
      kind: fields[2] as String,
      balance: fields[3] as double,
      pctCash: fields[4] as double,
      pctBonds: fields[5] as double,
      pctUsEq: fields[6] as double,
      pctIntlEq: fields[7] as double,
      pctRealEstate: fields[8] as double,
      pctAlt: fields[9] as double,
      updatedAt: fields[10] as DateTime,
      employerStockPct: fields[11] as double,
      isLocked: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.pctCash)
      ..writeByte(5)
      ..write(obj.pctBonds)
      ..writeByte(6)
      ..write(obj.pctUsEq)
      ..writeByte(7)
      ..write(obj.pctIntlEq)
      ..writeByte(8)
      ..write(obj.pctRealEstate)
      ..writeByte(9)
      ..write(obj.pctAlt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.employerStockPct)
      ..writeByte(12)
      ..write(obj.isLocked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LiabilityAdapter extends TypeAdapter<Liability> {
  @override
  final int typeId = 2;

  @override
  Liability read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Liability(
      id: fields[0] as String,
      name: fields[1] as String,
      kind: fields[2] as String,
      balance: fields[3] as double,
      apr: fields[4] as double,
      minPayment: fields[5] as double,
      updatedAt: fields[6] as DateTime,
      creditLimit: fields[7] as double?,
      nextPaymentDate: fields[8] as DateTime?,
      paymentFrequencyDays: fields[9] as int?,
      dayOfMonth: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Liability obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.kind)
      ..writeByte(3)
      ..write(obj.balance)
      ..writeByte(4)
      ..write(obj.apr)
      ..writeByte(5)
      ..write(obj.minPayment)
      ..writeByte(6)
      ..write(obj.updatedAt)
      ..writeByte(7)
      ..write(obj.creditLimit)
      ..writeByte(8)
      ..write(obj.nextPaymentDate)
      ..writeByte(9)
      ..write(obj.paymentFrequencyDays)
      ..writeByte(10)
      ..write(obj.dayOfMonth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiabilityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 3;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      riskBand: fields[0] as RiskBand,
      monthlyEssentials: fields[1] as double,
      driftThresholdPct: fields[2] as double,
      notificationsEnabled: fields[3] as bool,
      usEquityTargetPct: fields[4] as double,
      isPro: fields[5] as bool,
      biometricLockEnabled: fields[6] as bool,
      darkModeEnabled: fields[7] as bool,
      colorTheme: fields[8] as ColorTheme,
      liquidityBondHaircut: fields[9] as double,
      bucketCap: fields[10] as double,
      employerStockThreshold: fields[11] as double,
      monthlyIncome: fields[12] as double?,
      incomeMultiplierFallback: fields[13] as double,
      schemaVersion: fields[14] as int?,
      concentrationRiskSnoozedUntil: fields[15] as DateTime?,
      concentrationRiskResolvedAt: fields[16] as double?,
      homeCountry: fields[17] as String,
      globalDiversificationMode: fields[18] as String,
      intlTargetOverride: fields[19] as double?,
      intlTolerancePct: fields[20] as double,
      intlFloorPct: fields[21] as double,
      intlPenaltyScale: fields[22] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.riskBand)
      ..writeByte(1)
      ..write(obj.monthlyEssentials)
      ..writeByte(2)
      ..write(obj.driftThresholdPct)
      ..writeByte(3)
      ..write(obj.notificationsEnabled)
      ..writeByte(4)
      ..write(obj.usEquityTargetPct)
      ..writeByte(5)
      ..write(obj.isPro)
      ..writeByte(6)
      ..write(obj.biometricLockEnabled)
      ..writeByte(7)
      ..write(obj.darkModeEnabled)
      ..writeByte(8)
      ..write(obj.colorTheme)
      ..writeByte(9)
      ..write(obj.liquidityBondHaircut)
      ..writeByte(10)
      ..write(obj.bucketCap)
      ..writeByte(11)
      ..write(obj.employerStockThreshold)
      ..writeByte(12)
      ..write(obj.monthlyIncome)
      ..writeByte(13)
      ..write(obj.incomeMultiplierFallback)
      ..writeByte(14)
      ..write(obj.schemaVersion)
      ..writeByte(15)
      ..write(obj.concentrationRiskSnoozedUntil)
      ..writeByte(16)
      ..write(obj.concentrationRiskResolvedAt)
      ..writeByte(17)
      ..write(obj.homeCountry)
      ..writeByte(18)
      ..write(obj.globalDiversificationMode)
      ..writeByte(19)
      ..write(obj.intlTargetOverride)
      ..writeByte(20)
      ..write(obj.intlTolerancePct)
      ..writeByte(21)
      ..write(obj.intlFloorPct)
      ..writeByte(22)
      ..write(obj.intlPenaltyScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SnapshotAdapter extends TypeAdapter<Snapshot> {
  @override
  final int typeId = 4;

  @override
  Snapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Snapshot(
      at: fields[0] as DateTime,
      netWorth: fields[1] as double,
      cashTotal: fields[2] as double,
      bondsTotal: fields[3] as double,
      usEqTotal: fields[4] as double,
      intlEqTotal: fields[5] as double,
      reTotal: fields[6] as double,
      altTotal: fields[7] as double,
      liabilitiesTotal: fields[8] as double,
      note: fields[9] as String?,
      source: fields[10] as String,
      diversificationMode: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Snapshot obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.at)
      ..writeByte(1)
      ..write(obj.netWorth)
      ..writeByte(2)
      ..write(obj.cashTotal)
      ..writeByte(3)
      ..write(obj.bondsTotal)
      ..writeByte(4)
      ..write(obj.usEqTotal)
      ..writeByte(5)
      ..write(obj.intlEqTotal)
      ..writeByte(6)
      ..write(obj.reTotal)
      ..writeByte(7)
      ..write(obj.altTotal)
      ..writeByte(8)
      ..write(obj.liabilitiesTotal)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.source)
      ..writeByte(11)
      ..write(obj.diversificationMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActionCardAdapter extends TypeAdapter<ActionCard> {
  @override
  final int typeId = 5;

  @override
  ActionCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActionCard(
      id: fields[0] as String,
      type: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      createdAt: fields[4] as DateTime,
      completedAt: fields[5] as DateTime?,
      hiddenUntil: fields[6] as DateTime?,
      data: (fields[7] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ActionCard obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.hiddenUntil)
      ..writeByte(7)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 6;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      id: fields[0] as String,
      liabilityId: fields[1] as String,
      amount: fields[2] as double,
      paidDate: fields[3] as DateTime,
      paymentType: fields[4] as String,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      previousBalance: fields[7] as double?,
      newBalance: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.liabilityId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.paidDate)
      ..writeByte(4)
      ..write(obj.paymentType)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.previousBalance)
      ..writeByte(8)
      ..write(obj.newBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RiskBandAdapter extends TypeAdapter<RiskBand> {
  @override
  final int typeId = 0;

  @override
  RiskBand read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RiskBand.conservative;
      case 1:
        return RiskBand.balanced;
      case 2:
        return RiskBand.growth;
      default:
        return RiskBand.conservative;
    }
  }

  @override
  void write(BinaryWriter writer, RiskBand obj) {
    switch (obj) {
      case RiskBand.conservative:
        writer.writeByte(0);
        break;
      case RiskBand.balanced:
        writer.writeByte(1);
        break;
      case RiskBand.growth:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskBandAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ColorThemeAdapter extends TypeAdapter<ColorTheme> {
  @override
  final int typeId = 7;

  @override
  ColorTheme read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ColorTheme.blue;
      case 1:
        return ColorTheme.green;
      case 2:
        return ColorTheme.red;
      case 3:
        return ColorTheme.purple;
      case 4:
        return ColorTheme.orange;
      case 5:
        return ColorTheme.teal;
      default:
        return ColorTheme.blue;
    }
  }

  @override
  void write(BinaryWriter writer, ColorTheme obj) {
    switch (obj) {
      case ColorTheme.blue:
        writer.writeByte(0);
        break;
      case ColorTheme.green:
        writer.writeByte(1);
        break;
      case ColorTheme.red:
        writer.writeByte(2);
        break;
      case ColorTheme.purple:
        writer.writeByte(3);
        break;
      case ColorTheme.orange:
        writer.writeByte(4);
        break;
      case ColorTheme.teal:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationSeverityAdapter extends TypeAdapter<NotificationSeverity> {
  @override
  final int typeId = 8;

  @override
  NotificationSeverity read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationSeverity.critical;
      case 1:
        return NotificationSeverity.high;
      case 2:
        return NotificationSeverity.medium;
      case 3:
        return NotificationSeverity.low;
      case 4:
        return NotificationSeverity.info;
      default:
        return NotificationSeverity.critical;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationSeverity obj) {
    switch (obj) {
      case NotificationSeverity.critical:
        writer.writeByte(0);
        break;
      case NotificationSeverity.high:
        writer.writeByte(1);
        break;
      case NotificationSeverity.medium:
        writer.writeByte(2);
        break;
      case NotificationSeverity.low:
        writer.writeByte(3);
        break;
      case NotificationSeverity.info:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSeverityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = 9;

  @override
  NotificationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationType.risk;
      case 1:
        return NotificationType.reminder;
      case 2:
        return NotificationType.insight;
      case 3:
        return NotificationType.system;
      default:
        return NotificationType.risk;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    switch (obj) {
      case NotificationType.risk:
        writer.writeByte(0);
        break;
      case NotificationType.reminder:
        writer.writeByte(1);
        break;
      case NotificationType.insight:
        writer.writeByte(2);
        break;
      case NotificationType.system:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
