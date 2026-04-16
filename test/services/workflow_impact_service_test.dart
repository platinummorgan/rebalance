import 'package:flutter_test/flutter_test.dart';
import 'package:rebalance/data/models.dart';
import 'package:rebalance/services/workflow_impact_service.dart';

void main() {
  group('WorkflowImpactService', () {
    test('buildMetricsSnapshot computes core portfolio and cashflow metrics',
        () {
      final snapshot = WorkflowImpactService.buildMetricsSnapshot(
        accounts: [
          Account(
            id: 'cash-1',
            name: 'Checking',
            kind: 'cash',
            balance: 5000,
            pctCash: 1,
            pctBonds: 0,
            pctUsEq: 0,
            pctIntlEq: 0,
            pctRealEstate: 0,
            pctAlt: 0,
            updatedAt: DateTime(2026, 4, 1),
          ),
          Account(
            id: 'sav-1',
            name: 'Emergency',
            kind: 'savings',
            balance: 3000,
            pctCash: 1,
            pctBonds: 0,
            pctUsEq: 0,
            pctIntlEq: 0,
            pctRealEstate: 0,
            pctAlt: 0,
            updatedAt: DateTime(2026, 4, 1),
          ),
          Account(
            id: 'bro-1',
            name: 'Brokerage',
            kind: 'brokerage',
            balance: 12000,
            pctCash: 0.05,
            pctBonds: 0.25,
            pctUsEq: 0.55,
            pctIntlEq: 0.15,
            pctRealEstate: 0,
            pctAlt: 0,
            updatedAt: DateTime(2026, 4, 1),
          ),
        ],
        liabilities: [
          Liability(
            id: 'cc-1',
            name: 'Credit Card',
            kind: 'creditCard',
            balance: 2000,
            apr: 0.22,
            minPayment: 75,
            updatedAt: DateTime(2026, 4, 1),
          ),
        ],
        incomes: [
          Income(
            id: 'inc-1',
            name: 'Salary',
            kind: 'salary',
            grossAmount: 6000,
            frequency: 'monthly',
            updatedAt: DateTime(2026, 4, 1),
          ),
        ],
        expenses: [
          MonthlyExpense(
            id: 'exp-1',
            name: 'Rent',
            amount: 3200,
            updatedAt: DateTime(2026, 4, 1),
          ),
        ],
        settings: Settings(
          riskBand: RiskBand.balanced,
          monthlyEssentials: 3500,
        ),
      );

      expect(snapshot[WorkflowImpactService.metricTotalAssets], 20000);
      expect(snapshot[WorkflowImpactService.metricTotalLiabilities], 2000);
      expect(snapshot[WorkflowImpactService.metricNetWorth], 18000);
      expect(snapshot[WorkflowImpactService.metricMonthlyIncome], 6000);
      expect(snapshot[WorkflowImpactService.metricMonthlyBurn], 3500);
      expect(snapshot[WorkflowImpactService.metricMonthlySurplus], 2500);
      expect(snapshot[WorkflowImpactService.metricCashBuffer], 8000);
      expect(
        snapshot[WorkflowImpactService.metricCashRunwayMonths],
        closeTo(8000 / 3500, 0.0001),
      );
    });

    test('WorkflowImpactLogEntry parses map and computes deltas', () {
      final entry = WorkflowImpactLogEntry.fromMap({
        'id': 'log-1',
        'workflowId': WorkflowImpactService.workflowDebtBlitz,
        'workflowTitle': 'Debt Blitz',
        'source': WorkflowImpactService.sourceCommandCenter,
        'startedAt': '2026-04-16T10:00:00.000Z',
        'completedAt': '2026-04-16T10:30:00.000Z',
        'baselineMetrics': {
          WorkflowImpactService.metricNetWorth: 100000,
          WorkflowImpactService.metricMonthlySurplus: 500,
        },
        'outcomeMetrics': {
          WorkflowImpactService.metricNetWorth: 105000,
          WorkflowImpactService.metricMonthlySurplus: 300,
        },
      });

      expect(entry.isCompleted, isTrue);
      expect(entry.delta(WorkflowImpactService.metricNetWorth), 5000);
      expect(entry.delta(WorkflowImpactService.metricMonthlySurplus), -200);
      expect(
        entry.toMap()['workflowId'],
        WorkflowImpactService.workflowDebtBlitz,
      );
    });
  });
}
