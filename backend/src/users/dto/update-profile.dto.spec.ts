import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { UpdateProfileDto } from './update-profile.dto';

describe('UpdateProfileDto', () => {
  it('rejects a direct avatar URL so replacement must use upload quarantine', async () => {
    const dto = plainToInstance(UpdateProfileDto, {
      avatarUrl: 'https://attacker.example/avatar.jpg',
    });

    const errors = await validate(dto, {
      whitelist: true,
      forbidNonWhitelisted: true,
    });

    expect(errors).toEqual([
      expect.objectContaining({ property: 'avatarUrl' }),
    ]);
  });
});
