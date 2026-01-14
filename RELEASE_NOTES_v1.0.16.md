# Release Notes - v1.0.16 (Build 33)

## New Features
- **Monthly Expenses Tracker**: Track recurring bills itemized by category (rent, utilities, insurance, subscriptions). Enter each expense separately with optional due dates instead of a single lump sum. Weekly Guardrails now automatically calculates from your actual expense list for better budget visibility.

## Improvements
- Fixed account card display for large balances - amounts over $100K now scale smoothly instead of wrapping to multiple lines
- Last updated timestamps now show real-time accuracy (just now, Xm ago, today) instead of estimated values

## Technical
- Added MonthlyExpense model with Hive encryption support
- Enhanced multi-currency conversion for expense tracking
- Improved account card layout with FittedBox for large numbers
