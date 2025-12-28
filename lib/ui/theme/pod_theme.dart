import 'package:flutter/material.dart';

/// Color palette for the POD XT Pro controller app
/// Inspired by the Line 6 POD XT Pro hardware aesthetics
class PodColors {
  // Backgrounds
  static const background = Color(0xFF0D0D0D);      // Near black
  static const surface = Color(0xFF1A1A1A);         // Dark charcoal
  static const surfaceLight = Color(0xFF2A2A2A);    // Elevated surfaces

  // Accents
  static const accent = Color(0xFFFF6B00);          // Line6 orange
  static const accentDim = Color(0xFF803600);       // Dimmed orange

  // Backlit Buttons
  static const buttonOff = Color(0xFF2A2A2A);       // Grayed out / no light
  static const buttonOffText = Color(0xFF606060);   // Dimmed text when off
  static const buttonOnGreen = Color(0xFF00CC00);   // Lit green
  static const buttonOnAmber = Color(0xFFFFAA00);   // Lit amber/orange
  static const buttonGlow = Color(0xFF00FF00);      // Glow effect (green)
  static const buttonGlowAmber = Color(0xFFFFCC00); // Glow effect (amber)

  // LCD Display
  static const lcdBackground = Color(0xFF1A2A1A);   // Dark green tint
  static const lcdText = Color(0xFF88FF88);         // Green LCD text
  static const lcdGlow = Color(0xFF00FF00);         // Glow effect

  // Knobs/Metal
  static const knobBase = Color(0xFF3A3A3A);        // Knob body
  static const knobHighlight = Color(0xFF5A5A5A);   // Knob highlight
  static const knobShadow = Color(0xFF1A1A1A);      // Knob shadow
  static const knobIndicator = Color(0xFFFFFFFF);   // Position indicator

  // Text
  static const textPrimary = Color(0xFFE0E0E0);     // Main text
  static const textSecondary = Color(0xFF808080);   // Dimmed text
  static const textLabel = Color(0xFFB0B0B0);       // Labels

  // Overlay
  static const modalOverlay = Color(0xCC000000);    // 80% black
}

/// Text styles for the POD XT Pro app
class PodTextStyles {
  // LCD Display styles
  static const lcdLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: PodColors.lcdText,
    letterSpacing: 1.5,
    height: 1.2,
  );

  static const lcdMedium = TextStyle(
    fontFamily: 'monospace',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: PodColors.lcdText,
    letterSpacing: 1.2,
    height: 1.2,
  );

  static const lcdSmall = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PodColors.lcdText,
    letterSpacing: 1.0,
    height: 1.2,
  );

  // Parameter labels (printed on hardware)
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: PodColors.textLabel,
    letterSpacing: 0.8,
    height: 1.2,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: PodColors.textLabel,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: PodColors.textLabel,
    letterSpacing: 0.3,
    height: 1.2,
  );

  // Parameter values
  static const valueLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: PodColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const valueMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: PodColors.textPrimary,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const valueSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: PodColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.2,
  );

  // Secondary text
  static const secondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: PodColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.2,
  );

  // Button text when off
  static const buttonOff = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: PodColors.buttonOffText,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Button text when on (green)
  static const buttonOnGreen = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: PodColors.buttonOnGreen,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Button text when on (amber)
  static const buttonOnAmber = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: PodColors.buttonOnAmber,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Header/title text
  static const header = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: PodColors.textPrimary,
    letterSpacing: 1.0,
    height: 1.2,
  );

  static const subheader = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: PodColors.textLabel,
    letterSpacing: 0.8,
    height: 1.2,
  );
}

/// Theme configuration for the POD XT Pro app
class PodTheme {
  /// Get the Material 3 ThemeData for the app
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: PodColors.accent,
        onPrimary: PodColors.textPrimary,
        primaryContainer: PodColors.accentDim,
        onPrimaryContainer: PodColors.textPrimary,
        secondary: PodColors.buttonOnGreen,
        onSecondary: PodColors.background,
        secondaryContainer: PodColors.buttonOnAmber,
        onSecondaryContainer: PodColors.background,
        tertiary: PodColors.lcdText,
        onTertiary: PodColors.lcdBackground,
        error: Colors.redAccent,
        onError: PodColors.textPrimary,
        surface: PodColors.surface,
        onSurface: PodColors.textPrimary,
        surfaceContainerHighest: PodColors.surfaceLight,
        outline: PodColors.textSecondary,
        outlineVariant: PodColors.knobBase,
        shadow: PodColors.knobShadow,
      ),

      // Scaffold
      scaffoldBackgroundColor: PodColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: PodColors.surface,
        foregroundColor: PodColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: PodTextStyles.header,
      ),

      // Card
      cardTheme: CardThemeData(
        color: PodColors.surface,
        elevation: 2,
        shadowColor: PodColors.knobShadow.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PodColors.surfaceLight,
          foregroundColor: PodColors.textPrimary,
          elevation: 2,
          shadowColor: PodColors.knobShadow.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: PodTextStyles.valueMedium,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PodColors.accent,
          textStyle: PodTextStyles.valueMedium,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: PodColors.textLabel,
        size: 24,
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: PodColors.accent,
        inactiveTrackColor: PodColors.knobBase,
        thumbColor: PodColors.knobIndicator,
        overlayColor: PodColors.accent.withValues(alpha: 0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PodColors.buttonOnGreen;
          }
          return PodColors.knobBase;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return PodColors.buttonOnGreen.withValues(alpha: 0.5);
          }
          return PodColors.buttonOff;
        }),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PodColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PodColors.knobBase),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PodColors.knobBase),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PodColors.accent, width: 2),
        ),
        labelStyle: PodTextStyles.labelMedium,
        hintStyle: PodTextStyles.secondary,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: PodColors.surface,
        elevation: 8,
        shadowColor: PodColors.knobShadow.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: PodTextStyles.header,
        contentTextStyle: PodTextStyles.valueMedium,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: PodColors.knobBase,
        thickness: 1,
        space: 1,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: PodTextStyles.header,
        displayMedium: PodTextStyles.subheader,
        titleLarge: PodTextStyles.header,
        titleMedium: PodTextStyles.subheader,
        titleSmall: PodTextStyles.labelLarge,
        bodyLarge: PodTextStyles.valueMedium,
        bodyMedium: PodTextStyles.valueSmall,
        bodySmall: PodTextStyles.secondary,
        labelLarge: PodTextStyles.labelLarge,
        labelMedium: PodTextStyles.labelMedium,
        labelSmall: PodTextStyles.labelSmall,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: PodColors.accent,
        foregroundColor: PodColors.textPrimary,
        elevation: 4,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PodColors.surface,
        selectedItemColor: PodColors.accent,
        unselectedItemColor: PodColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: PodColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: PodColors.accent, width: 1),
        ),
        textStyle: PodTextStyles.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PodColors.accent,
        linearTrackColor: PodColors.knobBase,
        circularTrackColor: PodColors.knobBase,
      ),
    );
  }
}
