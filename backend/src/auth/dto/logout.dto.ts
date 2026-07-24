import { IsJWT, IsNotEmpty, IsString } from 'class-validator';

export class LogoutDto {
  @IsString()
  @IsNotEmpty()
  @IsJWT()
  refreshToken!: string;
}
