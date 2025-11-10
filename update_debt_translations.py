#!/usr/bin/env python3
"""Script to replace hardcoded strings in debt_optimizer_screen.dart with translations."""

import re

# Read the Dart file
with open('lib/features/debt/debt_optimizer_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Define replacements (old string -> new translation call)
replacements = [
    # Simple text replacements
    ("const Text(\n                'No debts to optimize!',", "Text(\n                AppLocalizations.of(context)!.noDebtsToOptimize,"),
    ("Text(\n                'Add liabilities from the Liabilities tab to use this tool.',", "Text(\n                AppLocalizations.of(context)!.addLiabilitiesFromTab,"),
    ("'Current Debt'", "AppLocalizations.of(context)!.currentDebt"),
    
    # Line 248 - complex string with pluralization
    ("'${liabilities.length} ${liabilities.length == 1 ? 'liability' : 'liabilities'} • ${_formatCurrency(totalMinPayment)}/mo minimum'",
     "AppLocalizations.of(context)!.liabilityCount(liabilities.length, _formatCurrency(totalMinPayment))"),
    
    ("'Extra Monthly Payment'", "AppLocalizations.of(context)!.extraMonthlyPayment"),
    ("'Total monthly payment: ${_formatCurrency(totalMinPayment + _extraPayment)}'",
     "AppLocalizations.of(context)!.totalMonthlyPayment(_formatCurrency(totalMinPayment + _extraPayment))"),
    
    ("'Payoff Strategies'", "AppLocalizations.of(context)!.payoffStrategies"),
    ("'We recommend the option with lower total interest. You can still select the other for motivation wins.'",
     "AppLocalizations.of(context)!.strategyRecommendation"),
    
    # Strategy titles and descriptions
    ("'Avalanche${betterStrategy == 'avalanche' ? ' (Recommended)' : ''}'",
     "betterStrategy == 'avalanche' ? AppLocalizations.of(context)!.avalancheRecommended : AppLocalizations.of(context)!.avalanche"),
    ("'Highest APR first – minimizes total interest'", "AppLocalizations.of(context)!.avalancheDescription"),
    ("'Snowball${betterStrategy == 'snowball' ? ' (Recommended)' : ''}'",
     "betterStrategy == 'snowball' ? AppLocalizations.of(context)!.snowballRecommended : AppLocalizations.of(context)!.snowball"),
    ("'Smallest balance first – faster psychological wins'", "AppLocalizations.of(context)!.snowballDescription"),
    
    # Pro gate
    ("'Unlock Detailed Payoff Schedule'", "AppLocalizations.of(context)!.unlockDetailedPayoffSchedule"),
    ("'Get month-by-month payment breakdown showing:'", "AppLocalizations.of(context)!.monthByMonthBreakdown"),
    ("'Exact payoff date for each debt'", "AppLocalizations.of(context)!.exactPayoffDate"),
    ("'Principal vs interest breakdown'", "AppLocalizations.of(context)!.principalVsInterest"),
    ("'Remaining balance tracking'", "AppLocalizations.of(context)!.remainingBalanceTracking"),
    ("'Total interest saved: ${_formatCurrency(betterResult.interestSavingsVsMinimum)}'",
     "AppLocalizations.of(context)!.totalInterestSaved(_formatCurrency(betterResult.interestSavingsVsMinimum))"),
    
    # Debt payoff order
    ("'Debt Payoff Order'", "AppLocalizations.of(context)!.debtPayoffOrder"),
    ("'Debts will be paid off in this order (${_activeStrategy!.toUpperCase()} strategy):'",
     "AppLocalizations.of(context)!.debtsWillBePaidInOrder(_activeStrategy!.toUpperCase())"),
    ("'Paid off'", "AppLocalizations.of(context)!.paidOff"),
    
    # Strategy card
    ("'Payoff Time'", "AppLocalizations.of(context)!.payoffTime"),
    ("'${result.monthsToPayoff} months'", "AppLocalizations.of(context)!.monthsCount(result.monthsToPayoff)"),
    ("'Total Interest'", "AppLocalizations.of(context)!.totalInterest"),
    ("'Save ${_formatCurrency(result.interestSavingsVsMinimum)} vs minimum payments'",
     "AppLocalizations.of(context)!.saveVsMinimum(_formatCurrency(result.interestSavingsVsMinimum))"),
    
    # Payment schedule
    ("'Detailed Payment Schedule'", "AppLocalizations.of(context)!.detailedPaymentSchedule"),
    ("'Month-by-month breakdown (${_activeStrategy!.toUpperCase()} strategy):'",
     "AppLocalizations.of(context)!.monthByMonthStrategy(_activeStrategy!.toUpperCase())"),
    ("'Month ${month.month}'", "AppLocalizations.of(context)!.monthNumber(month.month)"),
    ("'${_formatCurrency(month.principalPayment)} principal • ${_formatCurrency(month.interestPayment)} interest'",
     "AppLocalizations.of(context)!.principalAndInterest(_formatCurrency(month.principalPayment), _formatCurrency(month.interestPayment))"),
    ("'Remaining: ${_formatCurrency(month.remainingBalance)}'",
     "AppLocalizations.of(context)!.remaining(_formatCurrency(month.remainingBalance))"),
    ("'... ${result.schedule.length - 12} more months'",
     "AppLocalizations.of(context)!.moreMonths(result.schedule.length - 12)"),
    
    # Strategy comparison
    ("'Strategy Comparison'", "AppLocalizations.of(context)!.strategyComparison"),
    
    # Pro gate screen
    ("'Unlock Debt Payoff Optimizer'", "AppLocalizations.of(context)!.unlockDebtPayoffOptimizer"),
    ("'Find the fastest path to debt freedom'", "AppLocalizations.of(context)!.fastestPathToDebtFreedom"),
    ("'Compare avalanche vs snowball strategies'", "AppLocalizations.of(context)!.compareAvalancheSnowball"),
    ("'See exact payoff dates for each debt'", "AppLocalizations.of(context)!.seeExactPayoffDates"),
    ("'Calculate total interest savings'", "AppLocalizations.of(context)!.calculateInterestSavings"),
    ("'Get month-by-month payment schedule'", "AppLocalizations.of(context)!.getMonthlySchedule"),
    
    # Chip labels
    ("'BEST'", "AppLocalizations.of(context)!.best"),
    ("'SELECTED'", "AppLocalizations.of(context)!.selected"),
    ("'Select strategy'", "AppLocalizations.of(context)!.selectStrategy"),
    
    # Already fixed - Go Back
    # (This was already done earlier in the session)
]

# Apply all replacements
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✓ Replaced: {old[:50]}...")
    else:
        print(f"⚠ Not found: {old[:50]}...")

# Handle complex replacement for strategySavingsComparison
old_pattern = r"'\$betterLabel saves \${_formatCurrency\(interestDiff\)} more interest\$\{monthsDiff > 0 \? ' and finishes \$monthsDiff month\$\{monthsDiff == 1 \? '' : 's'\} sooner' : ''\} vs the other approach\.'"
new_pattern = "AppLocalizations.of(context)!.strategySavingsComparison(betterLabel, _formatCurrency(interestDiff), monthsDiff > 0 ? AppLocalizations.of(context)!.andFinishesEarlier(monthsDiff, monthsDiff == 1 ? '' : 's') : '')"
if re.search(old_pattern, content):
    content = re.sub(old_pattern, new_pattern, content)
    print("✓ Replaced complex strategySavingsComparison")
else:
    print("⚠ Pattern not found for strategySavingsComparison - will try simpler pattern")
    # Try simpler match
    simple_old = "'$betterLabel saves ${_formatCurrency(interestDiff)} more interest${monthsDiff > 0 ? ' and finishes $monthsDiff month${monthsDiff == 1 ? '' : 's'} sooner' : ''} vs the other approach.'"
    if simple_old in content:
        content = content.replace(simple_old, new_pattern)
        print("✓ Replaced strategySavingsComparison with simple pattern")

# Write back
with open('lib/features/debt/debt_optimizer_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ Updated debt_optimizer_screen.dart with all translations")
