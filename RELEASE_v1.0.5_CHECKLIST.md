# Release Checklist for v1.0.5+19

**Release Date:** October 14, 2025  
**Build Number:** 19  
**Version:** 1.0.5

---

## 📋 Pre-Release Verification

### ✅ Code Quality
- [ ] Run `flutter analyze` - ensure zero errors
- [ ] Run `flutter test` - ensure all tests pass
- [ ] Review and remove debug print statements
- [ ] Verify no test/sample data in production code
- [ ] Check that all currency conversion debug logs are removed or commented out

### ✅ App Functionality - New Features
**Income Tracking:**
- [ ] Add new income source - all fields save correctly
- [ ] Edit existing income - changes persist
- [ ] Delete income - confirmation dialog works
- [ ] Income list displays correctly with currency conversion
- [ ] Sample data loads income examples correctly
- [ ] Tax breakdown calculations are accurate (net = gross - deductions)
- [ ] Frequency calculations work (hourly, weekly, monthly, etc.)

**Currency Conversion:**
- [ ] Change currency in Settings - updates immediately
- [ ] Currency persists after app restart
- [ ] All screens display correct currency symbol
- [ ] Exchange rate caching works (24hr cache)
- [ ] Offline mode uses cached rates
- [ ] Currency picker search works
- [ ] **CRITICAL**: Test rounding accuracy (1000 CNY = ¥1,000.00, not ¥999.60)
- [ ] Income displays original amounts correctly when currency matches
- [ ] Account balances display original amounts correctly
- [ ] Liability amounts display original amounts correctly
- [ ] Net income calculations preserve accuracy

### ✅ Regression Testing - Existing Features
- [ ] Dashboard net worth calculates correctly
- [ ] Asset allocation pie chart displays properly (enlarged size)
- [ ] Account CRUD operations work
- [ ] Liability CRUD operations work
- [ ] Payment tracking works
- [ ] Debt optimizer calculates correctly
- [ ] Net worth history/snapshots work
- [ ] CSV export generates valid files
- [ ] Settings save and persist
- [ ] Pro features (if applicable) work
- [ ] Sample data loads successfully

### ✅ UI/UX Testing
- [ ] Test on phone (standard size)
- [ ] Test on tablet (if applicable)
- [ ] Test with different system fonts (up to 150% scaling)
- [ ] Test light theme
- [ ] Test dark theme
- [ ] Currency picker displays flags correctly
- [ ] Income form scrolls properly
- [ ] All touch targets are adequate size
- [ ] No UI overflow errors

### ✅ Data Integrity
- [ ] Existing users: test migration from v1.0.4
- [ ] New users: test fresh installation
- [ ] Income model saves with originalCurrency and originalAmount
- [ ] Account model saves with originalCurrency and originalBalance
- [ ] Liability model saves with originalCurrency, originalBalance, originalMinPayment, originalCreditLimit
- [ ] Settings saves with currency and baseCurrency fields
- [ ] Hive encryption still working
- [ ] Data persists across app restarts
- [ ] No data loss during currency switches

---

## 🔧 Build Configuration

### ✅ Version Information
- [x] Version in `pubspec.yaml`: 1.0.5+19
- [ ] CHANGELOG.md updated with all changes
- [ ] RELEASE_NOTES_v1.0.5.md complete
- [ ] Version matches Play Console

### ✅ Build Process
```bash
# Step 1: Clean
flutter clean
rm -rf build/

# Step 2: Get dependencies
flutter pub get

# Step 3: Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Step 4: Verify no errors
flutter analyze

# Step 5: Run tests
flutter test

# Step 6: Build release APK for testing
flutter build apk --release

# Step 7: Build release AAB for Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols/
```

### ✅ Testing Release Build
- [ ] Install release APK on test device
- [ ] Test complete user flow (onboarding → add data → navigate)
- [ ] Verify no debug logs appear
- [ ] Test currency conversion with fresh install
- [ ] Test migration from previous version (side-load if needed)
- [ ] Verify app signing is correct

### ✅ Final Checks
- [ ] Release notes reviewed by team
- [ ] Screenshots updated if UI changed
- [ ] Privacy policy still accurate
- [ ] Data safety form still correct
- [ ] No "TODO" or "FIXME" comments in critical code

---

## 📱 Play Store Preparation

