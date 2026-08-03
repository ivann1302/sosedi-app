import { IsNotEmpty, IsString } from 'class-validator';

export class CreateUserDataExportDto {
  @IsString()
  @IsNotEmpty()
  stepUpToken!: string;
}
