import { BookingStatus } from '@prisma/client';

export type BookingActorRole = 'BORROWER' | 'LENDER';

export type BookingNextAction = {
  code:
    | 'WAIT_LENDER'
    | 'REVIEW_REQUEST'
    | 'PREPARE_HANDOVER'
    | 'USE_ITEM'
    | 'WAIT_RETURN'
    | 'REVIEW_RETURN'
    | 'LEAVE_REVIEW'
    | 'NONE';
  title: string;
  description: string;
};

export function bookingNextAction(
  status: BookingStatus,
  actorRole: BookingActorRole,
): BookingNextAction {
  if (status === BookingStatus.PENDING) {
    return actorRole === 'LENDER'
      ? {
          code: 'REVIEW_REQUEST',
          title: 'Ответьте на заявку',
          description:
            'Проверьте даты и условия, затем подтвердите или отклоните заявку.',
        }
      : {
          code: 'WAIT_LENDER',
          title: 'Ожидайте ответ владельца',
          description: 'Владелец должен подтвердить или отклонить заявку.',
        };
  }
  if (status === BookingStatus.CONFIRMED) {
    return {
      code: 'PREPARE_HANDOVER',
      title: 'Подготовьтесь к передаче',
      description: 'Согласуйте время в чате и проверьте акт передачи.',
    };
  }
  if (status === BookingStatus.ACTIVE) {
    return actorRole === 'LENDER'
      ? {
          code: 'WAIT_RETURN',
          title: 'Ожидайте возврат вещи',
          description: 'Оставайтесь на связи и проверьте вещь при возврате.',
        }
      : {
          code: 'USE_ITEM',
          title: 'Верните вещь в согласованный срок',
          description: 'Сохраните комплектность и согласуйте возврат в чате.',
        };
  }
  if (status === BookingStatus.RETURNED) {
    return {
      code: 'REVIEW_RETURN',
      title: 'Возврат подтверждён',
      description: 'Если есть вопрос по аренде, напишите в поддержку.',
    };
  }
  if (status === BookingStatus.COMPLETED) {
    return {
      code: 'LEAVE_REVIEW',
      title: 'Оставьте отзыв',
      description: 'Поделитесь опытом завершённой аренды.',
    };
  }
  return {
    code: 'NONE',
    title: 'Заявка завершена',
    description: 'Новых действий по этой заявке нет.',
  };
}