### ✅ Store Listing
- [ ] Update "What's New" section with v1.0.5 highlights
- [ ] Screenshots show new Income tab (if applicable)
- [ ] Feature graphic updated (optional)
- [ ] Verify app description mentions currency support
- [ ] Check that all supported languages are accurate

### ✅ What's New Text (500 chars max)
```
🎉 v1.0.5 - Income Tracking & Multi-Currency!

✨ NEW:
• Income Tracking: Manage all income sources with tax breakdown
• Multi-Currency: Track finances in 150+ currencies with live conversion
• Enlarged pie charts for better visibility

🐛 FIXES:
• Currency rounding errors - perfect accuracy now
• Currency selection persists correctly
• Improved settings stability

💰 Track income, convert currencies, monitor net worth - all in one app!
```

### ✅ Upload to Play Console
- [ ] Log into Play Console
- [ ] Navigate to Rebalance app
- [ ] Create new release in Production track
- [ ] Upload `app-release.aab` from `build/app/outputs/bundle/release/`
- [ ] Enter release notes
- [ ] Review and confirm changes
- [ ] Set rollout percentage (recommend 20% initially)

---

## 🚀 Release Strategy

### ✅ Rollout Plan
**Phase 1: Initial Release (20%)**
- [ ] Deploy to 20% of users
- [ ] Monitor for 24 hours
- [ ] Check crash reports
- [ ] Review user feedback

**Phase 2: Expand (50%)**
- [ ] If Phase 1 stable, increase to 50%
- [ ] Monitor for 24 hours
- [ ] Continue checking metrics

**Phase 3: Full Rollout (100%)**
- [ ] If Phase 2 stable, push to 100%
- [ ] Announce on social media (if applicable)
- [ ] Prepare for user support inquiries

### ✅ Monitoring Metrics
- [ ] Crash rate < 2% (target: < 1%)
- [ ] ANR rate < 1% (target: < 0.5%)
- [ ] No critical user-reported bugs
- [ ] Average rating stable or improved
- [ ] New feature adoption tracking

---

## 📊 Post-Release

### ✅ Day 1 Checks
- [ ] Monitor Play Console crash reports
- [ ] Check user reviews (respond within 24hrs)
- [ ] Verify currency conversion API usage
- [ ] Monitor exchange rate API quota
- [ ] Check for any user confusion about new features

### ✅ Week 1 Checks
- [ ] Review all user feedback
- [ ] Track feature usage (if analytics enabled)
- [ ] Identify any common issues
- [ ] Plan hotfix if critical issues found
- [ ] Document lessons learned

### ✅ Communication
- [ ] Respond to user reviews mentioning new features
- [ ] Thank beta testers (if applicable)
- [ ] Update documentation if needed
- [ ] Share success metrics with team

---

## 🚨 Emergency Procedures

### If Critical Bug Found:
1. **Immediate**: Document the issue precisely
2. **Within 2 hours**: Identify root cause and create fix
3. **Within 6 hours**: Build and test hotfix
4. **Within 12 hours**: Submit v1.0.5+20 or v1.0.6
5. **Communication**: Update Play Store description with "Update in progress"

### Rollback Plan:
- Have v1.0.4+18 AAB ready to re-upload if needed
- Document rollback decision and reasons
- Plan communication to users

---

## ✅ Final Sign-Off

**Prepared by:** _________________  
**Date:** _________________  

**Reviewed by:** _________________  
**Date:** _________________  

**Approved for Release:** _________________  
**Date:** _________________  

---

## 📝 Notes

**Key Changes in v1.0.5:**
1. Income tracking with full CRUD operations
2. Multi-currency support with live conversion
3. Currency rounding error fix (dual-storage system)
4. Enlarged dashboard pie charts
5. Settings persistence improvements

**Risk Assessment:**
- **Low Risk**: UI improvements, pie chart sizing
- **Medium Risk**: Currency conversion (well-tested, has caching/offline fallback)
- **Medium Risk**: Income tracking (new feature, isolated from existing code)
- **Low Risk**: Currency rounding fix (improves accuracy, backward compatible)

**Rollback Readiness:** ✅ Ready  
**Test Coverage:** ✅ Comprehensive  
**User Impact:** ✅ Positive

---

**Ready for Release:** ⬜ YES / ⬜ NO

**Comments:**
_____________________________________________
_____________________________________________
_____________________________________________
