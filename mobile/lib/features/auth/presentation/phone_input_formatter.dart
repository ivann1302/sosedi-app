import 'package:flutter/services.dart';

/// Formats the national part; the field displays +7 as a fixed prefix.
class RussianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsPattern = RegExp(r'\d');
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    var beforeCursor = digitsPattern
        .allMatches(
          newValue.text.substring(
            0,
            newValue.selection.extentOffset.clamp(0, newValue.text.length),
          ),
        )
        .length;
    if (digits.length == 11 &&
        (digits.startsWith('7') || digits.startsWith('8'))) {
      digits = digits.substring(1);
      beforeCursor = (beforeCursor - 1).clamp(0, 10);
    }
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    if (newValue.text.length < oldValue.text.length &&
        digits == oldDigits &&
        beforeCursor > 0) {
      digits = digits.replaceRange(beforeCursor - 1, beforeCursor, '');
      beforeCursor--;
    }
    digits = digits.substring(0, digits.length.clamp(0, 10));
    final result = StringBuffer();
    var cursor = 0;
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) result.write('(');
      if (i == 3) result.write(') ');
      if (i == 6 || i == 8) result.write('-');
      result.write(digits[i]);
      if (i < beforeCursor) cursor = result.length;
    }
    return TextEditingValue(
      text: result.toString(),
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
