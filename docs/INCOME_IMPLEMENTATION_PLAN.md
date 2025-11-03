# Income Implementation Plan

## Current State Analysis

### Existing Income Fields
- **Settings.monthlyIncome** (optional): Simple single value, used as fallback
- **Settings.monthlyEssentials** (required): Used for liquidity calculations
- **Settings.incomeMultiplierFallback**: Used when monthlyIncome is null (default: 3.0x essentials)

### Current Usage
1. **Financial Health Score**: `monthlyIncome ?? (monthlyEssentials * incomeMultiplierFallback)`
2. **Debt Load Calculation**: Used for debt-to-income ratio
3. **Liquidity Calculation**: Used for months of coverage

### Limitations
- No breakdown of income sources
- No gross vs net distinction
- No tax/deduction tracking
- No multiple income streams support
- Income not treated as a first-class entity like Assets/Liabilities

---

## Proposed Implementation

### Phase 1: Income Data Model (Foundation)

#### New Model: `Income`
```dart
@HiveType(typeId: 8)
class Income extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name; // "Primary Salary", "Side Business", "Rental Income"

  @HiveField(2)
  late String kind; // salary, business, rental, investment, pension, social_security, alimony, child_support, other

  @HiveField(3)
  late double grossAmount; // Before any deductions

  @HiveField(4)
  late String frequency; // monthly, biweekly, weekly, annual, quarterly

  @HiveField(5)
  late DateTime updatedAt;

  // Tax & Deductions (optional for detailed tracking)
  @HiveField(6)
  double? federalTax;

  @HiveField(7)
  double? stateTax;

  @HiveField(8)
  double? socialSecurityTax;

  @HiveField(9)
  double? medicareTax;

  @HiveField(10)
  double? retirement401k; // Pre-tax retirement contributions

  @HiveField(11)
  double? healthInsurance;

  @HiveField(12)
  double? otherDeductions;

  // Computed
  double get totalDeductions => 
    (federalTax ?? 0) + 
    (stateTax ?? 0) + 
    (socialSecurityTax ?? 0) +
    (medicareTax ?? 0) + 
    (retirement401k ?? 0) + 
    (healthInsurance ?? 0) + 
    (otherDeductions ?? 0);

  double get netAmount => grossAmount - totalDeductions;

  // Convert to monthly for consistent calculations
  double get monthlyGross {
    switch (frequency) {
      case 'monthly': return grossAmount;
      case 'biweekly': return grossAmount * 26 / 12;
      case 'weekly': return grossAmount * 52 / 12;
      case 'annual': return grossAmount / 12;
      case 'quarterly': return grossAmount * 4 / 12;
      default: return grossAmount;
    }
  }

  double get monthlyNet => netAmount * _frequencyMultiplier;
}
```

#### Income Repository
```dart
// Similar to AccountRepository and LiabilityRepository
final incomesProvider = StreamProvider<List<Income>>((ref) {
  final repo = ref.watch(incomesRepositoryProvider);
  return repo.watchAll();
});
```

---

### Phase 2: UI Implementation

#### New Screen: `IncomeScreen`
**Location**: `lib/features/income/income_screen.dart`

**Features**:
- List all income sources
- Summary cards showing:
  - Total Monthly Gross Income
  - Total Monthly Net Income
  - Total Annual Income
  - Effective Tax Rate
- Add/Edit/Delete income sources
- Filter by income type
- Sort by amount, frequency, type

#### New Screen: `IncomeDetailScreen`
**Location**: `lib/features/income/income_detail_screen.dart`

**Features**:
- Add/Edit income source
- Input fields:
  - Name
  - Type/Category
  - Gross amount
  - Frequency
  - Tax breakdown (optional, collapsible)
  - Deductions breakdown (optional, collapsible)
- Auto-calculate net from gross and deductions
- Historical tracking (future enhancement)

#### Navigation Updates
**Update**: `lib/routes.dart`

