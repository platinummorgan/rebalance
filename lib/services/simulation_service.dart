import '../data/models.dart';
import '../data/calculators/financial_health.dart';

/// Lightweight scenario simulation utilities.
/// Allows hypothetical changes (e.g., extra debt payment) without mutating persistence.
class SimulationService {
  /// Simulate paying down a specific liability by [extraPayment] amount.
  static FinancialHealthResult simulateExtraDebtPayment({
    required List<Account> accounts,
    required List<Liability> liabilities,
    required Settings settings,
    required String liabilityId,
    required double extraPayment,
  }) {
    final clonedLiabilities = liabilities
        .map(
          (l) => Liability(
            id: l.id,
            name: l.name,
            kind: l.kind,
            balance: l.id == liabilityId
                ? (l.balance - extraPayment).clamp(0, double.infinity)
                : l.balance,
            apr: l.apr,
            minPayment: l.minPayment,
            updatedAt: l.updatedAt,
            creditLimit: l.creditLimit,
            nextPaymentDate: l.nextPaymentDate,
            paymentFrequencyDays: l.paymentFrequencyDays,
            dayOfMonth: l.dayOfMonth,
          ),
        )
        .toList();

    return FinancialHealthCalculator.calculateOverallHealth(
      accounts,
      clonedLiabilities,
      settings,
    );
  }

  /// Simulate rebalancing by shifting cash to debt payment & updating allocation.
  static FinancialHealthResult simulateDebtPaymentFromCash({
    required List<Account> accounts,
    required List<Liability> liabilities,
    required Settings settings,
    required String liabilityId,
    required double paymentFromCash,
  }) {
    final clonedAccounts = accounts
        .map(
          (a) => Account(
            id: a.id,
            name: a.name,
            kind: a.kind,
            balance: a.id == accounts.first.id
                ? (a.balance - paymentFromCash).clamp(0, double.infinity)
                : a.balance,
            pctCash: a.pctCash,
            pctBonds: a.pctBonds,
            pctUsEq: a.pctUsEq,
            pctIntlEq: a.pctIntlEq,
            pctRealEstate: a.pctRealEstate,
            pctAlt: a.pctAlt,
            updatedAt: a.updatedAt,
            employerStockPct: a.employerStockPct,
          ),
        )
        .toList();
    return simulateExtraDebtPayment(
      accounts: clonedAccounts,
      liabilities: liabilities,
      settings: settings,
      liabilityId: liabilityId,
      extraPayment: paymentFromCash,
    );
  }
}
