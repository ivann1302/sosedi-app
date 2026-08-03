import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_models.freezed.dart';
part 'booking_models.g.dart';

@freezed
abstract class ItemAvailability with _$ItemAvailability {
  const factory ItemAvailability({required bool available}) = _ItemAvailability;

  factory ItemAvailability.fromJson(Map<String, dynamic> json) =>
      _$ItemAvailabilityFromJson(json);
}

@freezed
abstract class BookingTerms with _$BookingTerms {
  const factory BookingTerms({
    required String itemTitle,
    required String? lenderDisplayName,
    required double pricePerDay,
    required int days,
    required double rentalSubtotal,
    required double? depositAmount,
    required double platformFee,
    required double ownerPayout,
    required double total,
    required String currency,
    @Default('PAY_ON_HANDOVER') String paymentScenario,
    required String listingVersion,
    required String? offerVersion,
    required String? cancellationPolicyVersion,
  }) = _BookingTerms;

  factory BookingTerms.fromJson(Map<String, dynamic> json) =>
      _$BookingTermsFromJson(json);
}

@freezed
abstract class BookingHandover with _$BookingHandover {
  const factory BookingHandover({
    required String area,
    required String address,
    required double latitude,
    required double longitude,
  }) = _BookingHandover;

  factory BookingHandover.fromJson(Map<String, dynamic> json) =>
      _$BookingHandoverFromJson(json);
}

@freezed
abstract class ParticipantBooking with _$ParticipantBooking {
  const factory ParticipantBooking({
    required String id,
    required String itemId,
    required String actorRole,
    required DateTime startDate,
    required DateTime endDate,
    required String status,
    required DateTime? expiresAt,
    required String? cancellationReason,
    required BookingTerms? terms,
    required BookingHandover? handover,
    required String? counterpartyContact,
    required DateTime createdAt,
  }) = _ParticipantBooking;

  factory ParticipantBooking.fromJson(Map<String, dynamic> json) =>
      _$ParticipantBookingFromJson(json);
}

@freezed
abstract class BookingEvidence with _$BookingEvidence {
  const factory BookingEvidence({
    required String id,
    required String sha256,
    required DateTime createdAt,
  }) = _BookingEvidence;

  factory BookingEvidence.fromJson(Map<String, dynamic> json) =>
      _$BookingEvidenceFromJson(json);
}

@freezed
abstract class BookingAct with _$BookingAct {
  const factory BookingAct({
    required String id,
    required String bookingId,
    required String authorId,
    required String stage,
    required DateTime createdAt,
    required String? confirmedById,
    required DateTime? confirmedAt,
    required List<BookingEvidence> evidence,
  }) = _BookingAct;

  factory BookingAct.fromJson(Map<String, dynamic> json) =>
      _$BookingActFromJson(json);
}
