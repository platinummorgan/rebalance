import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/data/calculators/allocation.dart';
import 'package:rebalance/data/calculators/liquidity.dart';
import 'package:rebalance/data/calculators/concentration.dart';
import 'package:rebalance/data/calculators/fixedincome.dart';
import 'package:rebalance/data/calculators/debtload.dart';
import 'package:rebalance/data/calculators/actions.dart';

void main() {
  group('Allocation Calculator', () {
    late List<Account> testAccounts;
    late Settings testSettings;

    setUp(() {
      testSettings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0,
        liquidityBondHaircut: 0.5,
        bucketCap: 0.20,
        employerStockThreshold: 0.10,
        monthlyIncome: 15000.0,
        incomeMultiplierFallback: 3.0,
      );
      testAccounts = [
        Account(
          id: 'test1',
          name: 'Test Account 1',
          kind: 'brokerage',
          balance: 100000.0,
          pctCash: 0.10,
          pctBonds: 0.30,
          pctUsEq: 0.50,
          pctIntlEq: 0.10,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          updatedAt: DateTime.now(),
        ),
        Account(
          id: 'test2',
          name: 'Test Account 2',
          kind: 'cash',
          balance: 25000.0,
          pctCash: 1.0,
          pctBonds: 0.0,
          pctUsEq: 0.0,
          pctIntlEq: 0.0,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          updatedAt: DateTime.now(),
        ),
      ];
    });

    test('calculates totals correctly', () {
      final totals = AllocationCalculator.calculateTotals(testAccounts);

      expect(totals['cash'], equals(35000.0)); // 10k + 25k
      expect(totals['bonds'], equals(30000.0)); // 30k from first account
      expect(totals['usEq'], equals(50000.0)); // 50k from first account
      expect(totals['intlEq'], equals(10000.0)); // 10k from first account
      expect(totals['realEstate'], equals(0.0));
      expect(totals['alt'], equals(0.0));
    });

    test('calculates percentages correctly', () {
      final percentages =
          AllocationCalculator.calculatePercentages(testAccounts);

      expect(percentages['cash'], closeTo(0.28, 0.01)); // 35k / 125k
      expect(percentages['bonds'], closeTo(0.24, 0.01)); // 30k / 125k
      expect(percentages['usEq'], closeTo(0.40, 0.01)); // 50k / 125k
      expect(percentages['intlEq'], closeTo(0.08, 0.01)); // 10k / 125k
    });

    test('calculates net worth correctly', () {
      final liabilities = [
        Liability(
          id: 'debt1',
          name: 'Test Debt',
          kind: 'creditCard',
          balance: 5000.0,
          apr: 0.199,
          minPayment: 100.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final netWorth =
          AllocationCalculator.calculateNetWorth(testAccounts, liabilities);
      expect(netWorth, equals(120000.0)); // 125k - 5k
    });
  });

  group('Liquidity Calculator', () {
    late List<Account> testAccounts;
    late Settings testSettings;

    setUp(() {
      testSettings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0,
        liquidityBondHaircut: 0.5,
        bucketCap: 0.20,
        employerStockThreshold: 0.10,
        monthlyIncome: 15000.0,
        incomeMultiplierFallback: 3.0,
      );
      testAccounts = [
        Account(
          id: 'cash1',
          name: 'Cash Account',
          kind: 'cash',
          balance: 15000.0,
          pctCash: 1.0,
          pctBonds: 0.0,
          pctUsEq: 0.0,
          pctIntlEq: 0.0,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          updatedAt: DateTime.now(),
        ),
      ];
    });

    test('calculates liquidity correctly', () {
      const monthlyEssentials = 5000.0;

      final result = LiquidityCalculator.calculateLiquidity(
        testAccounts,
        monthlyEssentials,
        testSettings,
      );

      expect(result.monthsOfEssentials, equals(3.0)); // 15k / 5k
      expect(result.band, equals(LiquidityBand.green));
    });

    test('handles zero monthly essentials', () {
      final result = LiquidityCalculator.calculateLiquidity(
        testAccounts,
        0.0,
        testSettings,
      );

      expect(result.monthsOfEssentials, equals(0.0));
      expect(result.band, equals(LiquidityBand.red));
    });
  });

  group('Concentration Calculator', () {
    late Settings testSettings;

    setUp(() {
      testSettings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0,
        liquidityBondHaircut: 0.5,
        bucketCap: 0.20,
        employerStockThreshold: 0.10,
        monthlyIncome: 15000.0,
        incomeMultiplierFallback: 3.0,
      );
    });

    test('identifies concentration risk', () {
      final accounts = [
        Account(
          id: 'concentrated',
          name: 'Concentrated Account',
          kind: 'brokerage',
          balance: 100000.0,
          pctCash: 0.0,
          pctBonds: 0.0,
          pctUsEq: 1.0, // 100% in US equity - concentrated!
          pctIntlEq: 0.0,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final result = ConcentrationCalculator.calculateConcentration(
        accounts,
        testSettings,
      );

      expect(result.largestBucketPct, equals(1.0));
      expect(result.largestBucket, equals('US Equity'));
      expect(result.band, equals(ConcentrationBand.red));
    });

    test('identifies employer stock risk', () {
      final accounts = [
        Account(
          id: 'employer',
          name: 'Employer Stock Account',
          kind: 'brokerage',
          balance: 100000.0,
          pctCash: 0.0,
          pctBonds: 0.0,
          pctUsEq: 1.0,
          pctIntlEq: 0.0,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          employerStockPct: 15.0, // 15% employer stock
          updatedAt: DateTime.now(),
        ),
      ];

      final result = ConcentrationCalculator.calculateConcentration(
        accounts,
        testSettings,
      );

      expect(result.hasEmployerStockRisk, isTrue);
      expect(result.band, equals(ConcentrationBand.red));
    });
  });

  group('Fixed Income Calculator', () {
    test('calculates bond allocation correctly', () {
      final accounts = [
        Account(
          id: 'balanced',
          name: 'Balanced Account',
          kind: 'brokerage',
          balance: 100000.0,
          pctCash: 0.0,
          pctBonds: 0.40,
          pctUsEq: 0.60,
          pctIntlEq: 0.0,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final settings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0,
      );

      final result = FixedIncomeCalculator.calculateFixedIncomeAllocation(
        accounts,
        settings,
      );

      expect(result.bondPct, equals(0.40));
      expect(result.targetBondPct, equals(0.40));
      expect(result.band, equals(FixedIncomeBand.green));
    });
  });

  group('Debt Load Calculator', () {
    late Settings testSettings;

    setUp(() {
      testSettings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0,
        liquidityBondHaircut: 0.5,
        bucketCap: 0.20,
        employerStockThreshold: 0.10,
        monthlyIncome: 15000.0,
        incomeMultiplierFallback: 3.0,
      );
    });

    test('calculates weighted APR correctly', () {
      final accounts = <Account>[];
      final liabilities = [
        Liability(
          id: 'card1',
          name: 'Credit Card 1',
          kind: 'creditCard',
          balance: 2000.0,
          apr: 0.199, // 19.9%
          minPayment: 50.0,
          updatedAt: DateTime.now(),
        ),
        Liability(
          id: 'mortgage1',
          name: 'Mortgage',
          kind: 'mortgage',
          balance: 200000.0,
          apr: 0.065, // 6.5%
          minPayment: 1500.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final result = DebtLoadCalculator.calculateDebtLoad(
        accounts,
        liabilities,
        5000.0,
        testSettings,
      );

      // Weighted APR should be closer to 6.5% due to mortgage size
      expect(result.weightedApr, closeTo(0.067, 0.01));
      expect(result.highAprDebts, hasLength(1)); // Credit card > 20%
    });

    test('calculates credit utilization', () {
      final accounts = <Account>[];
      final liabilities = [
        Liability(
          id: 'card1',
          name: 'Credit Card',
          kind: 'creditCard',
          balance: 3000.0,
          apr: 0.199,
          minPayment: 75.0,
          creditLimit: 10000.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final result = DebtLoadCalculator.calculateDebtLoad(
        accounts,
        liabilities,
        5000.0,
        testSettings,
      );

      expect(result.creditUtilization, equals(0.30)); // 30% utilization
    });
  });

  group('Action Card Generator', () {
    test('generates emergency fund action card', () {
      final accounts = [
        Account(
          id: 'low_cash',
          name: 'Low Cash Account',
          kind: 'cash',
          balance: 2000.0, // Only $2k cash
          pctCash: 1.0,
          pctBonds: 0.0,
          pctUsEq: 0.0,
          pctIntlEq: 0.0,
          pctRealEstate: 0.0,
          pctAlt: 0.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final settings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 5000.0, // Needs $15k emergency fund
      );

      final cards =
          ActionCardGenerator.generateActionCards(accounts, [], settings);

      expect(cards, isNotEmpty);
      expect(cards.first.type, equals('buildCushion'));
      expect(cards.first.title, contains('Emergency Cushion'));
    });

    test('generates high APR debt action card', () {
      final accounts = <Account>[];
      final liabilities = [
        Liability(
          id: 'high_apr',
          name: 'High APR Card',
          kind: 'creditCard',
          balance: 5000.0,
          apr: 0.299, // 29.9% APR!
          minPayment: 100.0,
          updatedAt: DateTime.now(),
        ),
      ];

      final settings = Settings(
        riskBand: RiskBand.balanced,
        monthlyEssentials: 3000.0,
      );

      final cards = ActionCardGenerator.generateActionCards(
        accounts,
        liabilities,
        settings,
      );

      expect(cards, isNotEmpty);
      expect(cards.first.type, equals('highApr'));
      expect(cards.first.title, contains('High-Cost Debt'));
    });
  });
}
