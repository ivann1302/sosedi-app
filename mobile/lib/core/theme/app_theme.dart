import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand500 = Color(0xFFFEA319);
  static const brandPressed = Color(0xFFFF8A00);
  static const brandForeground = Color(0xFFB65700);
  static const brand600 = brandPressed;
  static const brand700 = Color(0xFFFF6A00);
  static const ink900 = Color(0xFF17202B);
  static const slate500 = Color(0xFF5F7487);
  static const slate700 = Color(0xFF465B6E);
  static const slate800 = Color(0xFF35485A);
  static const canvas = Color(0xFFFFFFFF);
  static const cloud = Color(0xFFF7F8F9);
  static const warmSand = Color(0xFFFFF2D9);
  static const surface = canvas;
  static const line = Color(0xFFE4E8EB);
  static const textMuted = Color(0xFF65727C);
  static const success = Color(0xFF1C7C54);
  static const error = Color(0xFFB42318);
}

abstract final class AppRadii {
  static const small = 10.0;
  static const medium = 12.0;
  static const large = 16.0;
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
      surface: AppColors.canvas,
      onSurface: AppColors.ink900,
      error: AppColors.error,
      onError: AppColors.surface,
      outline: AppColors.slate500,
      outlineVariant: AppColors.line,
    );
    final textTheme = _textTheme();

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Onest',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink900,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.medium),
          side: BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cloud,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        helperStyle: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        border: _inputBorder(AppColors.line),
        enabledBorder: _inputBorder(AppColors.line),
        focusedBorder: _inputBorder(AppColors.brandForeground, width: 2),
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
        backgroundColor: AppColors.cloud,
        selectedColor: AppColors.warmSand,
        disabledColor: AppColors.line,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink900),
        iconTheme: const IconThemeData(color: AppColors.ink900),
        checkmarkColor: AppColors.ink900,
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
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.brandForeground
                : AppColors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.brandForeground
                : AppColors.textMuted,
            fontWeight: FontWeight.w600,
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
        color: AppColors.brand500,
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
    const base = TextStyle(color: AppColors.ink900, fontFamily: 'Onest');

    return TextTheme(
      displaySmall: base.copyWith(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: base.copyWith(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.copyWith(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.copyWith(
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.copyWith(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.copyWith(
        fontSize: 17,
        height: 22 / 17,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.copyWith(fontSize: 16, height: 23 / 16),
      bodyMedium: base.copyWith(fontSize: 16, height: 23 / 16),
      bodySmall: base.copyWith(
        color: AppColors.textMuted,
        fontSize: 14,
        height: 20 / 14,
      ),
      labelLarge: base.copyWith(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.copyWith(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.copyWith(
        color: AppColors.textMuted,
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
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
