import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_validators.dart';

void main() {
  group('phone validation', () {
    test('normalizes Russian phone numbers', () {
      expect(
        AuthValidators.normalizeRussianPhone('8 (999) 123-45-67'),
        '+79991234567',
      );
      expect(
        AuthValidators.normalizeRussianPhone('9991234567'),
        '+79991234567',
      );
    });

    test('validates Russian phone numbers', () {
      expect(AuthValidators.validateRussianPhone('+7 999 123 45 67'), isNull);
      expect(AuthValidators.validateRussianPhone('123'), isNotNull);
      expect(AuthValidators.validateRussianPhone(''), isNotNull);
    });
  });

  group('OTP validation', () {
    test('accepts only 6 digits', () {
      expect(AuthValidators.validateOtp('123456'), isNull);
      expect(AuthValidators.validateOtp('12345'), isNotNull);
      expect(AuthValidators.validateOtp('abcdef'), isNotNull);
    });
  });
}
