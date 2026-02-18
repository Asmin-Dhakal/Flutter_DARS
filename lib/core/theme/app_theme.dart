import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Coolors Palette Implementation
/// https://coolors.co/palette/f8f9fa-e9ecef-dee2e6-ced4da-adb5bd-6c757d-495057-343a40-212529
class AppColors {
  // Lightest to Darkest (Gray Scale)
  static const Color gray100 = Color(0xFFF8F9FA); // Background/Light surfaces
  static const Color gray200 = Color(0xFFE9ECEF); // Card backgrounds
  static const Color gray300 = Color(0xFFDEE2E6); // Borders/Dividers
  static const Color gray400 = Color(0xFFCED4DA); // Disabled states
  static const Color gray500 = Color(0xFFADB5BD); // Placeholder text
  static const Color gray600 = Color(0xFF6C757D); // Secondary text
  static const Color gray700 = Color(0xFF495057); // Primary text
  static const Color gray800 = Color(0xFF343A40); // Headers/Emphasis
  static const Color gray900 = Color(0xFF212529); // Darkest/High emphasis

  // Semantic Colors (Material 3 compatible)
  static const Color primary = Color(0xFF343A40); // gray800
  static const Color onPrimary = Color(0xFFF8F9FA); // gray100
  static const Color primaryContainer = Color(0xFFE9ECEF); // gray200
  static const Color onPrimaryContainer = Color(0xFF212529); // gray900

  static const Color secondary = Color(0xFF495057); // gray700
  static const Color onSecondary = Color(0xFFF8F9FA); // gray100
  static const Color secondaryContainer = Color(0xFFDEE2E6); // gray300
  static const Color onSecondaryContainer = Color(0xFF212529); // gray900

  static const Color surface = Color(0xFFF8F9FA); // gray100
  static const Color onSurface = Color(0xFF212529); // gray900
  static const Color surfaceVariant = Color(0xFFE9ECEF); // gray200
  static const Color onSurfaceVariant = Color(0xFF495057); // gray700

  static const Color background = Color(0xFFF8F9FA); // gray100
  static const Color onBackground = Color(0xFF212529); // gray900

  static const Color outline = Color(0xFFCED4DA); // gray400
  static const Color outlineVariant = Color(0xFFDEE2E6); // gray300

  // Status Colors (optimized for accessibility)
  static const Color success = Color(0xFF198754);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFFFC107);
  static const Color onWarning = Color(0xFF212529);
  static const Color error = Color(0xFFDC3545);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color info = Color(0xFF0DCAF0);
  static const Color onInfo = Color(0xFF212529);
}

/// Material 3 Design Tokens
class AppTokens {
  // Border Radius (Material 3: 4dp base, 8dp medium, 16dp large, 28dp extra large)
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;
  static const double radiusXXLarge = 28;
  static const double radiusFull = 999;

  // Spacing (8dp grid system)
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // Elevation (Material 3: 0, 1, 2, 3, 4, 6, 8, 12 levels)
  static const List<double> elevation = [0, 1, 2, 3, 4, 6, 8, 12];

  // Opacity
  static const double opacityHigh = 1.0;
  static const double opacityMedium = 0.87;
  static const double opacityLow = 0.60;
  static const double opacityDisabled = 0.38;

  // Animation (optimized for 60fps on low-end devices)
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.decelerate;
  static const Curve curveAccelerate = Curves.easeIn;
}

/// App Theme Configuration
class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Use gray900 as primary for dark, gray800 for light
    final primaryColor = isDark ? AppColors.gray700 : AppColors.gray800;
    final surfaceColor = isDark ? AppColors.gray900 : AppColors.gray100;
    final backgroundColor = isDark ? AppColors.gray900 : AppColors.gray100;
    final onSurfaceColor = isDark ? AppColors.gray100 : AppColors.gray900;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color Scheme (Material 3)
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.gray600,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.gray300,
        onTertiaryContainer: AppColors.gray900,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.error.withOpacity(0.1),
        onErrorContainer: AppColors.error,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
        surfaceContainerHighest: isDark ? AppColors.gray800 : AppColors.gray200,
        onSurfaceVariant: isDark ? AppColors.gray400 : AppColors.gray700,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        shadow: AppColors.gray900.withOpacity(0.2),
        scrim: AppColors.gray900.withOpacity(0.5),
        inverseSurface: isDark ? AppColors.gray100 : AppColors.gray900,
        onInverseSurface: isDark ? AppColors.gray900 : AppColors.gray100,
        inversePrimary: isDark ? AppColors.gray400 : AppColors.gray600,
      ),

      // Typography (Material 3 + optimized for readability)
      textTheme: _buildTextTheme(isDark),

      // Component Themes (Material 3)
      cardTheme: _buildCardTheme(isDark),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      filledButtonTheme: _buildFilledButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      appBarTheme: _buildAppBarTheme(isDark),
      bottomNavigationBarTheme: _buildBottomNavTheme(isDark),
      dialogTheme: _buildDialogTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      chipTheme: _buildChipTheme(),
      dividerTheme: _buildDividerTheme(),
      listTileTheme: _buildListTileTheme(),

      // Layout
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: surfaceColor,
      shadowColor: AppColors.gray900.withOpacity(0.1),

      // Performance optimizations
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Reduce animations for low-end devices
      visualDensity: VisualDensity.compact,
    );
  }

  static TextTheme _buildTextTheme(bool isDark) {
    final color = isDark ? AppColors.gray100 : AppColors.gray900;
    final secondaryColor = isDark ? AppColors.gray400 : AppColors.gray600;

    return TextTheme(
      // Display (large headers)
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: color,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.22,
      ),

      // Headlines
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color,
        height: 1.33,
      ),

      // Titles
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: color,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: color,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color,
        height: 1.43,
      ),

      // Body
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: color,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: color,
        height: 1.43,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: secondaryColor,
        height: 1.33,
      ),

      // Labels
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: color,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: color,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondaryColor,
        height: 1.45,
      ),
    );
  }

  static CardThemeData _buildCardTheme(bool isDark) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        side: BorderSide(color: AppColors.outline.withOpacity(0.5)),
      ),
      color: isDark ? AppColors.gray800 : AppColors.gray100,
      margin: const EdgeInsets.all(AppTokens.space2),
      clipBehavior: Clip.antiAlias,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space5,
          vertical: AppTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        minimumSize: const Size(64, 40),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme() {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space5,
          vertical: AppTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.outline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space5,
          vertical: AppTokens.space3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space3,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.gray500),
      labelStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.gray600),
    );
  }

  static AppBarTheme _buildAppBarTheme(bool isDark) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray100,
      foregroundColor: isDark ? AppColors.gray100 : AppColors.gray900,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.gray100 : AppColors.gray900,
      ),
      shape: Border(
        bottom: BorderSide(color: AppColors.outline.withOpacity(0.2)),
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavTheme(bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray100,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.gray500,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: AppColors.gray800,
      contentTextStyle: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.gray100,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primaryContainer,
      labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3,
        vertical: AppTokens.space1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
    );
  }

  static DividerThemeData _buildDividerTheme() {
    return DividerThemeData(
      color: AppColors.outline.withOpacity(0.5),
      thickness: 1,
      space: AppTokens.space4,
    );
  }

  static ListTileThemeData _buildListTileTheme() {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space1,
      ),
      minLeadingWidth: AppTokens.space6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
    );
  }
}
