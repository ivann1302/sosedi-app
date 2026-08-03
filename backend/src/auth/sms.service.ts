import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { redactSensitiveData } from '../common/logging/sensitive-data-redactor';
import { MetricsService } from '../observability/metrics.service';

type SmsRuPhoneStatus = {
  status?: string;
  status_code?: number;
};

type SmsRuResponse = {
  status?: string;
  status_code?: number;
  sms?: Record<string, SmsRuPhoneStatus>;
};

const SMS_PROVIDER_TIMEOUT_MS = 5_000;

@Injectable()
export class SmsService {
  constructor(
    private readonly config: ConfigService,
    private readonly metrics: MetricsService,
  ) {}

  async sendOtp(phone: string, code: string): Promise<void> {
    try {
      await this.sendOtpWithProvider(phone, code);
      this.metrics.recordOperation('sms_send', 'success');
    } catch (error) {
      this.metrics.recordOperation('sms_send', 'failure');
      throw error;
    }
  }

  private async sendOtpWithProvider(
    phone: string,
    code: string,
  ): Promise<void> {
    const provider = this.config.get<string>('SMS_PROVIDER') ?? 'console';
    const apiKey = this.config.get<string>('SMS_API_KEY');

    if (provider === 'console' || !apiKey || apiKey === 'change_me') {
      if (process.env.NODE_ENV === 'production') {
        throw new InternalServerErrorException('Не настроен SMS_API_KEY');
      }

      console.info(
        redactSensitiveData({
          event: 'dev_sms_otp_generated',
          phone,
          otpCode: code,
        }),
      );
      return;
    }

    if (provider !== 'smsru') {
      throw new InternalServerErrorException('Неизвестный SMS провайдер');
    }

    let response: Response;
    try {
      response = await fetch('https://sms.ru/sms/send', {
        method: 'POST',
        body: new URLSearchParams({
          api_id: apiKey,
          to: phone.replace('+', ''),
          msg: `Код для входа в Соседи: ${code}`,
          json: '1',
        }),
        signal: AbortSignal.timeout(SMS_PROVIDER_TIMEOUT_MS),
      });
    } catch {
      throw new InternalServerErrorException('Не удалось отправить SMS');
    }

    if (!response.ok) {
      throw new InternalServerErrorException('Не удалось отправить SMS');
    }

    let body: SmsRuResponse;
    try {
      body = (await response.json()) as SmsRuResponse;
    } catch {
      throw new InternalServerErrorException(
        'SMS сервис вернул некорректный ответ',
      );
    }
    const phoneStatus = body.sms?.[phone.replace('+', '')];
    if (body.status !== 'OK' || (phoneStatus && phoneStatus.status !== 'OK')) {
      throw new InternalServerErrorException('SMS сервис не принял сообщение');
    }
  }
}
