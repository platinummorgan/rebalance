# Wealth Dial

> Calculate net worth, visualize asset allocation, and get diversification insights—all private, offline, and fast.

A Flutter-based Android app for comprehensive wealth management and portfolio analysis with privacy-first design.

## Features

### 📊 Financial Analysis
- **Net Worth Calculation**: Assets minus liabilities with trend tracking
- **Asset Allocation Visualization**: Interactive donut charts across 6 asset classes
- **Diversification Scoring**: 5-factor analysis with color-coded grades
- **Historical Tracking**: 90-day sparklines and snapshot management

### 🎯 Smart Guidance  
- **Action Cards**: Specific recommendations with dollar amounts
- **Rebalancing Alerts**: Drift detection with monthly targets
- **Debt Optimization**: APR-based payoff strategies
- **Emergency Fund**: Liquidity assessment and building guidance

### 🔒 Privacy & Security
- **No Sign-Up Required**: Start using immediately
- **Local Storage Only**: All data stays on your device
- **Encrypted Database**: AES encryption for sensitive information
- **No Behavioral Tracking**: No ads and no analytics telemetry

### 💎 Pro Features
- Local notifications and alerts
- Encrypted backup/restore with passphrase
- PDF "Wealth Check" reports
- Dark mode themes
- Biometric app lock

## Quick Start

### Prerequisites
- Flutter 3.10+ 
- Dart 3.0+
- Android SDK with API level 24+

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/wealth_dial.git
cd wealth_dial

# Install dependencies
flutter pub get

# Generate type adapters for Hive
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### Sample Data
The app includes a "Load Sample Data" feature to demonstrate all functionality with realistic financial scenarios.

## Architecture

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app configuration  
├── routes.dart               # Go router navigation
├── theme.dart                # Material 3 theme
├── data/
│   ├── models.dart           # Hive data models
│   ├── repositories.dart     # Data persistence layer
│   ├── snapshot_service.dart # Historical data management
│   └── calculators/          # Business logic
│       ├── allocation.dart   # Asset totals and percentages
│       ├── liquidity.dart    # Emergency fund analysis
│       ├── concentration.dart# Risk concentration detection
│       ├── homebias.dart     # Geographic diversification
│       ├── fixedincome.dart  # Bond allocation analysis
│       ├── debtload.dart     # Debt sustainability scoring
│       └── actions.dart      # Action card generation
└── features/                 # UI screens organized by feature
    ├── onboarding/
    ├── dashboard/
    ├── accounts/
    ├── liabilities/
    ├── targets/
    ├── export/
    └── pro/
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Riverpod**: State management and dependency injection
- **Hive**: Local encrypted database
- **Go Router**: Declarative navigation
- **FL Chart**: Data visualization
- **Flutter Secure Storage**: Encryption key management

## Data Models

### Core Entities
```dart
// Investment accounts with allocation breakdown
Account {
  String id, name, kind;
  double balance;
  double pctCash, pctBonds, pctUsEq, pctIntlEq, pctRealEstate, pctAlt;
  double employerStockPct; // For concentration risk
}

// Debts and liabilities  
Liability {
  String id, name, kind;
  double balance, apr, minPayment;
  double? creditLimit; // For utilization calculation
}

// User preferences and targets
Settings {
  RiskBand riskBand; // Conservative, Balanced, Growth
  double monthlyEssentials; // For liquidity calculation
  double driftThresholdPct; // Rebalancing sensitivity
  double usEquityTargetPct; // Home bias target
}
```

## Calculation Engine

### Diversification Factors

1. **Liquidity (Emergency Fund)**
   - Formula: `(Cash + 0.5×Bonds) / monthlyEssentials`
   - Bands: Red <1mo, Yellow 1-3mo, Green 3-6mo, Blue >6mo

2. **Concentration (Risk Management)** 
   - Formula: `max(allocationBuckets) or employerStockPct`
   - Bands: Red >20%, Yellow 10-20%, Green <10%

3. **Home Bias (Geographic Diversification)**
   - Formula: `intlEquityPct within totalEquity`
   - Target: 20% international (adjustable)

4. **Fixed Income (Risk-Appropriate Bonds)**
   - Targets: Conservative 60%, Balanced 40%, Growth 20%
   - Based on investable assets (excludes cash/RE)

5. **Debt Load (Sustainability)**
   - Flags: Revolving debt >20% APR, credit util >90%
   - Considers mortgage-to-net-worth ratio

### Action Card Logic
- **Priority Order**: High APR debt → Liquidity → Concentration → Bonds → Home bias
- **Monthly Targets**: 6-month glide path for rebalancing suggestions
- **Specific Guidance**: Dollar amounts, not just percentages

## Testing

### Run Tests
```bash
# All tests
flutter test

# Specific test file
flutter test test/calculators_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Coverage
- ✅ Unit tests for all calculator functions
- ✅ Widget tests for onboarding flow  
- ✅ Golden tests for key screens
- ✅ Integration tests for data persistence

## Building for Release

### Generate Release Bundle
```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Configure production dart defines (one-time setup)
cp config/dart_defines.production.example.json config/dart_defines.production.json
# Edit config/dart_defines.production.json with real ENTITLEMENT_API_BASE_URL and ENTITLEMENT_API_KEY

# Build signed release (with entitlement backend defines)
flutter build appbundle --release \
  --dart-define-from-file=config/dart_defines.production.json \
  --obfuscate \
  --split-debug-info=build/symbols/

# Output: build/app/outputs/bundle/release/app-release.aab
```

PowerShell helper (Windows):
```powershell
.\tools\build_release_appbundle.ps1
```

### Keystore Setup
```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore ~/wealth-dial-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configure android/key.properties
storePassword=your_store_password
keyPassword=your_key_password  
keyAlias=upload
storeFile=/path/to/wealth-dial-key.jks
```

## Privacy & Security

### Local Storage
- **Hive Database**: Encrypted with AES-256
- **Secure Key Storage**: Platform keychain integration
- **Offline-First**: Core budgeting/portfolio features run locally
- **Limited Network Calls**: Optional FX rate lookup and purchase entitlement verification
- **Data Isolation**: Sandboxed app storage

### Export Options
- **CSV**: Anonymized account balances only
- **Encrypted JSON**: Full backup with user passphrase
- **User Control**: Manual export only, no automatic syncing

## Contributing

### Development Setup
1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Follow Flutter/Dart style guidelines
4. Add tests for new functionality
5. Ensure `flutter analyze` passes with zero issues
6. Submit pull request

### Code Style
- Use `flutter format` for consistent formatting
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Prefer composition over inheritance
- Write self-documenting code with clear naming

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Disclaimer

**Educational Information Only**: Wealth Dial provides educational information and should not be considered as financial advice. Consider your unique circumstances and consult a qualified professional for personalized guidance.

**No Warranty**: The software is provided "as is" without warranty of any kind. Users are responsible for verifying calculations and making their own financial decisions.

## Support

- **Documentation**: [docs/](docs/) folder
- **Issues**: GitHub Issues for bug reports
- **Privacy Policy**: [PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md)
- **Release Checklist**: [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md)

---

Built with ❤️ using Flutter • Privacy-first • Open Source
