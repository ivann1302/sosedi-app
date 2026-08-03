import { Matches } from 'class-validator';

export class VerifyUserStepUpOtpDto {
  @Matches(/^\d{6}$/, { message: 'Код должен состоять из 6 цифр' })
  code!: string;
}
