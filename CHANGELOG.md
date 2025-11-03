# Changelog

All notable changes to Rebalance will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **CSV Import**: Bulk import accounts, liabilities, and income from CSV files
  - File picker with CSV filter for easy file selection
  - Smart type detection (accounts, liabilities, income) based on headers
  - Preview with item count and error validation before import
  - Flexible column name matching (e.g., 'name'/'account_name', 'balance'/'amount')
  - Type normalization (e.g., '401k'→'retirement', 'checking'→'cash')
  - Default asset allocations for accounts when not specified
  - Comprehensive error handling and validation
  - Sample CSV files included for testing
  - Accessible from Settings > Import CSV

### Planned Features
- Income integration with Financial Health calculator
- Income summary card on Dashboard
- Income vs. expenses tracking
- Local notifications for bill due dates
- PDF wealth reports
- Encrypted backup/restore
- Dark mode themes
- Biometric app lock

### Changed
- Financial Health aggregator replaced with a contribution model (baseline + signed per-component contributions). Calibrated constants: baseline=75.0, globalScale=0.6. Added regression tests to lock outputs and verify muting behavior.

---

## [1.0.5] - 2025-10-14 (build 19)

### Added - Income Tracking 💰
- **Income Management**: Track multiple income sources with detailed tax breakdowns
- New Income tab in bottom navigation (2nd position with 💵 icon)
- Support for 10 income types: Salary, Hourly Wage, Bonus, Commission, Freelance, Rental Income, Investment Income, Pension, Social Security, Other
- 8 frequency options: Hourly, Daily, Weekly, Bi-Weekly, Semi-Monthly, Monthly, Quarterly, Annually
- Optional tax/deduction breakdown: Federal Tax, State Tax, Social Security, Medicare, 401k, Health Insurance, Other Deductions
- Automatic calculations: Monthly/Annual Gross & Net Income, Effective Tax Rate
- `Income` model (HiveType typeId: 11) with 13 fields and computed properties
- `IncomeScreen` with summary cards showing total income breakdown
- `IncomeDetailScreen` with comprehensive add/edit form
- Sample income data included in "Load Sample Data" feature

### Added - Currency Conversion 💱
- **Multi-Currency Support**: Live currency conversion for 150+ currencies
- Real-time exchange rates with 24-hour caching
- `CurrencyText` widget with automatic conversion
- `ExchangeRateService` for API calls and rate management
- Currency picker in Settings with country flags and search
- Works across all 16+ screens (Dashboard, Accounts, Liabilities, Reports, Pro features)
- Offline support with cached rates
- Added `currency` and `baseCurrency` fields to Settings model

### Improved
- Dashboard pie chart enlarged by 50% for better readability
- Enhanced text visibility in pie chart center
- **CSV Export**: Now saves directly to Downloads folder using native Android MediaStore API
  - No more share dialog confusion
  - Files save directly to `/storage/emulated/0/Download/`
  - Works on all Android versions (10+)
  - Files accessible through any file manager app
- Optimized navigation with 5-tab bottom bar: Dashboard | Income | Accounts | Debts | Settings
- Better Settings object integrity across all update methods

### Fixed
- **Critical**: Currency selection now persists correctly across app restarts
- **Critical**: Fixed currency rounding errors - values now display with perfect accuracy (e.g., 1000 CNY no longer shows as 999.60)
- Fixed missing `baseCurrency` field in Settings update methods (7 methods updated)
- Resolved Settings field loss during updates
- Fixed infinite loop issues in CurrencyText widget
- Improved state management and lifecycle handling
- Implemented dual-storage system: USD for calculations, original currency for display accuracy

### Technical
- Migrated CurrencyText from FutureBuilder to StatefulWidget for better performance
- Added comprehensive debug logging for currency conversion
- Enhanced caching system to prevent redundant API calls
- Schema version incremented to v2 for migration support
- Added dependencies: `currency_picker: ^2.0.21`, `uuid: ^4.0.0`

---

## [1.0.4] - 2025-10-09 (build 18)

### Improved
- Added Semantics labels to key interactive elements for better screen reader support
- Implemented haptic feedback (light/medium impact) on primary buttons and FAB interactions
- Improved tap target accessibility for all buttons (minimum 48×48 dp)
- UI polish pass on button states and visual feedback

