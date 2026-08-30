import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';

void main() {
  test('light theme exposes the approved marketplace tokens', () {
    final theme = AppTheme.light();
    final selected = <WidgetState>{WidgetState.selected};
    final unselected = <WidgetState>{};

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Onest');
    expect(theme.textTheme.labelSmall?.fontSize, 13);
    expect(theme.textTheme.labelSmall?.height, 18 / 13);
    expect(theme.textTheme.labelSmall?.fontWeight, FontWeight.w600);
    expect(theme.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
    expect(theme.appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    expect(theme.colorScheme.primary, const Color(0xFFFEA319));
    expect(theme.colorScheme.outlineVariant, const Color(0xFFE4E8EB));
    expect(theme.cardTheme.elevation, 0);
    expect(
      (theme.cardTheme.shape! as RoundedRectangleBorder).side,
      BorderSide.none,
    );
    expect(
      (theme.cardTheme.shape! as RoundedRectangleBorder).borderRadius.resolve(
        TextDirection.ltr,
      ),
      BorderRadius.circular(12),
    );
    expect(
      (theme.filledButtonTheme.style!.shape!.resolve(selected)
              as RoundedRectangleBorder)
          .borderRadius
          .resolve(TextDirection.ltr),
      BorderRadius.circular(10),
    );
    expect(theme.inputDecorationTheme.fillColor, const Color(0xFFF7F8F9));
    expect(
      theme.inputDecorationTheme.focusedBorder!.borderSide,
      const BorderSide(color: Color(0xFFB65700), width: 2),
    );
    expect(
      (theme.dialogTheme.shape! as RoundedRectangleBorder).borderRadius.resolve(
        TextDirection.ltr,
      ),
      BorderRadius.circular(16),
    );
    expect(theme.navigationBarTheme.indicatorColor, Colors.transparent);
    expect(
      theme.navigationBarTheme.iconTheme!.resolve(selected)!.color,
      const Color(0xFFB65700),
    );
    expect(
      theme.navigationBarTheme.labelTextStyle!.resolve(selected)!.color,
      const Color(0xFFB65700),
    );
    expect(
      theme.navigationBarTheme.labelTextStyle!.resolve(selected)!.fontWeight,
      FontWeight.w600,
    );
    expect(
      theme.navigationBarTheme.labelTextStyle!.resolve(unselected)!.fontWeight,
      FontWeight.w600,
    );
    expect(theme.chipTheme.backgroundColor, const Color(0xFFF7F8F9));
    expect(theme.chipTheme.selectedColor, const Color(0xFFFFF2D9));
    expect(theme.chipTheme.labelStyle?.color, const Color(0xFF17202B));
    expect(theme.chipTheme.checkmarkColor, const Color(0xFF17202B));
    expect(theme.chipTheme.iconTheme?.color, const Color(0xFF17202B));
    expect(theme.progressIndicatorTheme.color, const Color(0xFFFEA319));
  });
}
