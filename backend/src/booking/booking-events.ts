export const BookingEventType = {
  CREATED: 'BOOKING_CREATED',
  CONFIRMED: 'BOOKING_CONFIRMED',
  CANCELLED: 'BOOKING_CANCELLED',
  COMPETING_CANCELLED: 'BOOKING_COMPETING_CANCELLED',
  HANDOVER_CONFIRMED: 'BOOKING_HANDOVER_CONFIRMED',
  RETURN_CONFIRMED: 'BOOKING_RETURN_CONFIRMED',
  COMPLETED: 'BOOKING_COMPLETED',
  PENDING_TIMEOUT: 'BOOKING_PENDING_TIMEOUT',
} as const;

export type BookingEventType =
  (typeof BookingEventType)[keyof typeof BookingEventType];

export function bookingEventKey(
  bookingId: string,
  eventType: BookingEventType,
): string {
  return `booking:${bookingId}:${eventType}`;
}
