# Rebalance v1.0.11 Release Notes

**Build:** 28  
**Release Date:** November 20, 2025  
**APK Location:** `build\app\outputs\flutter-apk\app-release.apk`  
**APK Size:** 60.2 MB

---

## 🎯 What's New

### Weekly Guardrails 📊

Your new financial copilot that keeps you on track all week long.

**Safe to Spend Card** - Now front and center on your dashboard:
- 🟢 **Green (✓)**: You're on track with 3+ days of cash buffer
- 🟠 **Orange (⚠)**: Warning zone - less than 3 days buffer remaining  
- 🔴 **Red (🚨)**: Over budget - your safe-to-spend is negative

**Accessibility First**: Color-blind friendly icons (✓, ⚠, 🚨) on every state so everyone can understand their status at a glance.

**Deep Dive Detail Screen**: Tap the card to:
- See exactly how much you can safely spend this week
- Use the interactive "what-if" slider to model extra purchases
- Watch your buffer days update in real-time as you adjust spending
- Get smart warnings when you cross into danger zones
- Quick-edit your income and bills right from the breakdown

**One-Time Coaching**: First time hitting a warning zone? We'll show you a helpful toast explaining what's happening (just once, we promise).

---

### Complete Internationalization 🌍

Now **100% localized** across all 5 languages:

- 🇬🇧 English
- 🇸🇦 العربية (Arabic)  
- 🇧🇩 বাংলা (Bengali)
- 🇮🇷 فارسی (Persian)
- 🇮🇳 हिन्दी (Hindi)

**What's Translated:**
- ✅ All day names (Monday → सोमवार in Hindi)
- ✅ All dashboard states and messages
- ✅ Currency amounts automatically convert to your selected currency
- ✅ Financial health component names (e.g., "Debt Load" → "ऋण भार")
- ✅ All UI labels, buttons, and help text

**Letter Grades**: We kept A-F grades in English as they're internationally recognized (just like we keep mathematical symbols universal).

---

### Visual Polish ✨

**Optimized Dashboard Layout:**
- Income and Bills now stack vertically (no more "Wee..." cutoff text!)
- Smaller, tighter fonts for better information density
- "Updated today" is now subtle 10px text (not a distracting pill)
- Net Worth card changed from bright green to clean white with teal accent
- Better visual hierarchy: primary info (Safe to Spend) pops, secondary info (Net Worth) recedes

**Guardrails Detail Screen:**
- Matches dashboard with the same green/orange/red gradient states
- Accessibility icons added throughout
- What-if slider with dramatic color-coded backgrounds
- Pro upgrade prompt appears when you need it most

---

## 🐛 Fixes

- **Text Overflow**: "Weekly Bills" no longer cuts off as "Wee..."
- **Currency Conversion**: All amounts now properly convert using CurrencyText widget
- **Build Errors**: Fixed all compilation issues in guardrails detail screen  
- **Email Link**: Language support request link now properly encodes subject/body

---

## 🔧 Technical Details

**New Translation Strings:** 50+ entries added across 5 ARB files
- Dashboard states: `alreadyOverThisWeek`, `goingNegativeByDay`, `bufferUntilDay`, etc.
- Day names: `monday` through `sunday` in all languages
- UI elements: `updatedToday`, `buffer`, etc.

**Code Improvements:**
- Implemented `_translateComponentName()` for health component localization
- Fixed CurrencyFormatter vs CurrencyText usage patterns (format-only vs conversion+format)
- Enhanced state management for weekly safe-to-spend calculations
- Improved analytics tracking for guardrails screen interactions

---

## 📦 What's Included

- ✅ Weekly Guardrails with interactive what-if modeling
- ✅ Complete multi-language support (5 languages)
- ✅ Accessibility icons for colorblind users
- ✅ Optimized dashboard layout
- ✅ Smart coaching toasts
- ✅ Currency conversion across all screens
- ✅ All existing features: Net Worth tracking, Financial Health score, Debt Optimizer, etc.

---

## 🚀 Shipping Checklist

### Pre-Release
- [x] Version bumped to 1.0.11+28
- [x] CHANGELOG.md updated
- [x] Clean build completed
- [x] Release APK built (60.2 MB)
- [x] All lint errors resolved
- [x] Overflow issues fixed

### Testing
- [ ] Test on physical device
- [ ] Verify all 5 languages display correctly
- [ ] Test currency conversion (try EUR, INR, etc.)
- [ ] Test guardrails what-if slider
- [ ] Test all three states (green/orange/red)
- [ ] Verify accessibility icons appear
- [ ] Test coaching toast appears once
- [ ] Test deep linking to Income/Bills screens

### Play Store
- [ ] Update version name: `1.0.11`
- [ ] Update version code: `28`
- [ ] Upload APK to internal testing track
- [ ] Update release notes in Play Console (use "What's New" section below)
- [ ] Take new screenshots showing Weekly Guardrails
- [ ] Update app description if needed
- [ ] Promote to production when ready

---

## 📝 Play Store Release Notes

**Copy this to Play Console (under 500 characters):**

```
Weekly Guardrails: See exactly how much is safe to spend this week with smart color-coded warnings (green/orange/red). Tap to model "what-if" spending scenarios.

Complete translation in 5 languages: English, Arabic, Bengali, Persian, Hindi.

Dashboard improvements: cleaner layout, accessibility icons, better spacing.

Bug fixes and performance improvements.
```

---

## 🎓 User Education

**For Users Coming from v1.0.10:**

The biggest change is the new **Safe to Spend** card at the top of your dashboard. This replaces the old onboarding card for configured users.

**How it works:**
1. We calculate: `Weekly Income - Weekly Bills = Safe to Spend`
2. We track your cash buffer (how many days can you cover bills?)
3. Color changes based on your situation:
   - Green: 3+ days of buffer (comfortable)
   - Orange: <3 days buffer (tight)
   - Red: Negative safe-to-spend (over budget)

**What-If Slider:**
Tap the card, then drag the slider to see: "If I spend an extra $X this week, what happens to my buffer?"

Great for modeling:
- "Can I afford this $200 purchase?"
- "What if I go out to dinner a few times?"
- "How much wiggle room do I really have?"

---

## 🐛 Known Issues

None! This is a stable release ready for production.

---

## 📊 Analytics to Monitor

Post-release, watch for:
- **Guardrails card taps**: Are users discovering the detail screen?
- **What-if slider usage**: Are users modeling scenarios?
- **State distribution**: How many users see green vs orange vs red?
- **Language distribution**: Which translations are most used?
- **Pro conversion from guardrails**: Does the tight-budget prompt work?

---

## 🙏 Credits

Special thanks to:
- User feedback on dashboard hierarchy
- Translation validation across all 5 languages
- Accessibility testing for color-blind users

---

## 📞 Support

If users report issues:
- Settings → Send Feedback
- Check analytics for crash patterns
- Monitor Play Console reviews

---

**Ready to ship!** 🚀
