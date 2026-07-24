class AuthValidators {
  static final _onlyDigits = RegExp(r'\D');
  static final _russianPhone = RegExp(r'^\+7\d{10}$');
  static final _otpCode = RegExp(r'^\d{6}$');

  static String normalizeRussianPhone(String value) {
    final digits = value.replaceAll(_onlyDigits, '');

    if (digits.length == 11 && digits.startsWith('8')) {
      return '+7${digits.substring(1)}';
    }

    if (digits.length == 11 && digits.startsWith('7')) {
      return '+$digits';
    }

    if (digits.length == 10) {
      return '+7$digits';
    }

    return value.trim();
  }

  static String? validateRussianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите телефон';
    }

    final normalized = normalizeRussianPhone(value);
    if (!_russianPhone.hasMatch(normalized)) {
      return 'Введите телефон в формате +7XXXXXXXXXX';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите код';
    }

    if (!_otpCode.hasMatch(value.trim())) {
      return 'Код должен состоять из 6 цифр';
    }

    return null;
  }
}
