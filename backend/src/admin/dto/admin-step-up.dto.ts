import { IsString, Matches } from 'class-validator';

export class AdminStepUpDto {
  @IsString()
  @Matches(/^(?:\d{6}|[A-Fa-f0-9]{4}(?:-[A-Fa-f0-9]{4}){4})$/, {
    message: 'Укажите 6-значный TOTP или recovery code',
  })
  code: string;
}
