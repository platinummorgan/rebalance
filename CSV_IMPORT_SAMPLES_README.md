# CSV Import Sample Files

This folder contains sample CSV files for testing the CSV Import feature in Rebalance.

## Sample Files

### 1. sample_accounts.csv
Import accounts with asset allocations. Supports:
- **Account Types**: retirement, taxable, cash, hsa, 529
- **Columns**: name, account_type, balance, pct_cash, pct_bonds, pct_us_equity, pct_intl_equity, pct_real_estate, pct_alt

### 2. sample_liabilities.csv
Import debts and liabilities. Supports:
- **Liability Types**: credit_card, auto, mortgage, student_loan, personal_loan, other
- **Columns**: name, liability_type, balance, apr, min_payment, credit_limit (optional)

### 3. sample_income.csv
Import income sources with tax deductions. Supports:
- **Income Types**: salary, freelance, rental, investment, business, other
- **Columns**: name, income_type, gross_amount, frequency, federal_tax, state_tax, social_security_tax, medicare_tax, retirement_401k, health_insurance, other_deductions
- **Frequency**: monthly, biweekly, weekly, annual

### 4. sample_invalid.csv
Example of an invalid CSV to test error handling.

## How to Use

1. Open Rebalance app
2. Go to **Settings** tab (bottom navigation)
3. Tap **Import CSV**
4. Select one of these sample files
5. Review the preview
6. Tap **Import** to add items to your app

## CSV Format Requirements

### Common Rules
- First row must contain column headers
- Required columns must be present (name, type, balance/amount)
- Optional columns will use defaults if missing
- Type detection is automatic based on headers

### Flexible Column Names
The importer supports variations:
- `name` or `account_name`
- `balance` or `amount`
- `account_type`, `type`, or `kind`
- `liability_type`, `debt_type`, or `type`
- `income_type` or `type`

### Allocation Percentages
For accounts, if allocations aren't specified:
- **Retirement accounts** default to: 5% cash, 20% bonds, 50% US equity, 15% intl equity, 5% real estate, 5% alt
- **Cash accounts** default to: 100% cash
- **Taxable accounts** default to: 10% cash, 30% bonds, 35% US equity, 20% intl equity, 5% real estate

## Testing Checklist

- [ ] Import sample_accounts.csv - should add 5 accounts
- [ ] Import sample_liabilities.csv - should add 5 liabilities
- [ ] Import sample_income.csv - should add 3 income sources
- [ ] Import sample_invalid.csv - should show error message
- [ ] Verify data appears in Accounts/Debts/Income screens
- [ ] Verify allocations are correct
- [ ] Edit imported item to ensure it's fully functional
- [ ] Test with empty CSV - should show error

## Notes

- All amounts are in USD by default
- Percentages should add up to 100 for accounts
- APR is annual percentage rate (e.g., 18.99 for 18.99%)
- Tax deductions are monthly amounts
- Negative balances are not allowed
