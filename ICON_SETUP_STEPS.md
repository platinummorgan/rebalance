# Quick Setup Steps

## ✅ Packages Installed
- `flutter_launcher_icons` - for app icon
- `flutter_native_splash` - for splash screen

## 📝 What You Need To Do

### Step 1: Create Your Icon Files

You need 3 PNG files in `assets/icons/`:

1. **app_icon.png** (1024x1024) - Your main app icon
2. **app_icon_foreground.png** (1024x1024) - Same icon with transparency for adaptive icons
3. **splash_icon.png** (512x512 or 1024x1024) - Icon shown during app load

### Step 2: Design Options

**Quick Option - Use Online Tools:**
- **Canva** (free): Search "app icon template" → customize → download PNG
- **Figma** (free): Design custom icon → export PNG
- **Flaticon** (free): Download icon → customize color → export

**Colors to use (match your app):**
- Primary: `#00ACC1` (Teal/Cyan)
- Accent: `#0097A7` (Darker Teal)
- Background: `#1a1a1a` (Dark Gray)

**Icon Ideas:**
- Letter "W" in a circle (for Wealth)
- Gauge/speedometer icon
- Pie chart icon
- Dollar sign with dial
- Simple geometric shape with teal gradient

### Step 3: Once You Have Icons

Run these commands:

```bash
# Generate app icons
flutter pub run flutter_launcher_icons

# Generate splash screen
flutter pub run flutter_native_splash:create

# Rebuild app
flutter run -d emulator-5554
```

### Step 4: Test

- App icon appears on home screen/drawer
- Splash screen shows when launching app
- Both use your branding!

## 🎨 Need Help Designing?

**Free Tools:**
- Canva: https://www.canva.com
- Figma: https://www.figma.com
- Flaticon: https://www.flaticon.com
- IconScout: https://iconscout.com

**Or Hire Quick:**
- Fiverr: $5-25 for simple app icon
- 99designs: Professional designers

## 📐 Specifications

### App Icon:
- Square (1:1 aspect ratio)
- No transparency on main icon (solid background)
- Simple, recognizable at small sizes
- High contrast

### Splash Icon:
- Can have transparency
- Centered design
- Not too large (will be centered on dark background)

## ⚡ Quick Test (Temporary)

Want to test with a placeholder? You can:

1. Use any square PNG image (rename to required names)
2. Generate icons
3. See it working
4. Replace with real icons later!

---

**Current Status:** ✅ Configured, waiting for icon files
**Next Step:** Create/add your 3 PNG files to `assets/icons/`
