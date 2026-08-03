import type { LoggerService } from '@nestjs/common';
import { RedactingLogger } from './redacting-logger';

describe('RedactingLogger', () => {
  it('sanitizes messages and optional parameters before delegation', () => {
    const error = jest.fn();
    const delegate: LoggerService = {
      log: jest.fn(),
      error,
      warn: jest.fn(),
      debug: jest.fn(),
      verbose: jest.fn(),
      fatal: jest.fn(),
    };
    const logger = new RedactingLogger(delegate);

    logger.error(
      {
        eventId: 'event-1',
        phone: '+79991234567',
        accessToken: 'access-secret',
      },
      'OTP: 123456',
      'AuthService',
    );

    expect(error).toHaveBeenCalledWith(
      {
        eventId: 'event-1',
        phone: '[REDACTED]',
        accessToken: '[REDACTED]',
      },
      'OTP: [REDACTED]',
      'AuthService',
    );
  });
});
