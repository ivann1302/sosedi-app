import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand500 = Color(0xFFFEA319);
  static const brand600 = Color(0xFFFF8A00);
  static const brand700 = Color(0xFFFF6A00);
  static const ink900 = Color(0xFF17202B);
  static const slate500 = Color(0xFF5F7487);
  static const slate700 = Color(0xFF465B6E);
  static const slate800 = Color(0xFF35485A);
  static const cloud = Color(0xFFF7F8F9);
  static const warmSand = Color(0xFFFFF2D9);
  static const surface = Color(0xFFFFFFFF);
  static const line = Color(0xFFE4E8EB);
  static const textMuted = Color(0xFF65727C);
  static const success = Color(0xFF1C7C54);
  static const error = Color(0xFFB42318);
}

abstract final class AppRadii {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 24.0;
}

class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppColors.brand500,
      onPrimary: AppColors.ink900,
      primaryContainer: AppColors.warmSand,
      onPrimaryContainer: AppColors.ink900,
      secondary: AppColors.slate800,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.slate800,
      onSecondaryContainer: AppColors.surface,
      surface: AppColors.cloud,
      onSurface: AppColors.ink900,
      error: AppColors.error,
      onError: AppColors.surface,
      outline: AppColors.slate500,
      outlineVariant: AppColors.line,
    );
    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['Inter'],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cloud,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.cloud,
        foregroundColor: AppColors.ink900,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.ink900.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        helperStyle: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        border: _inputBorder(AppColors.line),
        enabledBorder: _inputBorder(AppColors.line),
        focusedBorder: _inputBorder(AppColors.slate700, width: 2),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AppColors.brand500,
          foregroundColor: AppColors.ink900,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.textMuted,
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink900,
          side: const BorderSide(color: AppColors.line),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.slate800,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          foregroundColor: AppColors.ink900,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.warmSand,
        selectedColor: AppColors.brand500,
        disabledColor: AppColors.line,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.slate700,
        textColor: AppColors.ink900,
        minVerticalPadding: 12,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.warmSand,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink900
                : AppColors.slate500,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink900
                : AppColors.slate500,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.slate800,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.small),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand600,
        linearTrackColor: AppColors.warmSand,
        circularTrackColor: AppColors.warmSand,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand500,
        foregroundColor: AppColors.ink900,
        elevation: 2,
      ),
    );
  }

  static TextTheme _textTheme() {
    const base = TextStyle(
      color: AppColors.ink900,
      fontFamily: 'Manrope',
      fontFamilyFallback: ['Inter'],
    );

    return TextTheme(
      displaySmall: base.copyWith(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineMedium: base.copyWith(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineSmall: base.copyWith(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: base.copyWith(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.copyWith(fontSize: 16, height: 24 / 16),
      bodyMedium: base.copyWith(fontSize: 16, height: 24 / 16),
      bodySmall: base.copyWith(
        color: AppColors.textMuted,
        fontSize: 14,
        height: 20 / 14,
      ),
      labelLarge: base.copyWith(
        fontSize: 16,
        height: 20 / 16,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
      ),
      labelSmall: base.copyWith(
        color: AppColors.textMuted,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.small),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
