# Google Play Store Launch - Complete Setup Guide

## 🎯 Mission: Get Rebalance v1.0.0 Live on Google Play

**Date**: October 2, 2025  
**App Name**: Rebalance  
**Package**: com.wealthdial.app  
**Version**: 1.0.0 (Build 1)

---

## Phase 1: Create Google Play Developer Account (30 minutes)

### Step 1: Sign Up
1. Go to [Google Play Console](https://play.google.com/console/signup)
2. Use your Gmail account
3. **Pay $25 registration fee** (one-time, lifetime access)
4. Accept Developer Agreement
5. Complete profile:
   - Developer name: (Your name or "Rebalance")
   - Email address
   - Website: (optional - can add later)
   - Phone number

### Step 2: Set Up Payment Profile
1. In Play Console → **Setup → Identity**
2. Choose account type:
   - **Individual** (simpler, faster) OR
   - **Organization** (if you have LLC)
3. Enter tax information (US: W-9 form)
4. Add payment method for receiving revenue
5. Verify identity (may require ID upload)

**⏰ Processing Time**: Identity verification can take 1-3 days

---

## Phase 2: Create Signing Key (15 minutes)

### Why You Need This
Google requires signed APKs. The signing key proves you're the legitimate developer.

### Step 1: Create Keystore File

Open PowerShell and run:

```powershell
cd D:\Dev\wealth_dial

# Create keystore (answer all prompts)
keytool -genkey -v -keystore rebalance-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rebalance
```

**Prompts you'll see**:
```
Enter keystore password: [CREATE STRONG PASSWORD]
Re-enter password: [REPEAT]
What is your first and last name? [Your name]
What is the name of your organizational unit? [Your name or "Rebalance"]
What is the name of your organization? [Your name or "Rebalance"]
What is the name of your City or Locality? [Your city]
What is the name of your State or Province? [Your state]
What is the two-letter country code? [US]
Is CN=... correct? [yes]
```

**CRITICAL**: Store these securely:
```
Keystore Password: _______________
Key Password: _______________
Alias: rebalance
File Location: D:\Dev\wealth_dial\rebalance-release-key.jks
```

### Step 2: Create key.properties File

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=rebalance
storeFile=D:/Dev/wealth_dial/rebalance-release-key.jks
```

**⚠️ IMPORTANT**: Add to `.gitignore`:
```
# In .gitignore
android/key.properties
*.jks
```

### Step 3: Update android/app/build.gradle

Find the `android {` block and add BEFORE it:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Inside `android { buildTypes {` block, replace `release {` section:

```gradle
release {
    signingConfig signingConfigs.release
    minifyEnabled true
    shrinkResources true
}
```

Add BEFORE `buildTypes {`:

```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
```

---

## Phase 3: Build Release APK (5 minutes)

### Step 1: Clean Build
```powershell
cd D:\Dev\wealth_dial
flutter clean
flutter pub get
```

### Step 2: Build Release APK
```powershell
flutter build apk --release
```

**Expected output**:
```
√ Built build/app/outputs/flutter-apk/app-release.apk (XX MB)
```

### Step 3: Verify Signing
```powershell
cd build\app\outputs\flutter-apk
keytool -printcert -jarfile app-release.apk
```

Should show your certificate details.

**📦 Your release APK is at**: `build/app/outputs/flutter-apk/app-release.apk`

---

## Phase 4: Create App in Play Console (45 minutes)

### Step 1: Create New App
1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in details:
   - **App name**: Rebalance
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
   - **Declarations**: Check all boxes
4. Click **Create app**

### Step 2: Set Up Store Listing

**Go to: Grow → Store presence → Main store listing**

#### App Details
```
App name: Rebalance
Short description (80 chars):
Privacy-first portfolio tracker with smart rebalancing and health scores

Full description (4000 chars max):
Rebalance is your personal financial health assistant that makes portfolio management simple and actionable.

✨ KEY FEATURES

📊 Financial Health Score
Get a simple 0-100 score that tells you exactly how healthy your finances are. Track net worth, debt load, liquidity, concentration risk, and portfolio balance.

🎯 Smart Rebalancing
Never guess what to do next. Get specific trade instructions to optimize your portfolio based on your risk profile (Conservative, Balanced, or Growth).

💰 Debt Optimizer (Pro)
Find the fastest path to debt freedom. See exactly how much interest you'll save with avalanche vs snowball strategies.

🔮 What-If Scenarios (Pro)
Model your retirement with Monte Carlo simulations. See probability of success and compare different contribution strategies.

🚨 Custom Alerts (Pro)
Get notified when your portfolio drifts, concentration risk increases, or debt payments are due.

🔒 PRIVACY FIRST
• 100% local storage - Your data never leaves your device
• No cloud sync, no data collection, no ads
• End-to-end encrypted storage
• No account required

💎 FREE FEATURES
• Financial health score
• Net worth tracking
• Debt load calculator
• Snapshot history
• CSV export
• Basic rebalancing guidance

🌟 PRO FEATURES ($3.99/month or $23.99/year)
• Interactive rebalancing plans
• Debt payoff optimizer
• What-If scenario engine
• Custom alerts with context
• Tax-smart asset allocation

Perfect for investors who want clear, actionable guidance without overwhelming complexity.

Download now and take control of your financial health! 🚀
```

#### Graphics Assets

**App icon** (512x512):
- Already in: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- Upload the 512x512 version

**Feature graphic** (1024x500) - REQUIRED:
Create in Canva or Photoshop:
- Background: Green gradient (#43A047 to #66BB6A)
- Text: "Rebalance" (large, white, bold)
- Subtext: "Your Financial Health Assistant"
- Maybe include: Health score circle (70) or chart icon

**Screenshots** (2-8 required, 16:9 or 9:16 ratio):
Take screenshots from your app:
1. Dashboard with health score
2. Net worth tracker
3. Rebalancing plan
4. Compare snapshots
5. Pro features screen

**Upload to**: Phone (required), Tablet (optional)

#### Categorization
- **App category**: Finance
- **Tags**: personal finance, budgeting, investing, portfolio
- **Email**: your.email@gmail.com
- **Phone**: (optional)
- **Website**: (optional - can add later)

#### Privacy Policy
**REQUIRED** - Create at: https://app-privacy-policy-generator.firebaseapp.com/

Or use this template:
```
Privacy Policy for Rebalance

Last updated: October 2, 2025

Rebalance is committed to protecting your privacy. 

DATA COLLECTION
We do NOT collect, store, or transmit any personal or financial data. All information is stored locally on your device using encrypted storage.

DATA STORAGE
• All financial data is stored locally on your device
• Data is encrypted using industry-standard encryption
• No cloud backup or sync
• Data is deleted when you uninstall the app

THIRD PARTY SERVICES
We use:
• Google Play Billing for in-app purchases
• No analytics services
• No advertising networks
• No data sharing with third parties

YOUR RIGHTS
• Your data never leaves your device
• You can export your data as CSV
• You can delete all data by clearing app data or uninstalling

CONTACT
Email: your.email@gmail.com

This policy may be updated. Changes will be posted here.
```

Host on: GitHub Pages (free) or paste directly in Play Console

### Step 3: Content Rating
**Go to: Policy → App content → Content rating**

1. Click **Start questionnaire**
2. Enter email
3. Category: **Utility, Productivity**
4. Answer questions (all "No" for violence, etc.)
5. Save → Get rating (should be "Everyone")

### Step 4: Target Audience
**Go to: Policy → App content → Target audience**

- **Target age**: 18+
- **Appeal to children**: No

### Step 5: Data Safety
**Go to: Policy → App content → Data safety**

```
Data Collection: NO (all toggles off)
Data Sharing: NO
Security Practices: YES
  - Encryption in transit: NO (local only)
  - Encryption at rest: YES
  - User can request deletion: YES (uninstall)
  - Committed to follow Google Play Families Policy: N/A
```

### Step 6: Government Apps & Ads
**Go to: Policy → App content**

- **Government app**: No
- **Ads**: No
- **App access**: All features available to all users

---

## Phase 5: Upload APK (Internal Testing) (15 minutes)

### Step 1: Create Internal Testing Track
**Go to: Testing → Internal testing**

1. Click **Create new release**
2. Upload `app-release.apk`
3. Release name: `v1.0.0 Initial Release`
4. Release notes:
```
Initial release of Rebalance v1.0.0

Features:
• Financial Health Score (0-100)
• Net worth tracking
• Smart rebalancing guidance
• Debt load calculator
• Snapshot history & CSV export
• Pro features: Rebalancing plans, debt optimizer, scenarios, alerts
```

5. Click **Save** → **Review release** → **Start rollout to Internal testing**

### Step 2: Add Yourself as Tester
1. In **Internal testing**, click **Testers** tab
2. Create email list: `internal-testers`
3. Add your Gmail
4. Save
5. Copy the **opt-in URL** (send to yourself)

### Step 3: Test on Device
1. Open opt-in URL on your phone
2. Click **Become a tester**
3. Download from Play Store
4. **Test thoroughly**:
   - [ ] All free features work
   - [ ] Pro features show paywall
   - [ ] CSV exports work
   - [ ] No crashes
   - [ ] Data persists across restarts

---

## Phase 6: Set Up In-App Products (30 minutes)

**Go to: Monetize → Products**

### Create Subscriptions

#### Product 1: Monthly
- **Product ID**: `pro_monthly`
- **Name**: Pro Monthly
- **Description**: Monthly Pro subscription with all features
- **Base plans**:
  - **ID**: monthly-standard
  - **Billing period**: Every 1 month (P1M)
  - **Price**: $3.99 USD
  - **Free trial**: 7 days
  - **Grace period**: 3 days
- **Status**: Active

#### Product 2: Annual
- **Product ID**: `pro_annual`
- **Name**: Pro Annual
- **Description**: Annual Pro subscription - best value
- **Base plans**:
  - **ID**: annual-standard
  - **Billing period**: Every 1 year (P1Y)
  - **Price**: $23.99 USD
  - **Free trial**: 7 days
  - **Grace period**: 3 days
- **Status**: Active

### Create One-Time Purchase

#### Product 3: Lifetime
- **Go to**: Monetize → Products → **In-app products**
- Click **Create product**
- **Product ID**: `founder_lifetime`
- **Name**: Founder Lifetime
- **Description**: Lifetime Pro access - limited offer
- **Price**: $39.99 USD
- **Status**: Active

### Set Up License Testing
**Go to: Monetize → Setup → License testing**

1. Add your Gmail
2. Set response: **RESPOND_NORMALLY**
3. Test mode: **Allow test purchases**

**⏰ Wait 2-4 hours** for products to sync before testing!

---

## Phase 7: Production Release (After Testing) (20 minutes)

### When You're Ready
1. Test everything in Internal Testing
2. Fix any bugs
3. Upload new APK to Internal Testing if needed
4. When confident:

**Go to: Release → Production**

1. Click **Create new release**
2. Upload `app-release.apk` (same one from internal testing)
3. Release notes (copy from internal testing)
4. **Countries**: Select all or start with US/Canada/UK/Australia
5. **Rollout percentage**: Start with 100% (or 10% for cautious rollout)
6. Click **Review release**
7. Fix any errors (if any)
8. Click **Start rollout to Production**

### Google Review Process
- **Time**: 1-3 days (usually ~24 hours)
- **Status**: Check in Play Console → Dashboard
- **Possible outcomes**:
  - ✅ Approved → Live on Play Store!
  - ⚠️ Needs changes → Fix issues and resubmit
  - ❌ Rejected → Appeal or fix violations

---

## Phase 8: Launch Day! 🎉

### When App Goes Live

1. **Verify it's live**:
   - Search "Rebalance" in Play Store
   - Or use direct link: `https://play.google.com/store/apps/details?id=com.wealthdial.app`

2. **Share the link**:
   - Friends/family
   - Reddit (r/personalfinance)
   - Twitter/X
   - LinkedIn

3. **Monitor**:
   - Play Console → Dashboard for installs
   - Crashes & ANRs (Application Not Responding)
   - Ratings & reviews

4. **Respond to reviews**:
   - Thank positive reviews
   - Fix issues in negative reviews

---

## Quick Reference Commands

```powershell
# Clean and build release
cd D:\Dev\wealth_dial
flutter clean
flutter pub get
flutter build apk --release

# Release APK location
build\app\outputs\flutter-apk\app-release.apk

# Verify signing
cd build\app\outputs\flutter-apk
keytool -printcert -jarfile app-release.apk
```

---

## Checklist Before Going Live

- [ ] Tested app thoroughly on physical device
- [ ] CSV exports work (Downloads folder)
- [ ] Pro features require payment
- [ ] No debug code or logs
- [ ] Privacy policy published
- [ ] Screenshots look professional
- [ ] Store listing has no typos
- [ ] Content rating completed
- [ ] Data safety form completed
- [ ] Internal testing successful (no crashes)
- [ ] In-app products created (monthly, annual, lifetime)
- [ ] License testing configured
- [ ] Release APK signed correctly

---

## Post-Launch Todo

**Week 1**:
- [ ] Monitor crashes daily
- [ ] Respond to all reviews
- [ ] Share on social media
- [ ] Post to r/personalfinance, r/investing

**Week 2-4**:
- [ ] Analyze user behavior (installs, retention)
- [ ] Implement user-requested features
- [ ] Plan v1.1 with improvements

**Month 2**:
- [ ] Submit to Amazon Appstore (easy, free)
- [ ] Create demo videos for YouTube
- [ ] Email finance bloggers for reviews

---

## Emergency Contacts

- **Play Console Support**: https://support.google.com/googleplay/android-developer
- **Play Console**: https://play.google.com/console
- **Developer Policies**: https://play.google.com/about/developer-content-policy/

---

**Good luck with your launch! 🚀**

You've built something genuinely useful. Now get it out there!
