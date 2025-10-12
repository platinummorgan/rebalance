# Google Play In-App Purchase Setup Guide

## Overview
This guide walks you through setting up Google Play in-app purchases for your three pricing tiers:
- **Monthly**: $3.99/month with 7-day free trial
- **Annual**: $23.99/year with 7-day free trial  
- **Founder Lifetime**: $39.99 one-time (limited to first 1,000)

## Prerequisites
- ✅ Google Play Developer account ($25 one-time fee)
- ✅ App uploaded to Google Play Console (at least Internal Testing track)
- ✅ `in_app_purchase` package already in pubspec.yaml

## Step 1: Google Play Console Setup

### A. Create Subscriptions (Monthly & Annual)

1. **Navigate to Products**
   - Open [Google Play Console](https://play.google.com/console)
   - Select your app "Rebalance"
   - Go to: **Monetize → Products → Subscriptions**

2. **Create Monthly Subscription**
   - Click **Create subscription**
   - Fill in details:
     ```
     Product ID: pro_monthly
     Name: Pro Monthly
     Description: Full access to all Pro features with monthly billing
     ```
   - Click **Add base plan**
   - Base plan details:
     ```
     Base plan ID: monthly-standard
     Billing period: 1 month (P1M)
     Price: $3.99 USD
     ```
   - **Add offer** (for free trial):
     ```
     Offer ID: trial-7-days
     Phase 1: Free trial - 7 days (P7D)
     Phase 2: Full price - Recurring
     Eligibility: New customers only
     ```
   - Click **Activate** to make live

3. **Create Annual Subscription**
   - Click **Create subscription**
   - Fill in details:
     ```
     Product ID: pro_annual
     Name: Pro Annual
     Description: Full access to all Pro features - best value
     ```
   - Click **Add base plan**
   - Base plan details:
     ```
     Base plan ID: annual-standard
     Billing period: 1 year (P1Y)
     Price: $23.99 USD
     ```
   - **Add offer** (for free trial):
     ```
     Offer ID: trial-7-days
     Phase 1: Free trial - 7 days (P7D)
     Phase 2: Full price - Recurring
     Eligibility: New customers only
     ```
   - Click **Activate** to make live

### B. Create One-Time Purchase (Lifetime)

1. **Navigate to In-app products**
   - Go to: **Monetize → Products → In-app products**
   
2. **Create Lifetime Product**
   - Click **Create product**
   - Fill in details:
     ```
     Product ID: founder_lifetime
     Name: Founder Lifetime
     Description: Lifetime access to all Pro features - limited offer
     Status: Active
     Price: $39.99 USD
     ```
   - Click **Save** and **Activate**

### C. Set Up Testing

1. **Add License Testers**
   - Go to: **Monetize → Setup → License testing**
   - Click **Add license testers**
   - Add your Gmail address (the one you use on your test device)
   - Set response: **RESPOND_NORMALLY**
   - Click **Save changes**

2. **Create Internal Testing Track** (if not already done)
   - Go to: **Testing → Internal testing**
   - Upload your signed APK
   - Add yourself as a tester
   - Accept the testing invitation on your device

## Step 2: Test Purchases

### Before Testing
- ✅ App must be uploaded to at least Internal Testing track
- ✅ Products must be **Activated** in Play Console
- ✅ Your email must be added to License Testers
- ✅ Wait 2-4 hours after creating products (Google needs to sync)
- ✅ Sign in to device with the test Gmail account

### Testing Workflow
1. **Install from Internal Testing**
   - Open the testing link on your device
   - Install the app from Google Play
   - DO NOT install via sideloading APK (IAP won't work)

2. **Test Each Purchase Flow**
   - Tap "Start Free Trial" (monthly)
   - Should see Google Play payment dialog
   - Because you're a tester, you won't be charged
   - Complete the "purchase"
   - App should unlock Pro features

3. **Verify Pro Access**
   - Check that Pro features are unlocked
   - Check Settings to see `isPro = true`
   - Try accessing Pro screens (Rebalancing, Tax, Debt, etc.)

4. **Test Restoration** (Important!)
   - Clear app data or reinstall
   - Tap "Restore Purchases" in Pro screen
   - Pro access should be restored automatically

## Step 3: Production Launch

### Before Going Live
- [ ] Test all three purchase options (Monthly, Annual, Lifetime)
- [ ] Test free trial flow (7 days)
- [ ] Test purchase restoration
- [ ] Test on multiple devices if possible
- [ ] Verify products show correct prices
- [ ] Check that "Founder Lifetime" shows as limited

### Going Live
1. **Move to Production Track**
   - Upload signed release APK
   - Complete Store Listing
   - Submit for review

2. **Products Are Automatically Live**
   - Once app is approved, subscriptions/products go live
   - No separate activation needed
   - Users can immediately purchase

## Step 4: Monitor & Manage

### View Subscription Analytics
- **Google Play Console → Monetize → Subscriptions**
- See active subscribers, revenue, churn rate
- Track which plan is most popular

### Handle Customer Issues
- **Order Management**: Refund purchases if needed
- **Subscription Management**: Cancel/manage user subscriptions
- **Purchase History**: View all transactions

### Important Policies
- ✅ 7-day free trial on subscriptions (pro-consumer)
- ✅ Users can cancel anytime (required by Google)
- ✅ No hidden fees or charges
- ✅ Clear pricing display (✅ already done)
- ✅ Restore purchases button (TODO: add to Pro screen)

## Troubleshooting

### "Product not found" Error
- Wait 2-4 hours after creating products
- Verify Product IDs match exactly in code:
  ```dart
  pro_monthly
  pro_annual
  founder_lifetime
  ```
- Check products are **Activated** in Play Console

### Purchases Not Working
- Must install from Google Play (not sideload)
- Must be signed in with test account
- Must be on Internal Testing track or higher
- App version code must match uploaded version

### Test Purchases Are Charging Me
- Verify email is in License Testers
- Set response to RESPOND_NORMALLY
- Wait 5-10 minutes after adding email

### Pro Not Unlocking After Purchase
- Check `purchaseStream` is being listened to
- Verify `_grantProAccess()` is being called
- Check Settings.isPro is being set to true
- Look for errors in console logs

## Implementation Status

### ✅ Completed
- [x] `in_app_purchase` package added to pubspec
- [x] PurchaseService created (`lib/services/purchase_service.dart`)
- [x] Settings model has `isPro` field
- [x] Pro screen shows correct pricing

### ⏳ TODO (Next Steps)
- [ ] Wire up purchase buttons in Pro screen
- [ ] Add "Restore Purchases" button
- [ ] Initialize PurchaseService in main.dart
- [ ] Test purchase flow on device
- [ ] Add loading states during purchase
- [ ] Add error handling for failed purchases

## Code Integration

### Initialize in main.dart
```dart
// In main() before runApp()
final container = ProviderContainer();
final purchaseService = container.read(purchaseServiceProvider);
await purchaseService.initialize(container);
```

### Update Pro Screen Buttons
```dart
// In _buildPricingCard onPressed
final purchaseService = ref.read(purchaseServiceProvider);
final products = await purchaseService.loadProducts();

// Find the product
final product = products.firstWhere(
  (p) => p.id == 'pro_monthly', // or pro_annual, founder_lifetime
);

// Initiate purchase
await purchaseService.purchaseProduct(product);
```

### Add Restore Purchases
```dart
// Add button in Pro screen
FilledButton.icon(
  onPressed: () async {
    final purchaseService = ref.read(purchaseServiceProvider);
    await purchaseService.restorePurchases(ref);
  },
  icon: Icon(Icons.restore),
  label: Text('Restore Purchases'),
)
```

## Revenue Expectations

### First 1,000 Founders
- If all 1,000 buy Lifetime: **$39,990**
- More realistic (30% conversion): **$11,997**

### After Launch (Monthly)
- 10,000 downloads
- 5% convert to Monthly: 500 × $3.99 = **$1,995/month**
- 2% upgrade to Annual: 200 × $23.99 = **$4,798/month**
- Annual run rate: ~**$80,000/year**

### Google Play Fees
- Google takes 15% first $1M (30% after)
- First year (under $1M): You keep **85%**

## Support Resources

- [Google Play Billing Docs](https://developer.android.com/google/play/billing)
- [in_app_purchase Package](https://pub.dev/packages/in_app_purchase)
- [Play Console Help](https://support.google.com/googleplay/android-developer)

---

**Next Steps**: Upload app to Internal Testing track, create products in Play Console, then test!
