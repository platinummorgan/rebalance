# Release Checklist

## Pre-Release Verification

### ✅ Code Quality
- [ ] Run `flutter analyze` with zero issues
- [ ] Run all tests with `flutter test` - 100% pass rate
- [ ] Code coverage > 80% for business logic
- [ ] All TODO comments resolved or documented
- [ ] No debug prints or test data in production code

### ✅ App Functionality
- [ ] Onboarding flow works correctly
- [ ] All calculator functions return expected results
- [ ] Data persistence works (accounts, liabilities, settings)
- [ ] Navigation between all screens works
- [ ] Form validation works properly
- [ ] Error handling displays user-friendly messages

### ✅ UI/UX Testing
- [ ] Test on multiple screen sizes (phone, tablet if supported)
- [ ] Test with system font scaling up to 130%
- [ ] Test both light and dark themes
- [ ] All touch targets are at least 44dp
- [ ] Test with Android accessibility services enabled
- [ ] Verify color contrast ratios meet WCAG guidelines

### ✅ Data & Privacy
- [ ] Hive encryption working properly
- [ ] No sensitive data logged to console
- [ ] CSV export generates anonymized data
- [ ] Import/export functions work correctly
- [ ] App works completely offline
- [ ] No network requests made (except for optional link opens)

### ✅ Performance
- [ ] App startup time < 3 seconds on mid-range device
- [ ] Smooth scrolling and animations (60fps)
- [ ] Memory usage stays reasonable with large datasets
- [ ] Battery usage acceptable during normal use

## Build Configuration

### ✅ Version Information
- [ ] Update version in `pubspec.yaml` (1.0.0+1)
- [ ] Version name matches marketing materials
- [ ] Build number incremented from previous release

### ✅ App Signing
- [ ] Generate release keystore (keep secure!)
- [ ] Configure `android/key.properties`
- [ ] Update `android/app/build.gradle` with signing config
- [ ] Test signed release build locally

### ✅ App Bundle Generation
```bash
# Clean and build release
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build appbundle --release

# Verify bundle
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=app.apks
bundletool install-apks --apks=app.apks
```

### ✅ Metadata & Assets
- [ ] App name correct in `AndroidManifest.xml`
- [ ] App icon generated and configured
- [ ] All required permissions documented and justified
- [ ] Adaptive icon works on all Android versions
- [ ] App screenshots generated (6 required)

## Play Store Submission

### ✅ Play Console Setup
- [ ] Developer account created and verified
- [ ] App created in Play Console
- [ ] Store listing information complete
- [ ] Privacy policy URL added
- [ ] Target audience and content rating set

### ✅ Content Requirements
- [ ] Upload all 6 screenshots with captions
- [ ] Feature graphic created (1024x500px)
- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)
- [ ] App category selected (Finance)
- [ ] Keywords optimized for ASO

### ✅ Release Management
- [ ] Upload signed AAB file
- [ ] Set up internal testing track first
- [ ] Test internal release thoroughly
- [ ] Create production release
- [ ] Set gradual rollout (start with 5%)

### ✅ Legal & Compliance
- [ ] Privacy policy live and accessible
- [ ] Data safety form completed accurately
- [ ] Content rating questionnaire completed
- [ ] Target age group specified
- [ ] In-app purchase items configured (if applicable)

## Post-Release Monitoring

### ✅ Launch Week
- [ ] Monitor crash reports in Play Console
- [ ] Track user reviews and ratings
- [ ] Monitor app performance metrics
- [ ] Check for any policy violations
- [ ] Increase rollout percentage gradually

### ✅ Success Metrics
- [ ] Crash rate < 2%
- [ ] ANR rate < 1%
- [ ] Average rating > 4.0
- [ ] No critical user-reported issues
- [ ] Install-to-usage conversion tracking

## Quick Build Commands

### Generate Release Bundle
```bash
# Clean build
flutter clean
flutter pub get

# Generate type adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Build release
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols/

# Output location
# build/app/outputs/bundle/release/app-release.aab
```

### Testing Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/calculators_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Analyze code
flutter analyze
```

### Keystore Commands
```bash
# Generate keystore (one time only)
keytool -genkey -v -keystore ~/wealth-dial-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Verify keystore
keytool -list -v -keystore ~/wealth-dial-key.jks
```

## Emergency Procedures

### Critical Issue Response
1. **Immediate**: Pull release from Play Store if possible
2. **Within 2 hours**: Identify root cause
3. **Within 24 hours**: Deploy hotfix or revert
4. **Within 48 hours**: Communicate with affected users

### Rollback Plan
1. Revert to previous stable version
2. Upload new build with reverted code
3. Update store listing with issue acknowledgment
4. Plan proper fix for next release

---

**Remember**: Better to delay launch than ship broken software. User trust is everything in finance apps.