# iOS Setup Checklist for Rebalance v1.0.16

## ✅ Completed
- [x] iOS project structure created
- [x] Info.plist configured with privacy descriptions
- [x] ITSAppUsesNonExemptEncryption set to false (no custom encryption)
- [x] App icons generated (39 iOS icon sizes)
- [x] Launch screen configured
- [x] App Store release notes prepared

## 📋 Before Building
1. **Open in Xcode** (requires Mac)
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Set Bundle Identifier**
   - In Xcode: Runner > Signing & Capabilities
   - Change from `com.example.rebalance` to your unique ID
   - Example: `com.yourname.rebalance` or `com.platinummorgan.rebalance`

3. **Configure Team & Signing**
   - Select your Apple Developer team
   - Enable "Automatically manage signing"
   - Xcode will generate provisioning profiles

4. **Update App Icons** (if you have custom ones)
   - Replace icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
   - Or use your existing Android icons and generate iOS sizes

## 🏗️ Build for iOS

### Test on Simulator (no Apple Developer account needed)
```bash
flutter run -d "iPhone 15 Pro"
```

### Build for TestFlight/App Store (requires Apple Developer account)
```bash
flutter build ipa --release
```
Output: `build/ios/ipa/rebalance.ipa`

## 📤 App Store Submission

### Requirements
- **Apple Developer Account**: $99/year
- **Mac with Xcode**: Latest version recommended
- **App Store Connect**: Set up app listing at https://appstoreconnect.apple.com

### Submission Steps
1. Upload IPA via Xcode or Transporter app
2. Add to TestFlight for beta testing
3. Submit for App Store review
4. Provide:
   - Screenshots (iPhone & iPad)
   - App description (4000 char max)
   - Keywords (100 char max)
   - Support URL
   - Privacy policy URL
   - Release notes (see APP_STORE_RELEASE_NOTES_v1.0.16.txt)

### App Store Review Guidelines
- **Data Collection**: Emphasize "Private, offline, no data collection"
- **Encryption**: Already declared ITSAppUsesNonExemptEncryption = false
- **In-App Purchases**: If using Pro features, must be properly configured
- **Financial Claims**: Avoid promises of specific returns/gains
- **Review Time**: Typically 1-2 days

## 🔑 Current Configuration

### App Information
- **Version**: 1.0.16 (Build 33)
- **Display Name**: Rebalance
- **Bundle ID**: (needs to be set in Xcode)
- **Min iOS Version**: iOS 12.0
- **Supported Devices**: iPhone, iPad
- **Orientations**: Portrait, Landscape

### Dependencies Status
All dependencies support iOS:
- ✅ flutter_secure_storage
- ✅ hive_flutter
- ✅ in_app_purchase
- ✅ go_router
- ✅ riverpod
- ✅ intl
- ✅ currency_picker
- ✅ file_picker
- ✅ share_plus
- ✅ url_launcher

### Privacy Descriptions Added
- Photo Library Usage (for CSV exports)
- Photo Library Add Usage (for saving exports)

## 📱 Testing Checklist
- [ ] Test on iPhone simulator
- [ ] Test on iPad simulator
- [ ] Test on physical iPhone (TestFlight)
- [ ] Test on physical iPad (TestFlight)
- [ ] Verify all features work:
  - [ ] Account creation
  - [ ] Income tracking
  - [ ] Expense tracking (new feature)
  - [ ] Debt tracking
  - [ ] Weekly Guardrails calculations
  - [ ] CSV import/export
  - [ ] Pro features (if applicable)
  - [ ] Multi-currency support
  - [ ] Localization (5 languages)

## 🚨 Known iOS Considerations
- **Hive Encryption**: Uses flutter_secure_storage for keychain integration
- **File Picker**: May need additional permissions for certain file types
- **Share**: Works with native iOS share sheet
- **Dark Mode**: Should respect system settings (test both modes)
- **Safe Area**: Test on devices with notch (iPhone X+)
- **iPad**: Test split-view and slide-over modes

## 📖 Useful Commands
```bash
# Check iOS devices
flutter devices

# Clean build
flutter clean && flutter pub get

# Run on specific device
flutter run -d <device-id>

# Build release
flutter build ipa --release

# Analyze for issues
flutter analyze

# Run tests
flutter test
```

## 🔗 Resources
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## 🎯 Next Steps
1. Open project in Xcode on a Mac
2. Set unique Bundle Identifier
3. Configure signing with your Apple Developer account
4. Build and test on simulator
5. Submit to TestFlight for beta testing
6. Submit to App Store for review

**Current Status**: iOS project structure ready. Needs Mac + Xcode + Apple Developer account to proceed with builds and submission.