Add new route:
```dart
static const String income = '/income';

GoRoute(
  path: income,
  name: 'income',
  builder: (context, state) => const IncomeScreen(),
  routes: [
    GoRoute(
      path: 'add',
      name: 'add-income',
      builder: (context, state) => const IncomeDetailScreen(),
    ),
    GoRoute(
      path: ':id',
      name: 'income-detail',
      builder: (context, state) {
        final incomeId = state.pathParameters['id']!;
        return IncomeDetailScreen(incomeId: incomeId);
      },
    ),
  ],
),
```

#### Main Navigation Update
**Location**: `lib/routes.dart` (MainShell bottom navigation)

**Current Navigation:**
```
Dashboard | Accounts | Debts | Settings
```

**New Navigation (with Income):**
```
Dashboard | Income | Accounts | Debts | Settings
```

This places Income prominently as the second tab, making it easy for users to track their income sources right after viewing their dashboard overview.

---

### Phase 3: Integration with Existing Features

#### 3.1 Dashboard Integration
**File**: `lib/features/dashboard/dashboard_screen.dart`

**Add Income Summary Card**:
- Display total monthly net income
- Show breakdown by income type
- Quick link to Income screen
- Income trend indicator (if historical data exists)

**Position**: Between Assets and Liabilities cards

#### 3.2 Financial Health Score
**File**: `lib/data/calculators/financial_health.dart`

