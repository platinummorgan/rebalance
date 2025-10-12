## Version 1.0.4 "Touch & Feel" - 2025-10-11

### What's New

**♿ Better Accessibility**
Make Rebalance work for everyone with improved screen reader support and clearer button labels.

**📱 Enhanced Touch Experience** 
Feel every tap with haptic feedback and easier-to-press buttons designed for all finger sizes.

**✨ Polish & Refinements**
Smoother interactions and visual improvements throughout the app.

---

**Play Store Release Notes (398 chars):**
```
What's New in v1.0.4 "Touch & Feel":

♿ Better Accessibility
Screen reader support and clearer labels

📱 Enhanced Touch Experience  
Haptic feedback and bigger tap targets

✨ UI Polish
Smoother interactions throughout

Making Rebalance accessible and delightful for everyone!
```

## Version 1.0.3 (build 17) - 2025-10-04

### What's New
- UI & scoring fixes; APR input improvements.

# Release Notes Template

Use this template when publishing updates to Google Play Store.

---

## Version 1.0.0 (Current)

### What's New in This Release

**🎉 Welcome to Rebalance!**

Your complete financial health companion is here. Track net worth, optimize debt payoff, and get personalized guidance—all with 100% privacy.

**Key Features:**
✅ Calculate net worth instantly
✅ Visualize asset allocation across 6 categories
✅ Get A-F financial health score
✅ Smart action cards with specific dollar recommendations
✅ Debt optimizer with avalanche/snowball strategies
✅ Track net worth history with snapshots
✅ 100% local storage—no cloud, no tracking

**What Makes Rebalance Special:**
• No sign-up required—start using immediately
• All data stays on your device
• Zero ads, zero analytics, zero data collection
• Encrypted database for security
• Works completely offline

**Try It Free—No Strings Attached!**

---

## Version 1.0.1 (Template for Next Release)

### What's New

**Bug Fixes:**
• Fixed payment dialog overflow on small screens
• Improved CSV export reliability
• Splash screen logo issue resolved

**Improvements:**
• Optimized debt optimizer performance
• Enhanced health score display
• Better layout on various screen sizes

---

## Version 1.1.0 (Template for Feature Release)

### What's New

**New Features:**
🔔 **Bill Reminders** - Get local notifications for upcoming payments
📄 **PDF Reports** - Export your wealth check as a professional PDF
🎯 **Investment Goals** - Track progress toward financial goals

**Improvements:**
• Faster snapshot creation
• Better debt payoff timeline visualization
• Enhanced action card recommendations

**Bug Fixes:**
• Resolved minor UI issues
• Improved app stability

---

## Tips for Writing Good Release Notes

### ✅ Do:
- **Lead with benefits**: "Track your progress" not "Added tracking feature"
- **Be specific**: "Fixed payment dialog overflow" not "Fixed bugs"
- **Use emojis sparingly**: 🎉 for major features, ✅ for items
- **Keep it short**: 500 characters max for Play Store
- **Group logically**: New features → Improvements → Fixes
- **Show value**: Explain WHY users should care

### ❌ Don't:
- Use technical jargon ("Refactored provider architecture")
- List internal changes users don't see
- Be vague ("Various improvements")
- Write essays (keep it scannable)
- Forget to proofread

---

## Google Play Store Character Limits

- **Title**: 50 characters
- **Short Description**: 80 characters
- **Full Description**: 4000 characters
- **Release Notes**: 500 characters (but aim for 300-400)

---

## Release Notes Best Practices

### Version 1.x.x Format (Recommended)

```
What's New in v1.2.0:

🎉 NEW
• Bill reminders with local notifications
• PDF wealth reports
• Investment goal tracking

✨ IMPROVED
• Faster debt optimizer calculations
• Better small-screen layouts

🐛 FIXED
• CSV export issues
• Payment dialog overflow
```

### Short Format (For Minor Updates)

```
Bug fixes and performance improvements:
• Fixed payment screen overflow
• Improved CSV export reliability
• Enhanced app stability
```

### Feature Release Format

```
🎯 Investment Goals Are Here!

Track progress toward your financial goals with visual progress bars and personalized milestones.

Also in this update:
• Bill reminder notifications
• PDF wealth check reports
• Improved performance
```

---

## When to Release Updates

### Patch (x.x.1)
- Critical bugs affecting many users
- Security fixes
- Small UI improvements
- Release quickly (1-2 days after fix)

### Minor (x.1.x)
- New features
- Significant improvements
- Multiple bug fixes
- Release every 2-4 weeks

### Major (1.x.x)
- Breaking changes
- Complete redesigns
- Major new capabilities
- Release every 3-6+ months

---

## Changelog vs Release Notes

### CHANGELOG.md (Technical, for developers)
- Complete detailed history
- Technical terminology okay
- Include all changes
- Longer explanations
- Lives in repository

### Release Notes (User-facing, for Play Store)
- Short, benefit-focused
- Non-technical language
- Highlight what users care about
- 300-400 characters max
- Lives in Play Console

---

## Example: Converting Changelog → Release Notes

### CHANGELOG.md Entry:
```markdown
## [1.1.0] - 2025-11-15

### Added
- Implemented local notification system using flutter_local_notifications
- Created PDF export functionality using pdf package
- Added investment goals tracking with Drift database schema updates

### Fixed
- Resolved SingleChildScrollView overflow in payment dialog (issue #42)
- Fixed FileSaver async/await blocking UI thread
- Corrected splash screen drawable-v21 resource duplication
```

### Play Store Release Notes:
```
What's New in v1.1.0:

🔔 Bill Reminders
Get notified before payments are due

📄 PDF Reports
Export your wealth check as a PDF

🎯 Investment Goals
Track progress toward your targets

Plus bug fixes and performance improvements.
```

**See the difference?** Users don't care about "flutter_local_notifications" or "issue #42"—they care about what the feature does for them.

---

## Quick Release Checklist

Before submitting to Play Store:

- [ ] Update CHANGELOG.md with technical details
- [ ] Write user-friendly release notes (300-400 chars)
- [ ] Increment version in pubspec.yaml
- [ ] Update version in Settings → About screen
- [ ] Test on multiple devices
- [ ] Take new screenshots if UI changed
- [ ] Build release APK/AAB
- [ ] Sign with release keystore
- [ ] Upload to Play Console
- [ ] Submit for review

---

## Resources

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Google Play Release Notes Guide](https://support.google.com/googleplay/android-developer/answer/7159011)
