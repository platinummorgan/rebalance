# App Icon & Splash Screen Requirements

## 📱 What You Need to Create

### 1. **App Icon** (`app_icon.png`)
- **Size**: 1024x1024 pixels (will be automatically resized)
- **Format**: PNG with transparency
- **Location**: `assets/icons/app_icon.png`
- **Design Tips**:
  - Simple, recognizable design
  - Works at small sizes (48x48)
  - Clear on both light and dark backgrounds
  - **Suggestion**: Use "W" for Wealth or a dial/gauge icon

### 2. **Adaptive Icon Foreground** (`app_icon_foreground.png`)
- **Size**: 1024x1024 pixels
- **Format**: PNG with transparency
- **Location**: `assets/icons/app_icon_foreground.png`
- **Design Tips**:
  - Same design as app_icon but with transparency
  - Keep important elements in safe zone (center 75%)
  - Will be placed on colored background (#1a1a1a dark gray)

### 3. **Splash Screen Icon** (`splash_icon.png`)
- **Size**: 1024x1024 pixels (or smaller, 512x512 works too)
- **Format**: PNG with transparency
- **Location**: `assets/icons/splash_icon.png`
- **Design Tips**:
  - Same as app icon or simplified version
  - Shows briefly when app launches
  - Centered on dark background (#1a1a1a)

## 🎨 Design Ideas for "Wealth Dial"

### Option 1: Gauge/Dial Icon
```
Simple speedometer or gauge showing financial health
- Arc with needle pointing to "healthy" zone
- Clean, modern lines
- Teal/blue gradient matching your app theme
```

### Option 2: Letter "W" Logo
```
Stylized "W" lettermark
- Modern, bold typography
- Could incorporate dial/circular element
- Teal accent color
```

### Option 3: Pie Chart Icon
```
Simplified pie chart representing asset allocation
- 3-4 segments in different colors
- Clean, minimal style
- Easy to recognize
```

## 🚀 Quick Start: Using Placeholder

For now, I can create simple text-based placeholders. To use real icons:

1. **Create or commission your icons** (Canva, Figma, hire designer)
2. **Export as PNG** at the sizes above
3. **Place in** `assets/icons/` folder
4. **Run commands**:
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

## 🔧 After Adding Your Icons

Once you have the PNG files:
1. Save them to `assets/icons/`
2. Run the generation commands above
3. Rebuild the app
4. Your icon appears on home screen!
5. Splash screen shows on launch!

## 📐 Current Colors in Your App

- **Primary**: Teal/Blue (#00ACC1, #0097A7)
- **Background**: Dark (#1a1a1a, #121212)
- **Accent**: Green (success), Red (warning)

Match your icon to these colors for consistency!
