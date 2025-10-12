import 'package:flutter/material.dart';
import 'data/models.dart';

class AppTheme {
  // Define custom colors for wealth management
  static const Color wealthGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFFF8F00);
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color infoBlue = Color(0xFF1976D2);

  // Color theme mapping
  static const Map<ColorTheme, Color> _primaryColors = {
    ColorTheme.blue: Color(0xFF1976D2),
    ColorTheme.green: Color(0xFF2E7D32),
    ColorTheme.red: Color(0xFFD32F2F),
    ColorTheme.purple: Color(0xFF7B1FA2),
    ColorTheme.orange: Color(0xFFFF8F00),
    ColorTheme.teal: Color(0xFF00796B),
  };

  static const Map<ColorTheme, Color> _primaryContainerColors = {
    ColorTheme.blue: Color(0xFFBBDEFB),
    ColorTheme.green: Color(0xFFA5D6A7),
    ColorTheme.red: Color(0xFFFFCDD2),
    ColorTheme.purple: Color(0xFFE1BEE7),
    ColorTheme.orange: Color(0xFFFFE0B2),
    ColorTheme.teal: Color(0xFFB2DFDB),
  };

  static const Map<ColorTheme, Color> _primaryDarkColors = {
    ColorTheme.blue: Color(0xFF64B5F6),
    ColorTheme.green: Color(0xFF81C784),
    ColorTheme.red: Color(0xFFEF5350),
    ColorTheme.purple: Color(0xFFCE93D8),
    ColorTheme.orange: Color(0xFFFFB74D),
    ColorTheme.teal: Color(0xFF4DB6AC),
  };

  // Light theme color scheme
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E7D32), // Wealth green
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFA5D6A7),
    onPrimaryContainer: Color(0xFF1B5E20),
    secondary: Color(0xFF546E7A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCFD8DC),
    onSecondaryContainer: Color(0xFF263238),
    tertiary: Color(0xFF7B1FA2),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE1BEE7),
    onTertiaryContainer: Color(0xFF4A148C),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFFB71C1C),
    outline: Color(0xFF79747E),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF1C1B1F),
    surfaceContainerHighest: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    inverseSurface: Color(0xFF313033),
    onInverseSurface: Color(0xFFF4EFF4),
    inversePrimary: Color(0xFF81C784),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF2E7D32),
  );

  // Dark theme color scheme
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF81C784),
    onPrimary: Color(0xFF1B5E20),
    primaryContainer: Color(0xFF2E7D32),
    onPrimaryContainer: Color(0xFFA5D6A7),
    secondary: Color(0xFF90A4AE),
    onSecondary: Color(0xFF263238),
    secondaryContainer: Color(0xFF455A64),
    onSecondaryContainer: Color(0xFFCFD8DC),
    tertiary: Color(0xFFCE93D8),
    onTertiary: Color(0xFF4A148C),
    tertiaryContainer: Color(0xFF7B1FA2),
    onTertiaryContainer: Color(0xFFE1BEE7),
    error: Color(0xFFEF5350),
    onError: Color(0xFFB71C1C),
    errorContainer: Color(0xFFD32F2F),
    onErrorContainer: Color(0xFFFFCDD2),
    outline: Color(0xFF938F99),
    surface: Color(0xFF1C1B1F),
    onSurface: Color(0xFFE6E1E5),
    surfaceContainerHighest: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    inverseSurface: Color(0xFFE6E1E5),
    onInverseSurface: Color(0xFF313033),
    inversePrimary: Color(0xFF2E7D32),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF81C784),
  );

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightColorScheme,
      fontFamily: 'Roboto',

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1C1B1F),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1C1B1F),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F2FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF79747E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD32F2F)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 12,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Color(0xFF79747E),
        showUnselectedLabels: true,
      ),

      // Navigation bar theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFBFF),
        indicatorColor: const Color(0xFFA5D6A7),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
        }),
      ),

      // Slider theme
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2E7D32);
          }
          return const Color(0xFF79747E);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFA5D6A7);
          }
          return const Color(0xFFE0E0E0);
        }),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkColorScheme,
      fontFamily: 'Roboto',

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE6E1E5),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE6E1E5),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2B2930),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF938F99)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF81C784), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 12,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF81C784),
        unselectedItemColor: Color(0xFF938F99),
        showUnselectedLabels: true,
        backgroundColor: Color(0xFF1C1B1F),
      ),

      // Navigation bar theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1B1F),
        indicatorColor: const Color(0xFF2E7D32),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
        }),
      ),

      // Slider theme
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF81C784);
          }
          return const Color(0xFF938F99);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2E7D32);
          }
          return const Color(0xFF49454F);
        }),
      ),
    );
  }

  // Custom colors for charts and indicators
  static const List<Color> chartColors = [
    Color(0xFF2E7D32), // Cash - Green
    Color(0xFF1976D2), // Bonds - Blue
    Color(0xFF388E3C), // US Equity - Dark Green
    Color(0xFF00796B), // Intl Equity - Teal
    Color(0xFF5D4037), // Real Estate - Brown
    Color(0xFF7B1FA2), // Alternatives - Purple
  ];

  // Diversification grade colors
  static const Color gradeA = Color(0xFF2E7D32); // Green
  static const Color gradeB = Color(0xFF689F38); // Light Green
  static const Color gradeC = Color(0xFFFF8F00); // Amber
  static const Color gradeD = Color(0xFFE64A19); // Deep Orange
  static const Color gradeF = Color(0xFFD32F2F); // Red

  // Get color for diversification grade
  static Color getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return gradeA;
      case 'B':
        return gradeB;
      case 'C':
        return gradeC;
      case 'D':
        return gradeD;
      case 'F':
        return gradeF;
      default:
        return gradeC;
    }
  }

  // Get color for band indicators
  static Color getBandColor(String band) {
    switch (band.toLowerCase()) {
      case 'green':
        return const Color(0xFF2E7D32);
      case 'yellow':
        return const Color(0xFFFF8F00);
      case 'red':
        return const Color(0xFFD32F2F);
      case 'blue':
        return const Color(0xFF1976D2);
      default:
        return const Color(0xFF79747E);
    }
  }

  // Generate light theme with custom color
  static ThemeData getLightTheme(ColorTheme colorTheme) {
    final primaryColor =
        _primaryColors[colorTheme] ?? _primaryColors[ColorTheme.green]!;
    final primaryContainer = _primaryContainerColors[colorTheme] ??
        _primaryContainerColors[ColorTheme.green]!;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryColor,
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: primaryContainer,
      onPrimaryContainer: _getDarkerColor(primaryColor),
      secondary: const Color(0xFF546E7A),
      onSecondary: const Color(0xFFFFFFFF),
      secondaryContainer: const Color(0xFFCFD8DC),
      onSecondaryContainer: const Color(0xFF263238),
      tertiary: const Color(0xFF7B1FA2),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFE1BEE7),
      onTertiaryContainer: const Color(0xFF4A148C),
      error: const Color(0xFFD32F2F),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFCDD2),
      onErrorContainer: const Color(0xFFB71C1C),
      outline: const Color(0xFF79747E),
      surface: const Color(0xFFFFFBFF),
      onSurface: const Color(0xFF1C1B1F),
      surfaceContainerHighest: const Color(0xFFE7E0EC),
      onSurfaceVariant: const Color(0xFF49454F),
      inverseSurface: const Color(0xFF313033),
      onInverseSurface: const Color(0xFFF4EFF4),
      inversePrimary: _getLighterColor(primaryColor),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      surfaceTint: primaryColor,
    );

    return _buildThemeData(colorScheme, primaryColor);
  }

  // Generate dark theme with custom color
  static ThemeData getDarkTheme(ColorTheme colorTheme) {
    final primaryColor =
        _primaryDarkColors[colorTheme] ?? _primaryDarkColors[ColorTheme.green]!;
    final primaryContainer =
        _primaryColors[colorTheme] ?? _primaryColors[ColorTheme.green]!;
    final primaryContainerLight = _primaryContainerColors[colorTheme] ??
        _primaryContainerColors[ColorTheme.green]!;

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryColor,
      onPrimary: _getDarkerColor(primaryContainer),
      primaryContainer: primaryContainer,
      onPrimaryContainer: primaryContainerLight,
      secondary: const Color(0xFF90A4AE),
      onSecondary: const Color(0xFF263238),
      secondaryContainer: const Color(0xFF455A64),
      onSecondaryContainer: const Color(0xFFCFD8DC),
      tertiary: const Color(0xFFCE93D8),
      onTertiary: const Color(0xFF4A148C),
      tertiaryContainer: const Color(0xFF7B1FA2),
      onTertiaryContainer: const Color(0xFFE1BEE7),
      error: const Color(0xFFEF5350),
      onError: const Color(0xFFB71C1C),
      errorContainer: const Color(0xFFD32F2F),
      onErrorContainer: const Color(0xFFFFCDD2),
      outline: const Color(0xFF938F99),
      surface: const Color(0xFF1C1B1F),
      onSurface: const Color(0xFFE6E1E5),
      surfaceContainerHighest: const Color(0xFF49454F),
      onSurfaceVariant: const Color(0xFFCAC4D0),
      inverseSurface: const Color(0xFFE6E1E5),
      onInverseSurface: const Color(0xFF313033),
      inversePrimary: primaryContainer,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      surfaceTint: primaryColor,
    );

    return _buildThemeData(colorScheme, primaryColor, isDark: true);
  }

  // Helper function to build ThemeData
  static ThemeData _buildThemeData(
    ColorScheme colorScheme,
    Color primaryColor, {
    bool isDark = false,
  }) {
    // Contrast Adjust (Option B - 2025-10-01):
    // When switching to stronger primaries (e.g. blue) the default M3 elevation
    // tint + neutral surfaces reduced contrast in dark mode. We selectively:
    // 1) Nudge onSurfaceVariant & outline lighter for readability.
    // 2) Provide explicit scaffold/card/dialog backgrounds (no implicit tint).
    // 3) Remove surfaceTintColor from elevated surfaces to avoid color cast.
    // 4) Keep light theme mostly unchanged for stability.
    final adjustedColorScheme = isDark
        ? colorScheme.copyWith(
            onSurfaceVariant: const Color(0xFFDDD8E3),
            outline: const Color(0xFFAAA6B0),
            surfaceContainerHighest: const Color(0xFF3A373E),
          )
        : colorScheme;

    final scaffoldBg =
        isDark ? const Color(0xFF121214) : adjustedColorScheme.surface;
    final cardBg = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final dialogBg = isDark ? const Color(0xFF1E1E22) : Colors.white;

    return ThemeData(
      useMaterial3: true,
      colorScheme: adjustedColorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      fontFamily: 'Roboto',

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: adjustedColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: adjustedColorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Filled button theme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2B2930) : const Color(0xFFF7F2FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: adjustedColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: adjustedColorScheme.error),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 12,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: adjustedColorScheme.outline,
        showUnselectedLabels: true,
        backgroundColor: scaffoldBg,
      ),

      // Navigation bar theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        indicatorColor: adjustedColorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);
        }),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        activeTrackColor: primaryColor,
        thumbColor: primaryColor,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return adjustedColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return adjustedColorScheme.primaryContainer;
          }
          return isDark ? const Color(0xFF49454F) : const Color(0xFFE0E0E0);
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Helper functions for color variations
  static Color _getDarkerColor(Color color) {
    return color.withValues(
      red: (color.r * 0.7).clamp(0.0, 1.0),
      green: (color.g * 0.7).clamp(0.0, 1.0),
      blue: (color.b * 0.7).clamp(0.0, 1.0),
    );
  }

  static Color _getLighterColor(Color color) {
    return color.withValues(
      red: (color.r + (1 - color.r) * 0.3).clamp(0.0, 1.0),
      green: (color.g + (1 - color.g) * 0.3).clamp(0.0, 1.0),
      blue: (color.b + (1 - color.b) * 0.3).clamp(0.0, 1.0),
    );
  }

  // Get color theme name for display
  static String getColorThemeName(ColorTheme theme) {
    switch (theme) {
      case ColorTheme.blue:
        return 'Blue';
      case ColorTheme.green:
        return 'Green';
      case ColorTheme.red:
        return 'Red';
      case ColorTheme.purple:
        return 'Purple';
      case ColorTheme.orange:
        return 'Orange';
      case ColorTheme.teal:
        return 'Teal';
    }
  }

  // Get primary color for a theme
  static Color getPrimaryColor(ColorTheme theme) {
    return _primaryColors[theme] ?? _primaryColors[ColorTheme.green]!;
  }
}
