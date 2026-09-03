import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Clean bright background for light mode
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF3F6F1); // Sunken / inset base
  static const foreground = Color(0xFF1E251C);
  static const mutedForeground = Color(0xFF5A6354);

  // Semantic Colors
  static const primary = Color(0xFF3B6D11);
  static const primaryLight = Color(0xFFDFF0C7);
  static const primaryPressed = Color(0xFF275300);
  static const brand = Color(0xFFB8931B);
  static const info = Color(0xFF185FA5);
  static const infoSurface = Color(0xFFE6F1FB);
  static const warning = Color(0xFF854F0B);
  static const danger = Color(0xFFA32D2D);
  static const success = Color(0xFF2F6B3B);
  static const successSurface = Color(0xFFE4F2E5);
  static const warningSurface = Color(0xFFFAEEDA);
  static const border = Color(0xFFE2E8DF);

  // Neumorphic / Soft UI Shadow Colors (Light Mode)
  static const shadowLight = Color(0xFFFFFFFF);
  static const shadowDark = Color(0x1A2B401D); // Soft organic shadow

  // Neumorphic Shadow Colors (Dark Mode)
  static const darkBackground = Color(0xFF1E221B);
  static const darkSurface = Color(0xFF1E221B);
  static const darkSurfaceAlt = Color(0xFF161A14);
  static const darkShadowLight = Color(0xFF2B3127);
  static const darkShadowDark = Color(0xFF111410);
}

class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadii {
  const AppRadii._();
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

class AppMotion {
  const AppMotion._();
  static const fast = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 300);
}

class AppShadows {
  const AppShadows._();

  /// Dual-shadow generator for Neumorphic Raised / Extruded surfaces
  static List<BoxShadow> neumorphicRaised({
    double distance = 6,
    double blur = 12,
    bool isDark = false,
  }) {
    if (isDark) {
      return [
        BoxShadow(
          color: AppColors.darkShadowLight.withValues(alpha: 0.7),
          offset: Offset(-distance, -distance),
          blurRadius: blur,
        ),
        BoxShadow(
          color: AppColors.darkShadowDark.withValues(alpha: 0.9),
          offset: Offset(distance, distance),
          blurRadius: blur,
        ),
      ];
    }
    return [
      BoxShadow(
        color: AppColors.shadowLight.withValues(alpha: 0.95),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: AppColors.shadowDark.withValues(alpha: 0.45),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
    ];
  }

  /// Subtle Floating shadow for soft UI elements (Buttons, floating bars)
  static List<BoxShadow> softFloating({
    Color shadowColor = AppColors.primary,
    double opacity = 0.25,
  }) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: opacity),
        offset: const Offset(0, 8),
        blurRadius: 18,
        spreadRadius: -2,
      ),
      BoxShadow(
        color: AppColors.shadowLight.withValues(alpha: 0.8),
        offset: const Offset(-2, -2),
        blurRadius: 6,
      ),
    ];
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primaryLight,
          onPrimaryContainer: AppColors.primaryPressed,
          surface: AppColors.surface,
          onSurface: AppColors.foreground,
          outline: AppColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        elevation: 0,
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.mutedForeground,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(surface: AppColors.darkSurface, onSurface: Colors.white);

    return ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
