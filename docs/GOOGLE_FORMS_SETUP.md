# Google Forms Setup Guide

## Overview
This guide will help you create two Google Forms for user feedback and bug reports in the Rebalance app.

---

## 1. Create Feedback Form

### Step 1: Go to Google Forms
1. Open https://forms.google.com
2. Click the **+ Blank** form or use a template

### Step 2: Form Title & Description
- **Title**: Rebalance App Feedback
- **Description**: "Help us improve Rebalance! Share your thoughts, suggestions, and what you love about the app."

### Step 3: Add Questions

**Question 1: Email (Optional)**
- Type: Short answer
- Question: "Email address (optional, if you'd like a response)"
- Toggle OFF "Required"

**Question 2: Feedback Type**
- Type: Multiple choice
- Question: "What type of feedback is this?"
- Options:
  - Feature request
  - General feedback
  - Compliment
  - Design/UI suggestion
  - Other

**Question 3: Your Feedback**
- Type: Paragraph
- Question: "Tell us your thoughts"
- Toggle ON "Required"
- Description: "Please provide as much detail as possible"

### Step 4: Settings
1. Click the **Settings** gear icon (top right)
2. **General tab**:
   - ✅ Collect email addresses: OFF (already optional in form)
   - ✅ Limit to 1 response: OFF
   - ✅ Edit after submit: OFF
3. **Presentation tab**:
   - ✅ Show progress bar: ON
   - Confirmation message: "Thank you! Your feedback helps us make Rebalance better. 🎯"

### Step 5: Get Shareable Link
1. Look at the top of your form - you should see a URL/link (it might say "Responder link" or just show the URL)
2. Click on the link or look for a **"Shorten URL"** option nearby
3. If you see a "Shorten URL" checkbox, enable it to get a shorter `forms.gle/` link
4. Copy the URL (e.g., `https://forms.gle/abc123xyz`)
5. **Paste this URL** into `lib/routes.dart` line 460:
   ```dart
   const String feedbackFormUrl = 'https://forms.gle/YOUR_FEEDBACK_FORM_ID';
   ```

---

## 2. Create Bug Report Form

### Step 1: Create New Form
1. Go back to https://forms.google.com
2. Click **+ Blank** form

### Step 2: Form Title & Description
- **Title**: Rebalance Bug Report
- **Description**: "Found a bug? Help us fix it by providing details below. We appreciate your help! 🐛"

### Step 3: Add Questions

**Question 1: Email (Optional)**
- Type: Short answer
- Question: "Email address (optional, for follow-up)"
- Toggle OFF "Required"

**Question 2: What happened?**
- Type: Paragraph
- Question: "Describe the bug"
- Toggle ON "Required"
- Description: "What went wrong? Be as specific as possible."

**Question 3: Steps to Reproduce**
- Type: Paragraph
- Question: "How can we reproduce this bug?"
- Toggle ON "Required"
- Description: "Step 1: I did this...\nStep 2: Then I did this...\nStep 3: Bug occurred"

**Question 4: Expected Behavior**
- Type: Paragraph
- Question: "What did you expect to happen?"
- Toggle OFF "Required"

**Question 5: How severe is this bug?**
- Type: Multiple choice
- Question: "Bug severity"
- Options:
  - Critical (App crashes or unusable)
  - High (Major feature broken)
  - Medium (Annoying but not blocking)
  - Low (Minor visual issue)
- Toggle ON "Required"

**Question 6: Device Information**
- Type: Short answer
- Question: "Device & Android version (e.g., Pixel 6, Android 13)"
- Toggle OFF "Required"

**Question 7: App Version**
- Type: Short answer
- Question: "App version"
- Description: "Check Settings > About (current version is 1.0.0)"
- Toggle OFF "Required"

### Step 4: Settings
1. Click **Settings** gear icon
2. **General tab**:
   - ✅ Collect email addresses: OFF
   - ✅ Limit to 1 response: OFF
3. **Presentation tab**:
   - ✅ Show progress bar: ON
   - Confirmation message: "Bug report submitted! We'll investigate and fix it as soon as possible. Thank you! 🛠️"

### Step 5: Get Shareable Link
1. Look at the top of your form - you should see a URL/link (it might say "Responder link" or just show the URL)
2. Click on the link or look for a **"Shorten URL"** option nearby
3. If you see a "Shorten URL" checkbox, enable it to get a shorter `forms.gle/` link
4. Copy the URL (e.g., `https://forms.gle/xyz789abc`)
5. **Paste this URL** into `lib/routes.dart` line 477:
   ```dart
   const String bugReportFormUrl = 'https://forms.gle/YOUR_BUG_REPORT_FORM_ID';
   ```

---

## 3. View Responses

### Option 1: Google Forms Dashboard
1. Open your form
2. Click **Responses** tab at the top
3. View individual responses or summary charts

### Option 2: Google Sheets (Recommended)
1. In form, click **Responses** tab
2. Click the green **Google Sheets** icon
3. Choose "Create a new spreadsheet"
4. Now all responses automatically go to a spreadsheet
5. You can sort, filter, and analyze responses easily

---

## 4. Update the App

After creating both forms:

1. Open `lib/routes.dart`
2. Replace the placeholder URLs:
   ```dart
   // Line ~460
   const String feedbackFormUrl = 'https://forms.gle/abc123';
   
   // Line ~477
   const String bugReportFormUrl = 'https://forms.gle/xyz789';
   ```
3. Save the file
4. Test in the app!

---

## Tips & Best Practices

### ✅ Do:
- Check responses regularly (daily during launch week)
- Respond to critical bugs quickly
- Thank users for detailed feedback
- Close/resolve issues when fixed
- Create labels/tags in sheets to organize responses

### ❌ Don't:
- Make too many fields required (users will abandon)
- Ask for sensitive personal information
- Leave responses unread for weeks
- Share the form publicly outside the app (spam risk)

### Privacy Note:
- Google Forms are anonymous by default
- Only collect email if user provides it voluntarily
- Don't share responses with third parties
- Consider adding a privacy note in form descriptions

---

## Example Form Links (for testing)

You can test your forms before adding them to the app:
1. Open the form link in your browser
2. Submit a test response
3. Check that it appears in the Responses tab
4. Verify the confirmation message shows correctly

---

## Troubleshooting

**"Could not open feedback form" error:**
- Make sure the form link is set to "Anyone with the link can respond"
- Check that you shortened the URL in Google Forms
- Verify the URL is pasted correctly in routes.dart (no extra spaces)

**Form not opening in browser:**
- Check internet connection
- Try opening the form URL directly in Chrome
- Make sure `url_launcher` package is installed

**Responses not showing:**
- Check spam/junk folder if using email notifications
- Open the form and click "Responses" tab
- Link the form to Google Sheets for easier tracking

---

## Future Enhancements

Once you have more users, consider:
1. **GitHub Issues** - For public bug tracking
2. **Discord Server** - For community support
3. **Dedicated Support Email** - With professional domain
4. **In-App Chat** - Using services like Intercom or Crisp
5. **Analytics Integration** - Track which bugs are most common

For now, Google Forms is perfect for launch! 🚀
