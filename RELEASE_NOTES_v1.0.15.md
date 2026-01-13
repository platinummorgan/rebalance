# Release Notes - v1.0.15 (Build 32) - PRODUCTION

**Release Date:** November 21, 2025  
**Type:** Production Release

## 🎯 Production-Ready Features

### Backup & Restore System
- **Complete Data Backup** - Export all accounts, debts, income, and settings to a single JSON file
- **Direct to Downloads** - Backup files automatically save to your Downloads folder
- **Easy Restore** - Pick any backup file to restore your complete financial data
- **Clear Feedback** - Shows exact file location after backup completes

### Subscription Management
- **Expiry Enforcement** - Monthly and annual subscriptions now properly expire after their billing period
- **Auto-Revocation** - Expired subscriptions automatically lose Pro access on app launch
- **Renewal Handling** - Subscription renewals extend from current expiry date (no time loss)
- **Lifetime Access** - Existing Pro users grandfathered with lifetime access

### Purchase Flow
- **Cancellation Tracking** - User cancellations during payment flow logged to analytics
- **Error Diagnostics** - Better purchase failure tracking and reporting
- **Founder Status** - "Already purchased" message shows correctly for lifetime members

## 🛠️ Technical Improvements

### Data Persistence
- Subscription expiry dates stored in Hive database
- Settings survive app restarts and OS updates
- Migration from v1.0.11 seamlessly handles new fields

### Code Quality
- Removed deprecated in_app_purchase API calls
- Fixed loading dialog dismissal issues
- File picker accepts all file types for restore flexibility
- Debug-only Pro toggle automatically hidden in production builds

## 🔒 Security & Privacy

- Backup files save to user-accessible Downloads folder
- No cloud storage required - user controls where backups are saved
- Encryption keys properly managed across app updates
- Data preservation on disk even if encryption errors occur

## 📋 What's Fixed

**Before this release:**
- Backup dialog showed confusing internal file paths
- Loading spinner didn't dismiss after backup
- Restore couldn't pick JSON files from Downloads
- Subscriptions became lifetime after first payment (revenue leak)
- No tracking of subscription end dates

**After this release:**
- Backup shows Downloads location and file created successfully
- Loading dialogs properly dismiss
- Restore file picker works with any file from Downloads
- Monthly subscriptions expire after 31 days
- Annual subscriptions expire after 366 days
- Lifetime purchases remain lifetime (null expiry)
- Expired subscriptions auto-revoked on app launch

## 📦 Build Information

**Bundle:** `build/app/outputs/bundle/release/app-release.aab`  
**Size:** 47.4 MB  
**Version:** 1.0.15 (Build 32)  
**Min SDK:** Android 24 (7.0)  
**Target SDK:** Android 36 (14.0+)

## 🚀 Deployment Checklist

- [x] Backup/restore tested with real data
- [x] Subscription expiry enforcement tested
- [x] Pro features working correctly
- [x] Debug toggle hidden in production build
- [x] File saves to Downloads successfully
- [x] Loading dialogs dismiss properly
- [x] Code compiles cleanly (no warnings)
- [x] Revenue leakage fixed

## 📖 User-Facing Changes

### In Settings → Import & Export:
- "Create Complete Backup" - Saves JSON file to Downloads
- Success message shows exact file location
- "Restore from Backup" - Pick backup file to restore all data

### Pro Features:
- Purchase flow works correctly
- "Already purchased" shows for lifetime members
- Monthly/annual subscriptions have proper expiry dates
- Expired subscriptions automatically revoked

## 🎯 Testing Priorities

1. **Backup Flow:**
   - Create backup → Check Downloads folder for JSON file
   - File name format: `wealth_dial_backup_2025-11-21T12-34-56.json`
   - Success message shows correct path

2. **Restore Flow:**
   - Pick backup file from Downloads
   - All data restored (accounts, debts, income, settings)
   - Warning dialog appears before restore

3. **Subscription Expiry:**
   - New monthly purchase → Check proExpiryDate is ~31 days from now
   - New annual purchase → Check proExpiryDate is ~366 days from now
   - Lifetime purchase → Check proExpiryDate is null
   - Restart app with expired subscription → Pro access revoked

4. **Pro Features:**
   - Debt Optimizer accessible to Pro users
   - Scenario Engine accessible to Pro users
   - Free users see upgrade prompts

## 📝 Known Limitations

- Server-side purchase verification not implemented (future enhancement)
- Backup file format may change in future versions
- No auto-backup reminders (future enhancement)
- Manual subscription management required

## 🔄 Migration Notes

- Users on v1.0.11-1.0.14: Automatic migration to new schema
- Existing Pro users: Grandfathered with lifetime access (proExpiryDate = null)
- No data loss during upgrade
- Backup/restore compatible with v1.0.11+ data

---

**Build Status:** ✅ Production Ready  
**Flutter Version:** 3.x  
**Dart Version:** >=3.0.0 <4.0.0  
**Tested on:** Samsung Galaxy S23 Ultra (Android 14)
