import '../models.dart';

class AllocationCalculator {
  static Map<String, double> calculateTotals(List<Account> accounts) {
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

    return {
      'cash': cashTotal,
      'bonds': bondsTotal,
      'usEq': usEqTotal,
      'intlEq': intlEqTotal,
      'realEstate': reTotal,
      'alt': altTotal,
    };
  }

  static Map<String, double> calculatePercentages(List<Account> accounts) {
    final totals = calculateTotals(accounts);
    final assetsTotal = totals.values.reduce((a, b) => a + b);

    if (assetsTotal == 0) {
      return {
        'cash': 0.0,
        'bonds': 0.0,
        'usEq': 0.0,
        'intlEq': 0.0,
        'realEstate': 0.0,
        'alt': 0.0,
      };
    }

    return totals.map((key, value) => MapEntry(key, value / assetsTotal));
  }

  static double calculateNetWorth(
    List<Account> accounts,
    List<Liability> liabilities,
  ) {
    final totals = calculateTotals(accounts);
    final assetsTotal = totals.values.reduce((a, b) => a + b);
    // Only include debts with positive balances
    final activeDebts = liabilities.where((debt) => debt.balance > 0).toList();
    final liabilitiesTotal =
        activeDebts.fold(0.0, (sum, liability) => sum + liability.balance);

    return assetsTotal - liabilitiesTotal;
  }

  static double calculateAssetsTotal(List<Account> accounts) {
    final totals = calculateTotals(accounts);
    return totals.values.reduce((a, b) => a + b);
  }

  static double calculateLiabilitiesTotal(List<Liability> liabilities) {
    // Only include debts with positive balances
    final activeDebts = liabilities.where((debt) => debt.balance > 0).toList();
    return activeDebts.fold(0.0, (sum, liability) => sum + liability.balance);
  }

  // Calculate investable assets (excludes cash and real estate for some calculations)
  static double calculateInvestableAssets(List<Account> accounts) {
    final totals = calculateTotals(accounts);
    return totals['bonds']! +
        totals['usEq']! +
        totals['intlEq']! +
        totals['alt']!;
  }

  // Calculate equity allocation within investable assets
  static Map<String, double> calculateEquityAllocation(List<Account> accounts) {
    final totals = calculateTotals(accounts);
    final equityTotal = totals['usEq']! + totals['intlEq']!;

    if (equityTotal == 0) {
      return {'usEq': 0.0, 'intlEq': 0.0};
    }

    return {
      'usEq': totals['usEq']! / equityTotal,
      'intlEq': totals['intlEq']! / equityTotal,
    };
  }
}
