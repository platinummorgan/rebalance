# Purchase Failure Diagnosis Guide

## Current Situation
- **10 purchase failures** from **3 users** (3.3 failures/user avg)
- Spike on Nov 2, 2025
- Users are trying to buy but failing

## How to Diagnose the Root Cause

### Step 1: Check Firebase Analytics for Error Details

1. Go to your Firebase Analytics dashboard
2. Click on **purchase_failure** event
3. Look at the **Parameters** (custom dimensions):
   - `plan_type` - which plan failed (monthly/annual/lifetime)
   - `error_message` - the specific error message
   - `timestamp` - when it happened

4. **In Firebase Console**: 
   - Analytics → Events → purchase_failure → View Event Parameters
   - Look for patterns in `error_message` field

### Step 2: Run Live Device Logs

Connect device via ADB and watch logs in real-time:

```powershell
# Filter for purchase-related logs
adb logcat | Select-String -Pattern "Purchase|ProScreen|PurchaseService|Analytics"

# More focused - just errors
adb logcat | Select-String -Pattern "PURCHASE ERROR|Purchase error|purchase_failure"
```

Then trigger a purchase on device and watch what happens.

### Step 3: Check Enhanced Error Logging (Just Added)

I've enhanced `purchase_service.dart` to log:
- Error code
- Error message
- Error details
- Product ID
- Purchase ID
- Transaction date

After rebuilding, these will appear in logs and Firebase.

### Step 4: Common Purchase Failure Causes

#### 1. Products Not Found in Play Store
**Error**: "Product not found" or notFoundIDs in logs
**Fix**: 
- Products must be created in Google Play Console
- Wait 2-4 hours for Google to sync
- Product IDs must match exactly: `pro_monthly`, `pro_annual`, `founder_lifetime`

#### 2. App Not Installed from Play Store
**Error**: "Billing not available" or connection issues
**Fix**: 
- App MUST be installed from Play Store (Internal Testing track)
- Sideloaded APKs (adb install) won't work with real purchases
- Users need Play Store version

#### 3. Region/Payment Method Issues
**Error**: Various billing errors
**Potential Fix**: 
- Some countries/regions have restrictions
- Hindi/Bengali/Arabic/Persian users may have different payment options
- Check if failures correlate with specific regions

#### 4. Network/Timeout Issues
**Error**: TimeoutException, connection errors
**Fix**: 
- Poor internet during purchase
- Already handling with 10-second timeout
- User should retry

#### 5. Products Not Active in Play Console
**Error**: Product not available
**Fix**: 
- Go to Play Console → Monetize → Products
- Ensure all products are "Active" status
- Check subscription settings are correct

#### 6. User Cancels Purchase
**Error**: "Purchase cancelled by user"
**Note**: This is normal, not a bug

### Step 5: Check Your Play Console

1. **Go to Play Console** → Your App → Monetize → Products
2. Verify all 3 products exist and are **Active**:
   - `pro_monthly` - $3.99/month subscription
   - `pro_annual` - $23.99/year subscription  
   - `founder_lifetime` - $39.99 one-time

3. Check **Order Management** for failed transactions:
   - Play Console → Order Management
   - Look for incomplete/failed orders
   - Note any error codes

### Step 6: Test Purchase Flow Yourself

1. Add yourself as a **License Tester** in Play Console
2. Install app from Internal Testing
3. Try to purchase
4. Watch device logs with `adb logcat`
5. Note exact error message

## Next Steps

### Immediate Action:
1. ✅ Build new APK with enhanced error logging (I just added it)
2. Check Firebase Analytics parameters for existing failures
3. Run device logs during test purchase
4. Verify products are active in Play Console

### After Diagnosis:
Based on what you find, we can:
- Fix product configuration issues
- Add user-friendly error messages
- Handle region-specific payment issues
- Add retry logic for network failures
- Display troubleshooting help in-app

## Build Command

```powershell
# Build debug APK with new logging
flutter build apk --debug

# Install to device
adb install -r build\app\outputs\flutter-apk\app-debug.apk

# Watch logs during purchase
adb logcat | Select-String -Pattern "❌ PURCHASE ERROR|Purchase"
```

## What's Different Now

The enhanced `purchase_service.dart` now logs:
```
❌ PURCHASE ERROR DETAILS:
  Product ID: pro_monthly
  Error Code: USER_CANCELED
  Error Message: User pressed back or canceled a dialog
  Error Details: {...}
  Purchase ID: GPA.1234...
  Transaction Date: 2025-11-09...
```

This will help identify if it's:
- User cancellations (normal)
- Network issues (retry logic needed)
- Product setup problems (Play Console fix)
- Regional restrictions (need workarounds)

---

**Let me know what you find in Firebase Analytics parameters and device logs!**
