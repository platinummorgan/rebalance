# Release 1.0.5 - Final Pre-Launch Checklist

**Target Release Date:** October 19, 2025  
**Build:** 1.0.5+19  
**AAB File:** `build\app\outputs\bundle\release\app-release.aab` (44.9MB)

---

## ✅ Pre-Launch Tasks (October 18)

### Final Testing
- [ ] Install release AAB on test device
- [ ] Test income tracking (add/edit/delete)
- [ ] Test currency conversion (change currency in settings)
- [ ] Test CSV export to Downloads
- [ ] Verify dashboard displays correctly
- [ ] Test account/liability creation
- [ ] Verify currency rounding accuracy (1000 CNY = ¥1,000.00)
- [ ] Check all navigation flows
- [ ] Test in-app purchases (if applicable)

### Beta Testing Review
- [ ] Check Google Play Console for crash reports
- [ ] Review any beta tester feedback
- [ ] Ensure no critical bugs reported
- [ ] Verify 14-day testing period completed

### Documentation
- [ ] ✅ CHANGELOG.md updated
- [ ] ✅ Release notes prepared
- [ ] ✅ "What's New" text ready (500 chars)

---

## 🚀 Launch Day Tasks (October 19)

### 1. Google Play Console - Production Release

#### Navigate to Release
1. Open [Google Play Console](https://play.google.com/console)
2. Select "Rebalance" app
3. Go to **Production** → **Releases**
4. Click **Create new release**

#### Upload Build
1. Click **Upload** and select:
   ```
   D:\Dev\wealth_dial\build\app\outputs\bundle\release\app-release.aab
   ```
2. Wait for upload to complete
3. Verify build number shows: **1.0.5 (19)**

#### Release Details
**Release name:** `1.0.5`

**What's new (paste this):**
```
🎉 New in v1.0.5:

💰 INCOME TRACKING
• Track multiple income sources with tax breakdowns
• 10 income types, 8 frequency options
• Automatic net/gross calculations

💱 MULTI-CURRENCY SUPPORT
• 150+ currencies with live exchange rates
• Automatic conversion across all screens
• Works offline with smart caching

✨ IMPROVEMENTS
• Larger dashboard pie chart (50% bigger)
• Fixed currency rounding errors for perfect accuracy
• Enhanced CSV export - saves directly to Downloads

🐛 Bug fixes and stability improvements
```

#### Rollout Strategy
**Recommended:** Staged rollout
- [x] Start with **20% of users**
- Monitor for 24-48 hours
- Increase to 50% if no issues
- Increase to 100% after another 24 hours

**Alternative:** Full release
- [x] Release to **100% of users** immediately
- Higher risk but faster deployment

### 2. Review and Submit

#### Pre-Submit Review
- [ ] Verify app content rating is correct
- [ ] Check privacy policy link is working
- [ ] Ensure all required permissions are documented
- [ ] Review target audience settings
- [ ] Verify app is in correct category (Finance)

#### Submit for Review
1. Review all details one final time
2. Click **Review release**
3. Check for any warnings/errors
4. Click **Start rollout to Production**
5. Confirm the release

---

## 📊 Post-Launch Monitoring (First 48 Hours)

### Day 1 (Release Day)
- [ ] Check for crash reports every 2-4 hours
- [ ] Monitor user reviews
- [ ] Watch for any patterns in bug reports
- [ ] Verify rollout percentage is working

### Day 2
- [ ] Review crash-free rate (should be >98%)
- [ ] Check ANR (Application Not Responding) rate
- [ ] Monitor review sentiment
- [ ] If all good: Increase rollout to 50%

### Day 3
- [ ] Final stability check
- [ ] If all good: Increase to 100%

### Key Metrics to Watch
- **Crash-free users rate:** Target >99%
- **ANR rate:** Target <0.5%
- **Uninstall rate:** Should remain stable
- **User ratings:** Should stay at current level or improve

---

## 🔍 What Google Reviews

Google Play will automatically review your app for:
- **Malware/Security:** Usually instant if no issues
- **Policy Compliance:** 1-2 days typically
- **Content Rating:** Verify matches your app
- **Permissions:** Ensure properly documented

**Typical Review Time:** 1-3 days  
**Your Status:** Should be fast since it's an update, not new app

---

## ⚠️ Troubleshooting

### If Release is Rejected
1. Check email for rejection reason
2. Fix the issue
3. Increment build number to 20
4. Rebuild: `flutter build appbundle --release`
5. Re-submit

### If Crashes Spike After Release
1. Halt rollout immediately
2. Check crash reports in Play Console
3. Identify affected Android versions/devices
4. Create hotfix
5. Submit v1.0.6

### If Users Report Issues
1. Respond to reviews promptly
2. Document issues in GitHub
3. Prioritize for v1.0.6
4. Consider hotfix if critical

---

## 📱 Communications

### Update App Description (Optional)
Consider adding to long description:
```
NEW IN v1.0.5:
✓ Income tracking with tax breakdowns
✓ Multi-currency support (150+ currencies)
✓ Enhanced dashboard visualization
✓ Improved CSV export
```

### Social Media (If Applicable)
```
🎉 Rebalance v1.0.5 is now live!

New features:
💰 Income tracking
💱 Multi-currency support
📊 Better dashboard
📥 Improved CSV export

Download/Update now on Google Play!
```

---

## 🎯 Success Criteria

Release is considered successful when:
- ✅ Crash-free rate >99%
- ✅ ANR rate <0.5%
- ✅ No critical bugs reported
- ✅ User reviews remain positive (>4.0 stars)
- ✅ No policy violations
- ✅ Rollout reaches 100%

---

## 📞 Emergency Contacts

**If Critical Issue Arises:**
1. Halt rollout in Google Play Console
2. Document the issue
3. Create hotfix branch
4. Test thoroughly
5. Submit v1.0.6 emergency release

**Google Play Support:**
- [Help Center](https://support.google.com/googleplay/android-developer)
- Use "Contact us" in Play Console for urgent issues

---

## 📝 Post-Release Tasks

### After Successful Release
- [ ] Update README.md with v1.0.5 info
- [ ] Create Git tag: `v1.0.5`
- [ ] Archive release AAB for records
- [ ] Document any learnings
- [ ] Plan v1.0.6 features

### Versioning for Next Release
**v1.0.6 Planning:**
- Increment version to `1.0.6+20` in pubspec.yaml
- Create new changelog section
- Address any feedback from v1.0.5

---

## ✅ Final Checklist Before Clicking "Release"

- [ ] AAB uploaded successfully
- [ ] Release notes pasted and look good
- [ ] Rollout percentage selected
- [ ] No warnings in Play Console
- [ ] Beta testing period complete (14 days)
- [ ] No critical bugs reported
- [ ] Team notified of pending release

**Ready to go? Click that release button! 🚀**

---

## 🎊 Congratulations!

You've successfully released v1.0.5! 

Key achievements:
- ✅ Income tracking feature
- ✅ Multi-currency support
- ✅ Fixed critical rounding bugs
- ✅ Enhanced user experience

**Well done! Time to monitor and then plan v1.0.6!** 🎉

