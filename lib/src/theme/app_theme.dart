import 'package:flutter/material.dart';

abstract final class AppColors {
  static const blue = Color(0xFF007AFF);
  static const blueDark = Color(0xFF0A84FF);
  static const indigo = Color(0xFF5856D6);
  static const mint = Color(0xFF30D158);
  static const orange = Color(0xFFFF9F0A);
  static const red = Color(0xFFFF453A);
  static const purple = Color(0xFFAF52DE);

  static const lightCanvas = Color(0xFFF5F5F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSidebar = Color(0xFFF0F0F3);
  static const lightBorder = Color(0x16000000);
  static const lightText = Color(0xFF1D1D1F);
  static const lightSecondaryText = Color(0xFF6E6E73);

  static const darkCanvas = Color(0xFF111113);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkSidebar = Color(0xFF18181A);
  static const darkBorder = Color(0x22FFFFFF);
  static const darkText = Color(0xFFF5F5F7);
  static const darkSecondaryText = Color(0xFF98989D);
}

ThemeData buildLightTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ).copyWith(
        primary: AppColors.blue,
        error: AppColors.red,
        outline: AppColors.lightBorder,
        surfaceContainerLowest: AppColors.lightSurface,
        surfaceContainerLow: const Color(0xFFF9F9FB),
        surfaceContainer: const Color(0xFFF1F1F4),
      );

  return _buildTheme(
    scheme: scheme,
    canvas: AppColors.lightCanvas,
    text: AppColors.lightText,
    secondaryText: AppColors.lightSecondaryText,
  );
}

ThemeData buildDarkTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.blueDark,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
      ).copyWith(
        primary: AppColors.blueDark,
        error: AppColors.red,
        outline: AppColors.darkBorder,
        surfaceContainerLowest: const Color(0xFF171719),
        surfaceContainerLow: AppColors.darkSurface,
        surfaceContainer: const Color(0xFF28282B),
      );

  return _buildTheme(
    scheme: scheme,
    canvas: AppColors.darkCanvas,
    text: AppColors.darkText,
    secondaryText: AppColors.darkSecondaryText,
  );
}

ThemeData _buildTheme({
  required ColorScheme scheme,
  required Color canvas,
  required Color text,
  required Color secondaryText,
}) {
  final typography = Typography.material2021();
  final baseTextTheme = scheme.brightness == Brightness.dark
      ? typography.white
      : typography.black;
  final textTheme = baseTextTheme.copyWith(
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      color: text,
      fontSize: 34,
      height: 1.08,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.1,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      color: text,
      fontSize: 26,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.65,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      color: text,
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      color: text,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      color: text,
      fontSize: 15,
      height: 1.4,
      letterSpacing: -0.1,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      color: text,
      fontSize: 13,
      height: 1.4,
      letterSpacing: -0.05,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      color: secondaryText,
      fontSize: 12,
      height: 1.35,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      color: text,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.05,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      color: secondaryText,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  final border = BorderSide(color: scheme.outline);

  return ThemeData(
    useMaterial3: true,
    brightness: scheme.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: canvas,
    textTheme: textTheme,
    dividerColor: scheme.outline,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      hintStyle: textTheme.bodyMedium?.copyWith(color: secondaryText),
      labelStyle: textTheme.labelMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: border,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: border,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: border,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: border,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        color: text.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: canvas),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: text,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: canvas),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
