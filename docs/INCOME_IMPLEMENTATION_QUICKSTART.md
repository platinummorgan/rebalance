# Income Feature - Quick Implementation Guide

## Navigation Structure

### Current Navigation (4 tabs)
```
Dashboard | Accounts | Debts | Settings
```

### New Navigation (5 tabs)
```
Dashboard | Income | Accounts | Debts | Settings
```

---

## Step-by-Step Implementation

### Step 1: Add Income Route to routes.dart

**Location**: `lib/routes.dart`

Add after the Dashboard route (around line 65):

```dart
// Income section (NEW!)
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

Add to AppRouter constants (around line 26):

```dart
static const String income = '/income';
```

Add imports at top of file:

```dart
import 'features/income/income_screen.dart';
import 'features/income/income_detail_screen.dart';
```

---

### Step 2: Update Bottom Navigation Bar

**Location**: `lib/routes.dart` - MainShell class (around line 225)

**Update destinations array:**

```dart
destinations: const [
  NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: 'Dashboard',
  ),
  NavigationDestination(
    icon: Icon(Icons.attach_money_outlined),  // NEW!
    selectedIcon: Icon(Icons.attach_money),    // NEW!
    label: 'Income',                           // NEW!
  ),
  NavigationDestination(
    icon: Icon(Icons.account_balance_wallet_outlined),
    selectedIcon: Icon(Icons.account_balance_wallet),
    label: 'Accounts',
  ),
  NavigationDestination(
    icon: Icon(Icons.credit_card_outlined),
    selectedIcon: Icon(Icons.credit_card),
    label: 'Debts',
  ),
  NavigationDestination(
    icon: Icon(Icons.tune_outlined),
    selectedIcon: Icon(Icons.tune),
    label: 'Settings',
  ),
],
```

**Update _getSelectedIndex method:**

```dart
int _getSelectedIndex(BuildContext context) {
  final location = GoRouterState.of(context).matchedLocation;

  if (location.startsWith('/income')) return 1;        // NEW!
  if (location.startsWith('/accounts')) return 2;      // Changed from 1
  if (location.startsWith('/liabilities')) return 3;   // Changed from 2
  if (location.startsWith('/targets') ||
      location.startsWith('/export') ||
      location.startsWith('/pro') ||
      location.startsWith('/about')) {
    return 4;                                          // Changed from 3
  }

  return 0; // Dashboard
}
```

**Update _onDestinationSelected method:**

```dart
void _onDestinationSelected(BuildContext context, int index) {
  switch (index) {
    case 0:
      context.go(AppRouter.dashboard);
      break;
    case 1:
      context.go(AppRouter.income);              // NEW!
      break;
    case 2:
      context.go(AppRouter.accounts);            // Changed from case 1
      break;
    case 3:
      context.go(AppRouter.liabilities);         // Changed from case 2
      break;
    case 4:
      context.go(AppRouter.targets);             // Changed from case 3
      break;
  }
}
```

---

## Icon Options for Income Tab

Here are some good Material Icons for the Income tab:

1. **`Icons.attach_money`** ✅ (Recommended - Dollar sign, universal)
2. **`Icons.payments`** (Credit card payment style)
3. **`Icons.account_balance`** (Bank/institution style)
4. **`Icons.trending_up`** (Growth/increase style)
5. **`Icons.monetization_on`** (Coin with dollar sign)
6. **`Icons.work`** (Briefcase, work/salary style)
7. **`Icons.receipt_long`** (Receipt/paycheck style)

**Recommendation**: `Icons.attach_money_outlined` / `Icons.attach_money` (filled)
- Universal symbol for money
- Clear and recognizable
- Distinct from Accounts (wallet) and Debts (credit card)

---

## File Structure to Create

```
lib/
├── features/
│   └── income/
│       ├── income_screen.dart           (List of all income sources)
│       └── income_detail_screen.dart    (Add/Edit income form)
├── data/
│   └── models.dart                      (Add Income class)
└── data/
    └── repositories.dart                (Add Income repository)
```

---

## Next Steps After Navigation Update

1. ✅ Update navigation (Step 1 & 2 above)
2. Create Income data model (Hive entity)
3. Create Income repository
4. Build IncomeScreen (list view)
5. Build IncomeDetailScreen (form)
6. Update Dashboard to show income summary
7. Update Financial Health calculator

---

## Testing the Navigation

After making the changes:

1. Hot reload the app: `r` in terminal
2. You should see 5 tabs in the bottom navigation
3. Tapping "Income" should navigate to `/income` route
4. The Income tab should be highlighted when on that route

Initial state will show an error since IncomeScreen doesn't exist yet - that's expected!

---

## Design Considerations

### Color Scheme
- **Income**: Green accent (money coming in, positive)
- **Accounts**: Blue (neutral, informational)
- **Debts**: Red/Orange (caution, money going out)

### Empty State (No Income Sources)
```
💰 No Income Sources Yet
Track your income to improve financial insights
[+ Add Income Source] button
```

### Income Card Design
```
┌─────────────────────────────────┐
│ 💼 Primary Salary               │
│ ¥450,000 / month (net)          │
│ Bi-weekly • Updated 2 days ago  │
└─────────────────────────────────┘
```

---

## Implementation Priority

1. **Phase 1** (Week 1): Navigation + Basic UI
   - ✅ Add navigation tab
   - Create Income data model
   - Build list screen
   - Build detail/form screen

2. **Phase 2** (Week 2): Integration
   - Dashboard income summary
   - Financial health calculator update
   - Replace Settings.monthlyIncome

3. **Phase 3** (Week 3): Polish
   - Charts and visualizations
   - Export support
   - Testing and refinement

---

## Questions Resolved

✅ **Navigation**: Income goes after Dashboard, before Accounts
✅ **Tab count**: 5 tabs total (acceptable on mobile)
✅ **Icon**: `attach_money` icon family
✅ **Priority**: Primary navigation item, not hidden in Settings

---

Ready to implement! Start with updating the navigation in `lib/routes.dart` as shown above.
