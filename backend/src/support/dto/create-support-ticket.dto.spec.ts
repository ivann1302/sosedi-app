import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CreateSupportTicketDto } from './create-support-ticket.dto';

describe('CreateSupportTicketDto', () => {
  it('accepts a normal support request', async () => {
    const dto = plainToInstance(CreateSupportTicketDto, {
      subject: 'Вопрос по передаче',
      message: 'Нужна помощь со временем встречи.',
    });

    await expect(validate(dto)).resolves.toHaveLength(0);
  });

  it('rejects short subject and message', async () => {
    const dto = plainToInstance(CreateSupportTicketDto, {
      subject: 'Я',
      message: 'Помогите',
    });

    await expect(validate(dto)).resolves.toHaveLength(2);
  });
});