### Changed
- Quick Add FAB now provides haptic feedback on tap and long-press
- Enhanced accessibility hints for interactive elements

---

## [1.0.3] - 2025-10-04 (build 17)

### Fixed
- Dashboard autosuggest overlapping Financial Health badge.
- Intl Exposure 'Light' mode and muting behavior corrected so scores update properly.
- APR input on Debt/Add screens accepts normal percentage typing and limits to two decimals.

---

## [1.0.0] - 2025-10-02

### 🎉 Initial Release

**First public release of Rebalance - Your Financial Health Companion**

### Added

#### Core Features
- **Net Worth Tracking**: Calculate and visualize total net worth (assets minus liabilities)
- **Asset Allocation**: Interactive donut charts across 6 asset classes (Cash, Bonds, US Equity, International Equity, Real Estate, Alternatives)
- **Financial Health Score**: Comprehensive 5-factor analysis with A-F grading
  - Debt Load (30% weight)
  - Concentration Risk (25% weight)
  - Liquidity Coverage (20% weight)
  - Fixed Income Allocation (15% weight)
  - Home Bias (10% weight)

#### Accounts & Liabilities
- Add/edit/delete accounts with 6 asset class types
- Track liabilities (credit cards, loans, mortgages, personal loans)
- Credit utilization tracking
- APR monitoring and high-APR debt alerts
- Payment tracking with history
- Quick "Mark as Paid" functionality from dashboard

#### Smart Guidance
- Action cards with specific dollar recommendations
- Rebalancing suggestions based on target allocations
- Emergency fund building guidance
- Debt payoff optimization

#### Debt Optimizer
- Avalanche strategy (highest APR first)
- Snowball strategy (smallest balance first)
- Custom extra payment calculator
- Payoff timeline with calendar dates (e.g., "Sep 2028")
- Month-by-month payment breakdown
- Interest savings calculations

#### Net Worth History
- Snapshot system for tracking over time
- Automatic daily snapshots
- Manual snapshot creation
- Snapshot comparison (before/after analysis)
- 7-day, 30-day, 90-day, 1-year trend views
- CSV export for all snapshots
- Delete individual snapshots

#### Privacy & Security
- 100% local storage - no cloud, no accounts, no tracking
- AES-256 encrypted database (flutter_secure_storage)
- No analytics, ads, or data collection
- Works completely offline

#### UI/UX
- Material Design 3
- Responsive layouts for all screen sizes
- Dark theme support
- Accessibility features (semantic labels, screen reader support)
- Custom splash screen
- Intuitive navigation with bottom nav bar

### Technical Details
- **Platform**: Android (Flutter 3.24+)
- **Database**: Drift (SQLite) with encryption
- **State Management**: Riverpod 2.x
- **Min SDK**: Android 21 (Lollipop, 5.0)
- **Target SDK**: Android 34

### Known Issues
- Snapshots limited to 90 days of history (will extend in future)
- No cloud backup (local only)
- Android only (iOS planned for future)

---

## Version Guidelines

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR** (1.x.x): Breaking changes, major new features
- **MINOR** (x.1.x): New features, backwards compatible
- **PATCH** (x.x.1): Bug fixes, small improvements

### Categories
- `Added`: New features
- `Changed`: Changes to existing functionality
- `Deprecated`: Soon-to-be removed features
- `Removed`: Removed features
- `Fixed`: Bug fixes
- `Security`: Security fixes

---

## Example Future Releases

```markdown
## [1.1.0] - TBD

### Added
- Local notifications for bill reminders
- PDF wealth check reports
- Investment goals tracking

### Fixed
- Minor UI overflow on payment screen
- CSV export loading indicator

---

## [1.0.1] - TBD

### Fixed
- Payment dialog overflow on small screens
- CSV export freezing issue
- Splash screen logo appearing on some devices

### Changed
- Improved debt optimizer performance
- Updated health score calculation display
```

---

## Support

Found a bug or have a feature request?
- **In-App**: Settings → Send Feedback / Report Bug
- **Email**: support@rebalance.app (coming soon)
- **GitHub**: github.com/yourusername/rebalance (if open source)

---

## License

Copyright © 2025 Rebalance. All rights reserved.
