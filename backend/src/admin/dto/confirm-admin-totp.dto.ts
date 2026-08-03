import { IsString, Matches } from 'class-validator';

export class ConfirmAdminTotpDto {
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Код TOTP должен состоять из 6 цифр' })
  code: string;
}
