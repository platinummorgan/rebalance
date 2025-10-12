import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/financial_health.dart';
// import 'package:rebalance/data/calculators/allocation.dart';
import 'package:rebalance/data/calculators/liquidity.dart';
import 'package:rebalance/data/calculators/concentration.dart';
import 'package:rebalance/data/calculators/homebias.dart';
import 'package:rebalance/data/calculators/fixedincome.dart';
import 'package:rebalance/data/calculators/debtload.dart';

void main() {
  test('reproduce user old vs new', () {
    // Assumptions documented here:
    // - Account allocations: checking = cash; brokerage = default brokerage; 401k = default retirement
    // - Student loan minPayment = 1% of balance
    // - Credit card minPayment = max(2% of balance, 25)
    // - monthlyEssentials = 3000, riskBand = growth

    final accounts = <Account>[];

    accounts.add(
      Account(
        id: 'a1',
        name: 'Synnovus',
        kind: 'cash',
        balance: 682.96,
        pctCash: 1.0,
        pctBonds: 0.0,
        pctUsEq: 0.0,
        pctIntlEq: 0.0,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    accounts.add(
      Account(
        id: 'a2',
        name: 'Robinhood',
        kind: 'brokerage',
        balance: 1966.00,
        pctCash: 0.05,
        pctBonds: 0.25,
        pctUsEq: 0.55,
        pctIntlEq: 0.15,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
      ),
    );

    accounts.add(
      Account(
        id: 'a3',
        name: 'Fidelity',
        kind: 'retirement',
        balance: 388442.00,
        pctCash: 0.05,
        pctBonds: 0.30,
        pctUsEq: 0.50,
        pctIntlEq: 0.15,
        pctRealEstate: 0.0,
        pctAlt: 0.0,
        updatedAt: DateTime.now(),
        isLocked: true,
      ),
    );

    // Build liabilities from user's list
    final liabilities = <Liability>[];
    void addStudent(String id, double balance, double apr) {
      final minPay = balance * 0.01; // 1% min
      liabilities.add(
        Liability(
          id: id,
          name: id,
          kind: 'studentLoan',
          balance: balance,
          apr: apr,
          minPayment: minPay,
          updatedAt: DateTime.now(),
        ),
      );
    }

    addStudent('Aidadvantage1', 861.41, 0.0375);
    addStudent('Aidadvantage2', 1631.25, 0.0375);
    addStudent('Aidadvantage3', 3468.36, 0.0445);
    addStudent('Aidadvantage4', 6553.16, 0.0445);
    addStudent('Aidadvantage5', 990.94, 0.0445);
    addStudent('Aidadvantage6', 4484.69, 0.0505);
    addStudent('Aidadvantage7', 5562.26, 0.0505);
    addStudent('Aidadvantage8', 5454.47, 0.0453);
    addStudent('Aidadvantage9', 6529.51, 0.0453);
    addStudent('Aidadvantage10', 5363.36, 0.0275);
    addStudent('Aidadvantage11', 6323.88, 0.0275);

    const ccBalance = 4776.96;
    const ccLimit = 6000.0;
    final ccMin = (ccBalance * 0.02).clamp(25.0, double.infinity);
    liabilities.add(
      Liability(
        id: 'missionlane',
        name: 'Mission Lane',
        kind: 'creditCard',
        balance: ccBalance,
        apr: 0.3124,
        minPayment: ccMin,
        updatedAt: DateTime.now(),
        creditLimit: ccLimit,
      ),
    );

    final settings = Settings(
      riskBand: RiskBand.growth,
      monthlyEssentials: 3000,
      globalDiversificationMode: 'standard',
    );

    // New model (contribution)
    final newRes = FinancialHealthCalculator.calculateOverallHealth(
      accounts,
      liabilities,
      settings,
    );

    // Legacy weighted-average calculation (re-implemented here for comparison)
    // Component scores (continuous) from individual calculators
    final liquidityResult = LiquidityCalculator.calculateLiquidity(
      accounts,
      settings.monthlyEssentials,
      settings,
    );
    final concentrationResult =
        ConcentrationCalculator.calculateConcentration(accounts, settings);
    final homeBiasResult =
        HomeBiasCalculator.calculateHomeBias(accounts, settings);
    final fixedIncomeResult =
        FixedIncomeCalculator.calculateFixedIncomeAllocation(
      accounts,
      settings,
    );
    final debtLoadResult = DebtLoadCalculator.calculateDebtLoad(
      accounts,
      liabilities,
      settings.monthlyEssentials,
      settings,
    );

    final double liqScore = liquidityResult.score;
    final double concScore = concentrationResult.score;
    final double homeScore = homeBiasResult.score;
    final double fixedScore = fixedIncomeResult.score;
    final double debtScore = debtLoadResult.score;

    final weights = {
      'Debt Load': 0.30,
      'Concentration': 0.25,
      'Liquidity': 0.20,
      'Fixed Income': 0.15,
      'Home Bias': 0.10,
    };

    final bool homeMuted =
        settings.globalDiversificationMode.toLowerCase() == 'off';
    double weightedSum = 0.0;
    double weightTotal = 0.0;

    final compMap = {
      'Debt Load': debtScore,
      'Concentration': concScore,
      'Liquidity': liqScore,
      'Fixed Income': fixedScore,
      'Home Bias': homeScore,
    };

    if (homeMuted) {
      // exclude home bias and renormalize remaining weights
      final remWeights = Map<String, double>.from(weights)..remove('Home Bias');
      final base = remWeights.values.reduce((a, b) => a + b);
      final renorm = remWeights.map((k, v) => MapEntry(k, v / base));
      renorm.forEach((k, v) {
        weightTotal += v;
        weightedSum += (compMap[k]! * v);
      });
    } else {
      weights.forEach((k, v) {
        weightTotal += v;
        weightedSum += (compMap[k]! * v);
      });
    }

    final legacyScore =
        (weightedSum / (weightTotal == 0 ? 1 : weightTotal)).round();

    // Basic sanity checks: both scores are integers and not wildly different
    expect(newRes.score, isA<int>());
    expect(legacyScore, isA<int>());
    // Allow some delta between legacy and new model during transition
    expect((newRes.score - legacyScore).abs(), lessThanOrEqualTo(15));
  });
}