**Updates**:
- Replace `settings.monthlyIncome` with sum of all income sources
- Use net income for calculations (more accurate)
- Add income stability metric (based on # of sources)
- Consider income diversification score

```dart
final incomes = ref.watch(incomesProvider).maybeWhen(
  data: (list) => list,
  orElse: () => <Income>[],
);
final totalMonthlyIncome = incomes.fold<double>(
  0, (sum, income) => sum + income.monthlyNet
);
```

#### 3.3 Debt Load Calculator
**File**: `lib/data/calculators/debtload.dart`

**Updates**:
- Use sum of income sources instead of settings value
- Improve debt-to-income ratio accuracy
- Consider gross vs net for different calculations

#### 3.4 Liquidity Calculator
**File**: `lib/data/calculators/liquidity.dart`

**Updates**:
- Calculate emergency fund needs based on net income
- Consider income volatility (salary vs freelance)
- Adjust recommendations based on income stability

#### 3.5 Scenario Engine
**File**: `lib/features/scenario/scenario_engine_screen.dart`

**Updates**:
- Include future income projections in Monte Carlo
- Add salary growth rate parameter
- Consider retirement income replacement ratios

#### 3.6 Reports Screen
**File**: `lib/features/reports/reports_screen.dart`

**Add Income Section**:
- Income vs Expenses analysis
- Tax efficiency report
- Savings rate calculation (Net Income - Expenses)
- Income breakdown charts

#### 3.7 Export Service
**File**: `lib/services/export_service.dart`

**Updates**:
- Include income data in CSV exports
- Add income summary to PDF reports
- Export tax information for tax prep

---

### Phase 4: Advanced Features (Future)

#### 4.1 Income vs Expenses Tracking
- Link with monthlyEssentials
- Calculate savings rate automatically
- Budget tracking and alerts
- Spending categories

#### 4.2 Tax Planning
- Estimated tax liability
- Tax bracket analysis
- Deduction optimization suggestions
- Quarterly tax payment reminders

#### 4.3 Income Projections
- Career growth scenarios
- Retirement income modeling
- Social security estimates integration
- Pension payout calculations

#### 4.4 Multi-Currency Support
- Track income in different currencies
- Auto-convert to base currency
- International income (foreign employment, expat scenarios)

---

## Implementation Priority

### Must-Have (MVP)
1. ✅ Income data model with Hive storage
2. ✅ Income list screen with CRUD operations
3. ✅ Income detail form
4. ✅ Replace Settings.monthlyIncome with aggregated income
5. ✅ Update Financial Health calculator
6. ✅ Dashboard income summary card

### Should-Have (Phase 2)
7. Tax/deduction breakdown UI
8. Income charts and trends
9. Integration with Debt Load calculator
10. Export income data
11. Income diversification score

### Nice-to-Have (Future)
12. Income vs expenses analysis
13. Tax planning tools
14. Historical income tracking
15. Income projections
16. Budget integration

---

## Database Schema Changes

### New Hive Type
- **TypeId 8**: Income (reserve this in models.dart)

### Settings Updates (Optional)
Consider deprecating:
- `monthlyIncome` (replaced by aggregated Income entities)
- Keep `incomeMultiplierFallback` as fallback when no incomes exist

---

## UI/UX Considerations

### Income Categories (kind field)
1. **Salary/Wages** - Regular employment income
2. **Business Income** - Self-employment, freelance, consulting
3. **Rental Income** - Real estate rental proceeds
4. **Investment Income** - Dividends, interest, capital gains
5. **Pension** - Retirement pension payments
6. **Social Security** - Government benefits
7. **Alimony** - Spousal support received
8. **Child Support** - Child support received
9. **Other** - Miscellaneous income sources

### Frequency Options
- Monthly (default)
- Bi-weekly (every 2 weeks)
- Weekly
- Annual
- Quarterly

### Color Scheme
- Income cards: **Green** accent (positive, money coming in)
- Differentiate from Assets (blue) and Liabilities (red)

---

## Questions to Resolve

1. **Navigation**: Where should Income screen live? New nav item or under Settings?
2. **Tax Complexity**: How detailed should tax tracking be? Simple vs detailed?
3. **Historical Data**: Track income history from the start or phase 2?
4. **Currency**: Should each income source have its own currency field?
5. **Expenses**: Implement income + expenses together or separately?
6. **Integration**: Should income auto-link to retirement contributions in Assets?

---

## Migration Strategy

### For Existing Users
1. On app update, check if `Settings.monthlyIncome` exists
2. If yes, auto-create a default Income entry: "Salary" with that amount
3. Migrate smoothly without data loss
4. Show in-app message: "We've upgraded income tracking! Review your income sources."

---

## Testing Requirements

### Unit Tests
- Income model calculations (gross, net, monthly conversions)
- Repository CRUD operations
- Financial health calculator with multiple incomes
- Currency conversion for income

### Integration Tests
- Income list screen
- Income form validation
- Dashboard income summary
- Financial health score updates

### Edge Cases
- Zero income sources (show onboarding)
- Negative net income (high deductions)
- Multiple currencies
- Irregular frequencies (annual bonuses, quarterly dividends)

---

## Success Metrics

### User Engagement
- % of users who add at least one income source
- Average number of income sources per user
- Time to complete income setup

### Feature Usage
- Income screen views per session
- Income edit frequency
- Dashboard income card interactions

### Accuracy Improvements
- More accurate financial health scores
- Better debt-to-income ratios
- Improved emergency fund recommendations

---

## Timeline Estimate

### Week 1: Foundation
- Day 1-2: Data model + repository
- Day 3-4: Income list screen
- Day 5: Income detail screen

### Week 2: Integration
- Day 1-2: Dashboard integration
- Day 3-4: Financial health calculator updates
- Day 5: Testing + bug fixes

### Week 3: Polish
- Day 1-2: UI/UX refinements
- Day 3: Documentation
- Day 4: Migration code
- Day 5: Final testing + release

---

## Next Steps

1. **Decide on navigation placement** (where Income screen lives)
2. **Approve data model** (fields, structure, Hive typeId)
3. **Design UI mockups** (list screen, detail screen, dashboard card)
4. **Create implementation tasks** (break down into smaller tickets)
5. **Begin Phase 1 implementation** (data model + repository)

---

## Related Documents
- `SCHEMA_CHANGE_CHECKLIST.md` - Database migration guide
- `PRO_FEATURES_RESTRUCTURE.md` - Pro feature integration
- `RELEASE_CHECKLIST.md` - Release process
