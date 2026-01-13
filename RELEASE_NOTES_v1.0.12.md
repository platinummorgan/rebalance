# Release Notes - v1.0.12 (Build 29)

**Release Date:** November 21, 2025

## 🔒 Critical Revenue Protection Fixes

### Subscription Lifecycle Management
- **Fixed revenue leakage:** Subscriptions now properly expire after their billing period
- **Expiry enforcement:** App validates subscription status on startup and revokes expired Pro access
- **Renewal handling:** Subscription renewals now extend from the later of current expiry or now (prevents time loss)
- **Persistent tracking:** Expiry dates stored in Hive database, survive app restarts

### Purchase Flow Improvements
- **Cancellation tracking:** User cancellations during billing flow now logged to Firebase Analytics
- **Improved error handling:** Better purchase failure diagnostics
- **Grandfathering:** Existing Pro users automatically receive lifetime access (no expiry)

## 🛠️ Technical Improvements

### Data Persistence
- **Hive schema update:** Added `proExpiryDate` field to Settings model (field 29)
- **Migration safety:** Existing users seamlessly upgraded with null expiry (lifetime)

### Play Billing Compatibility
- **Package update:** Using in_app_purchase 3.2.3 (pending purchases enabled by default)
- **Removed deprecated calls:** Cleaned up obsolete `enablePendingPurchases()` API usage

### Code Quality
- **Removed duplicate logic:** Cleaned up purchase cancellation handling
- **Enhanced validation:** Tighter expiry checks with proper revocation flow

## 📋 What's Fixed

**Before this release:**
- Monthly/annual subscriptions became lifetime after first payment (90%+ revenue loss)
- No tracking of subscription end dates
- User cancellations invisible in analytics
- Subscription renewals didn't extend properly

**After this release:**
- Monthly subscriptions expire after 31 days
- Annual subscriptions expire after 366 days  
- Lifetime purchases remain lifetime (null expiry)
- Expired subscriptions automatically revoked on app launch
- All cancellations logged for funnel analysis
- Renewals properly extend subscription period

## 🧪 Testing Performed

- ✅ Subscription expiry calculation (monthly = 31d, annual = 366d)
- ✅ Expiry validation on app boot (hasActiveSubscription)
- ✅ Auto-revocation of expired subscriptions
- ✅ Renewal extends from max(now, currentExpiry)
- ✅ Cancellation analytics logging
- ✅ Hive persistence of proExpiryDate
- ✅ Grandfathering existing Pro users

## 📦 Build Information

**File:** `build/app/outputs/bundle/release/app-release.aab`  
**Size:** 47.4 MB  
**Version:** 1.0.12+29  
**Min SDK:** Android 24 (7.0)

## 🚀 Deployment Notes

**Important:**
- Existing Pro users will be grandfathered with lifetime access
- New purchases after this update will have proper expiry tracking
- Server-side purchase verification recommended for production (see IAP_FIXES_CRITICAL.md)

**Analytics Events:**
- `purchase_cancel` - now properly tracked
- `purchase_success` - continues to track completed purchases
- `purchase_failure` - enhanced error diagnostics

## 📖 Documentation

See `IAP_FIXES_CRITICAL.md` for detailed technical analysis and testing checklist.

---

**Build Status:** ✅ Success  
**Flutter Version:** 3.x  
**Kotlin Version:** Compatible  
**ProGuard:** Enabled
