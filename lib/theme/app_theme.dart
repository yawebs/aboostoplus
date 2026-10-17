import 'package:flutter/material.dart';

import '../const/constant.dart';
import 'app_palette.dart';

// The component-styled theme (AppTheme.light/dark) is never wired into
// MaterialApp directly. Screens wrap their own subtree in `Theme(data:
// AppTheme.theme, ...)` on web (always light) and `AppTheme.of(context)` on
// mobile, which follows the app-wide light/dark mode. The app-wide mobile
// themes are AppTheme.mobileLight / mobileDark (see main.dart).
class AppColors {
  static final primary = primaryColor;
  static const primaryLight = Color(0xFFFFF0E8);
  // Warm gold accent, pulled from the existing gradientColors4 palette in
  // constant.dart so the new web accent still feels drawn from the brand.
  static const secondary = Color(0xFFE8A93B);
  static const secondaryLight = Color(0xFFFCF0DA);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F6FA);
  static const surfaceAlt = Color(0xFFEFEFF6);
  static const textDark = Color(0xFF0D0D0D);
  static const textGrey = Color(0xFF8A8A8A);
  static const textLight = Color(0xFFBBBBBB);
  static const border = Color(0xFFE8E8E8);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const cardBg = Color(0xFFF7F8FC);
  static const cardShadow = Color(0x1F3F224F);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F224F), Color(0xFF6A3D7A)],
  );
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

// Responsive breakpoints for the web-only layout branches. Mobile never
// consults these — it always renders its original, unbranched layout.
class AppBreakpoints {
  static const narrow = 700.0; // narrow browser window / mobile web
  static const medium = 1100.0; // tablet web
  // >= medium is treated as desktop web.

  static bool isNarrow(double width) => width < narrow;
  static bool isMedium(double width) => width >= narrow && width < medium;
  static bool isWide(double width) => width >= medium;
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.primary.withOpacity(.35),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTheme {
  // Component-styled theme used by the redesigned screens. On web it is the
  // only theme (always light). On mobile the redesigned screens wrap
  // themselves in Theme(data: AppTheme.of(context)), which picks the light
  // or dark variant to match the app-wide theme mode.
  static ThemeData get theme => light;

  static ThemeData get light => _component(Brightness.light, AppPalette.light);
  static ThemeData get dark => _component(Brightness.dark, AppPalette.dark);

  static ThemeData of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // Mobile app-wide themes, wired to MaterialApp in main.dart. Light keeps
  // the app's original implicit theme so light mode is unchanged.
  static ThemeData get mobileLight => ThemeData(
        primaryColor: primaryColor,
        extensions: const [AppPalette.light],
      );

  static ThemeData get mobileDark {
    const p = AppPalette.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: p.accent,
      surface: p.background,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      cardColor: p.surface,
      dividerColor: p.border,
      dialogTheme: DialogThemeData(backgroundColor: p.surface),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textDark,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: const [p],
    );
  }

  static ThemeData _component(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: isDark ? p.accent : AppColors.primary,
        secondary: AppColors.secondary,
        surface: p.background,
      ),
      scaffoldBackgroundColor: p.background,
      fontFamily: 'SF Pro Display',
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: p.textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: p.textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: p.textDark,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: p.textGrey,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: p.accent),
        titleTextStyle: TextStyle(
          color: p.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.background,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: p.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: p.textLight),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primaryFill,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      extensions: [p],
    );
  }
}
