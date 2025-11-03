# Rebalance - Version 1.0.5 Release Notes

**Release Date:** October 2025  
**Build Number:** 1.0.5

---

## 🎉 What's New

### � **Income Tracking** (Major Feature)
Comprehensive income management to complete your financial picture!

- **Multiple Income Sources**: Track salary, freelance work, rental income, bonuses, and more
- **Detailed Tax Breakdown**: Record federal tax, state tax, Social Security, Medicare, 401k contributions, health insurance, and other deductions
- **Smart Calculations**: Automatic computation of:
  - Monthly gross and net income
  - Annual gross and net income
  - Effective tax rate
  - Total deductions
- **Flexible Frequency Options**: Support for hourly, daily, weekly, bi-weekly, semi-monthly, monthly, quarterly, and annual income
- **10 Income Types**: Salary, Hourly Wage, Bonus, Commission, Freelance, Rental Income, Investment Income, Pension, Social Security, and Other
- **Dedicated Income Tab**: New navigation tab (💵 icon) for easy access
- **Sample Data Included**: Pre-loaded income examples when using "Load Sample Data"

**How it works:**
- Add unlimited income sources from the Income tab
- Optionally add detailed tax/deduction breakdown for accurate net income
- View total monthly and annual income at a glance
- All income stored in base currency (USD) with automatic display conversion

**Perfect for:**
- Tracking multiple income streams
- Understanding take-home pay after taxes
- Planning based on net vs. gross income
- Freelancers managing variable income

---

### �💱 **Live Currency Conversion** (Major Feature)
Transform your financial tracking experience with real-time currency conversion across 150+ currencies!

- **Automatic Currency Conversion**: All amounts automatically convert to your preferred currency
- **Real Exchange Rates**: Powered by live exchange rate API with 24-hour caching
- **Smart Performance**: Efficient caching prevents redundant conversions and saves battery
- **Offline Support**: Continues working with cached rates when offline
- **Universal Coverage**: Works across all 16 screens:
  - Dashboard net worth and deltas
  - Account balances and details
  - Liability tracking
  - Net Worth History graphs
  - Rebalancing recommendations
  - Reports and analytics
  - Pro features and targets

**How it works:**
- All amounts are stored in USD (universal standard)
- Display in any currency: USD, EUR, GBP, JPY, CNY, INR, THB, and 140+ more
- Exchange rates update automatically every 24 hours
- Changes persist across app restarts

**Perfect for:**
- Expats tracking finances in multiple countries
- International investors
- Travelers managing budgets
- Anyone who prefers their local currency

---

## 🎨 **UI/UX Improvements**

### Enhanced Dashboard Visualization
- **Larger Pie Chart**: Increased asset allocation pie chart size by 50%
  - Wider color sections (30→45px) for better visibility
  - Enlarged center area (50→70px) for clearer text display
  - Easier to read "Total Equities" percentage at a glance
  - Improved accessibility for all users

### Better Readability
- Optimized text sizing in pie chart center
- Enhanced contrast for key metrics
- More breathing room for percentage displays

---

## 🐛 **Bug Fixes**

### Critical Fixes
- **Currency Rounding Errors**: Fixed precision loss when converting between currencies
  - Values now display with perfect accuracy (e.g., 1000 CNY displays as ¥1,000.00, not ¥999.60)
  - Implemented dual-storage system: USD for calculations, original currency for display
  - Added `originalCurrency` and `originalAmount` fields to Income, Account, and Liability models
  - Prevents cumulative rounding errors across multiple entries
  - All monetary inputs (Income, Accounts, Liabilities) now preserve exact entered values
  
- **Currency Persistence Issue**: Fixed currency selection not saving properly
  - Currency changes now persist correctly across app restarts
  - All settings updates now preserve currency preferences
  - Fixed issue where currency would revert to USD after closing app
  - Updated 7 different settings update methods across the codebase

### Settings Stability
- Enhanced Settings object creation to preserve all fields
- Fixed missing `baseCurrency` field in multiple update methods
- Improved settings integrity in:
  - Currency selection (targets screen)
  - Theme changes
  - Dark mode toggle
  - Diversification mode updates
  - Pro purchase flows
  - Targets detail screen saves

---

## 🔧 **Technical Improvements**

### Performance Optimizations
- **Smart Caching System**: CurrencyText widget now caches conversion results
  - Prevents redundant API calls
  - Reduces battery consumption
  - Improves scroll performance
  - Unique cache keys prevent stale data

### Architecture Enhancements
- Migrated CurrencyText from FutureBuilder to StatefulWidget
  - Eliminated infinite loop issues
  - Better lifecycle management
  - More efficient state handling
  - Proper disposal of resources

### Code Quality
- Added comprehensive debug logging for currency conversion
- Type-safe exchange rate handling (int/double casting)
- Proper error handling for API failures
- Fallback mechanisms for offline scenarios

