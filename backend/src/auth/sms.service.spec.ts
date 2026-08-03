import { InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsService } from './sms.service';

describe('SmsService logging', () => {
  it('never writes the phone or OTP to the console fallback log', async () => {
    const originalNodeEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    const consoleInfo = jest
      .spyOn(console, 'info')
      .mockImplementation(() => undefined);
    const service = new SmsService(
      new ConfigService({
        SMS_PROVIDER: 'console',
      }),
      {
        recordOperation: jest.fn(),
      } as never,
    );

    try {
      await service.sendOtp('+79991234567', '123456');

      const logged = JSON.stringify(consoleInfo.mock.calls);
      expect(logged).toContain('dev_sms_otp_generated');
      expect(logged).not.toContain('79991234567');
      expect(logged).not.toContain('123456');
      expect(logged).toContain('[REDACTED]');
    } finally {
      consoleInfo.mockRestore();
      if (originalNodeEnv === undefined) {
        delete process.env.NODE_ENV;
      } else {
        process.env.NODE_ENV = originalNodeEnv;
      }
    }
  });

  it('fails safely on provider outage and succeeds after recovery', async () => {
    const metrics = { recordOperation: jest.fn() };
    const fetchMock = jest
      .spyOn(global, 'fetch')
      .mockRejectedValueOnce(
        new Error('network failure with provider topology details'),
      )
      .mockResolvedValueOnce({
        ok: true,
        json: () =>
          Promise.resolve({
            status: 'OK',
            sms: { '79991234567': { status: 'OK' } },
          }),
      } as Response);
    const service = new SmsService(
      new ConfigService({
        SMS_PROVIDER: 'smsru',
        SMS_API_KEY: 'test-key',
      }),
      metrics as never,
    );

    try {
      await expect(service.sendOtp('+79991234567', '123456')).rejects.toEqual(
        expect.objectContaining<InternalServerErrorException>({
          message: 'Не удалось отправить SMS',
        }),
      );
      await expect(
        service.sendOtp('+79991234567', '654321'),
      ).resolves.toBeUndefined();
      expect(fetchMock).toHaveBeenCalledTimes(2);
      expect(metrics.recordOperation.mock.calls).toEqual([
        ['sms_send', 'failure'],
        ['sms_send', 'success'],
      ]);
    } finally {
      fetchMock.mockRestore();
    }
  });

  it('normalizes an invalid provider response', async () => {
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      json: () => Promise.reject(new SyntaxError('provider body details')),
    } as Response);
    const service = new SmsService(
      new ConfigService({
        SMS_PROVIDER: 'smsru',
        SMS_API_KEY: 'test-key',
      }),
      { recordOperation: jest.fn() } as never,
    );

    try {
      await expect(service.sendOtp('+79991234567', '123456')).rejects.toEqual(
        expect.objectContaining<InternalServerErrorException>({
          message: 'SMS сервис вернул некорректный ответ',
        }),
      );
    } finally {
      fetchMock.mockRestore();
    }
  });
});
