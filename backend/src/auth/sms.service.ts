import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

type SmsRuPhoneStatus = {
  status?: string;
  status_code?: number;
};

type SmsRuResponse = {
  status?: string;
  status_code?: number;
  sms?: Record<string, SmsRuPhoneStatus>;
};

@Injectable()
export class SmsService {
  constructor(private readonly config: ConfigService) {}

  async sendOtp(phone: string, code: string): Promise<void> {
    const provider = this.config.get<string>('SMS_PROVIDER') ?? 'console';
    const apiKey = this.config.get<string>('SMS_API_KEY');

    // В dev OTP печатается в лог, чтобы MVP можно было поднять без SMS-договора.
    if (provider === 'console' || !apiKey || apiKey === 'change_me') {
      if (process.env.NODE_ENV === 'production') {
        throw new InternalServerErrorException('Не настроен SMS_API_KEY');
      }

      console.info(`[dev-sms] ${phone}: ${code}`);
      return;
    }

    if (provider !== 'smsru') {
      throw new InternalServerErrorException('Неизвестный SMS провайдер');
    }

    const response = await fetch('https://sms.ru/sms/send', {
      method: 'POST',
      body: new URLSearchParams({
        api_id: apiKey,
        to: phone.replace('+', ''),
        msg: `Код для входа в Соседи: ${code}`,
        json: '1',
      }),
    });

    if (!response.ok) {
      throw new InternalServerErrorException('Не удалось отправить SMS');
    }

    const body = (await response.json()) as SmsRuResponse;
    const phoneStatus = body.sms?.[phone.replace('+', '')];
    if (body.status !== 'OK' || (phoneStatus && phoneStatus.status !== 'OK')) {
      throw new InternalServerErrorException('SMS сервис не принял сообщение');
    }
  }
}
