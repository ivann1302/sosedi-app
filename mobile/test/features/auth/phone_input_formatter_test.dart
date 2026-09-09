import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/phone_input_formatter.dart';

void main() {
  final formatter = RussianPhoneInputFormatter();
  TextEditingValue input(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  test('formats national digits and pasted Russian prefixes consistently', () {
    for (final text in ['9991234567', '89991234567', '+7 (999) 123-45-67']) {
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, input(text)).text,
        '(999) 123-45-67',
      );
    }
  });
  test('keeps deletion and clearing usable', () {
    expect(
      formatter
          .formatEditUpdate(input('(999) 123-45-67'), input('(999) 123-45-6'))
          .text,
      '(999) 123-45-6',
    );
    expect(
      formatter.formatEditUpdate(input('(999'), TextEditingValue.empty).text,
      '',
    );
  });
}