---

## 📊 **Data Management**

### Schema Updates
- **Income Model Added** (HiveType typeId: 11)
  - 13 fields including name, kind, gross amount, frequency
  - Tax deduction fields: federalTax, stateTax, socialSecurityTax, medicareTax
  - Retirement/benefit fields: retirement401k, healthInsurance, otherDeductions
  - Computed properties: monthlyGross, monthlyNet, annualGross, annualNet, effectiveTaxRate
- Added `baseCurrency` field to Settings (HiveField 26, default: 'USD')
- Added `currency` field for display preference (HiveField 25, default: 'USD')
- Schema version incremented to v2 for migration support
- Automatic migration for existing users

### API Integration
- Integrated exchangerate-api.com for live rates
- 1,500 requests/month on free tier (sufficient for all users)
- 24-hour cache duration optimizes API usage
- Graceful degradation when API unavailable

---

## 🎯 **User Experience**

### Settings Screen Enhancements
- New currency picker with:
  - Country flags for visual recognition
  - Currency codes and full names
  - Favorite currencies (USD, EUR, GBP, JPY, CNY) at top
  - Search functionality for 150+ currencies
  - Live conversion preview showing sample amounts

### Seamless Integration
- Zero configuration required - works out of the box
- One-time currency selection
- Instant UI updates across all screens
- No data loss during currency switches

---

## 🔐 **Stability & Reliability**

### Comprehensive Testing
- Tested currency conversion across all 16 display locations
- Verified persistence across app restarts
- Validated offline functionality
- Confirmed proper Settings object integrity

### Error Prevention
- Fixed all Settings constructor calls (7 methods updated)
- Prevented field loss during updates
- Enhanced state management
- Improved error handling

---

## 📱 **Compatibility**

- **Minimum SDK**: Android 6.0+ (API 23)
- **Target SDK**: Android 14 (API 34)
- **Flutter**: 3.x
- **Dependencies Updated**:
  - `currency_picker: ^2.0.21` (new - for currency selection)
  - `uuid: ^4.0.0` (for unique Income IDs)
  - `http: ^1.1.0` (for API calls)
  - `shared_preferences` (for caching)

---

## 🚀 **For Developers**

### New Components
- **Income Feature**:
  - `Income` model with 13 fields and computed properties
  - `IncomeScreen` - list view with summary cards
  - `IncomeDetailScreen` - add/edit form with optional tax breakdown
  - `incomesProvider` - Riverpod state management
  - Repository methods: `getIncomes()`, `saveIncome()`, `deleteIncome()`
- **Currency System**:
  - `CurrencyText` widget - reusable currency display with auto-conversion
  - `ExchangeRateService` - handles API calls, caching, and rate calculations
  - `CurrencyFormatter` enhancements - now supports conversion
- **Navigation**: Updated bottom nav to 5 tabs (Dashboard | Income | Accounts | Debts | Settings)

### Breaking Changes
None - all changes are backward compatible

### Migration Notes
Existing users will see:
- Automatic migration to schema v2
- Default currency set to USD
- All existing amounts preserved
- No action required

---

## 📈 **What's Next**

### Planned for v1.0.6
- Integrate income data with Financial Health calculator
- Income summary card on Dashboard
- Income vs. expenses tracking
- Remove debug logging after verification
- Add more currency-specific formatting options
- Enhanced offline mode indicators
- Currency conversion in PDF exports

### Future Considerations
- Income trends and analytics
- Budget planning with income forecasting
- Custom exchange rate sources
- Historical exchange rate data
- Multi-currency account support
- Currency trend analysis

---

## 🙏 **Acknowledgments**

Special thanks to:
- All beta testers for valuable feedback
- Codex AI for collaboration on complex debugging
- The Flutter community for excellent packages
- Our users for feature requests and bug reports

---

## 📝 **Known Issues**

None at this time. Please report any issues through:
- In-app feedback
- GitHub issues
- Google Play reviews

---

## 🔄 **Update Instructions**

**For Users:**
1. Open Google Play Store
2. Search for "Rebalance"
3. Tap "Update"
4. Launch app - currency feature ready to use!

**For New Users:**
1. Install from Google Play
2. Complete onboarding
3. Go to Settings → Display Currency
4. Select your preferred currency
5. All amounts will convert automatically!

---

## 📞 **Support**

Need help? Contact us:
- **Email**: support@rebalanceapp.com
- **Documentation**: [Setup Guide](SETUP_GUIDE.md)
- **FAQ**: Available in-app under Settings → Help

---

## 🎊 **Thank You!**

Thank you for using Rebalance! We're committed to making financial tracking simple, powerful, and accessible for everyone. Your feedback drives our development - keep it coming!

**Happy Rebalancing!** 💰📊✨

---

*Version 1.0.5 - Building better financial futures, one update at a time.*
