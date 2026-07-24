import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  phone!: string;

  @IsString()
  @Matches(/^\d{6}$/, { message: 'Код должен состоять из 6 цифр' })
  code!: string;
}
