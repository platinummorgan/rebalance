# Firebase Analytics Setup Guide

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Project name: **Rebalance** (or "Wealth Dial")
4. Disable Google Analytics for Firebase (we're using Firebase Analytics, not GA)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon to add Android app
2. **Android package name**: `com.wealthdial.app` (check `android/app/build.gradle` to confirm)
3. **App nickname** (optional): Rebalance
4. **Debug signing certificate SHA-1** (optional for now, needed for some features)
5. Click "Register app"

## Step 3: Download google-services.json

1. Download the `google-services.json` file
2. Move it to: `android/app/google-services.json`
3. **DO NOT commit this file to Git!** (already in .gitignore)

## Step 4: Update android/build.gradle

Add this to the `buildscript` dependencies section:

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

## Step 5: Update android/app/build.gradle

Add this at the BOTTOM of the file:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 6: Test Firebase Connection

1. Run the app: `flutter run`
2. Check console for: `[Main] Firebase initialized successfully`
3. In Firebase Console → Analytics → Events → watch for `first_open` event (may take 24-48 hours to show)

## Step 7: Monitor Analytics Dashboard

Firebase Console → Analytics → Dashboard shows:
- **Users**: Daily/monthly active users
- **Events**: Custom events we're tracking:
  - `pro_screen_view` - User views Pro features screen
  - `pro_banner_view` - User sees Pro banner on dashboard
  - `pro_banner_tap` - User taps Pro banner CTA
  - `pro_feature_tap` - User taps a locked Pro feature
  - `upgrade_button_tap` - User taps "Upgrade to Pro"
  - `purchase_flow_start` - Google Play billing opens
  - `purchase_complete` - User completes purchase
  - `purchase_failure` - Purchase fails
  - `retirement_calculator_view` - User views Retirement Calculator
  - `debt_optimizer_view` - User views Debt Optimizer
  - `rebalancing_view` - User views Rebalancing screen

## Key Metrics to Watch

### Pro Conversion Funnel:
1. **Dashboard views** → `pro_banner_view`
2. **Banner taps** → `pro_banner_tap`
3. **Pro screen views** → `pro_screen_view`
4. **Upgrade button taps** → `upgrade_button_tap`
5. **Purchase flow starts** → `purchase_flow_start`
6. **Purchase completions** → `purchase_complete`

### Conversion Rate Formula:
- **Banner → Pro Screen**: `pro_screen_view / pro_banner_view`
- **Pro Screen → Purchase**: `purchase_complete / pro_screen_view`
- **Overall Conversion**: `purchase_complete / unique_users`

### Success Targets:
- Banner → Pro Screen: **10%** (1 in 10 who see banner tap it)
- Pro Screen → Purchase: **2-5%** (industry standard for free trials)
- Overall Conversion: **1-2%** (need 1-2 paying users out of 83 MAU)

## Troubleshooting

### Firebase not initializing:
- Check `google-services.json` is in `android/app/`
- Verify package name matches in Firebase Console and `android/app/build.gradle`
- Rebuild: `flutter clean && flutter pub get && flutter run`

### Events not showing in Firebase:
- Events can take 24-48 hours to appear in Firebase Console
- Use DebugView for real-time testing (requires debug build)
- Check console logs for `[Analytics]` messages

### DebugView not working:
```bash
# Enable debug mode
adb shell setprop debug.firebase.analytics.app com.wealthdial.app

# Disable debug mode
adb shell setprop debug.firebase.analytics.app .none.
```

## Next Steps After Setup

1. **Week 1**: Monitor `pro_banner_view` and `pro_screen_view` counts
   - If <10% of users see banner, it's working
   - If <1% tap banner, messaging needs improvement

2. **Week 2**: Analyze `upgrade_button_tap` vs `purchase_complete`
   - High button taps but low purchases = pricing issue
   - Low button taps = value prop issue

3. **Week 3**: Calculate conversion rates
   - If still 0 conversions with 83 MAU, consider:
     - Price reduction (limited time offer)
     - Extended trial (14 days instead of 7)
     - Different messaging

## Privacy Notes

Firebase Analytics is privacy-focused:
- No personal data collected (no names, emails, etc.)
- Only anonymous usage data
- User can't be personally identified
- Compliant with Google Play policies

For privacy policy, mention:
> "We use Firebase Analytics to improve app quality and understand how users interact with features. No personal information is collected."
