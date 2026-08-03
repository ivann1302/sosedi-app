// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemAvailability _$ItemAvailabilityFromJson(Map<String, dynamic> json) =>
    _ItemAvailability(available: json['available'] as bool);

Map<String, dynamic> _$ItemAvailabilityToJson(_ItemAvailability instance) =>
    <String, dynamic>{'available': instance.available};

_BookingTerms _$BookingTermsFromJson(Map<String, dynamic> json) =>
    _BookingTerms(
      itemTitle: json['itemTitle'] as String,
      lenderDisplayName: json['lenderDisplayName'] as String?,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      days: (json['days'] as num).toInt(),
      rentalSubtotal: (json['rentalSubtotal'] as num).toDouble(),
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      ownerPayout: (json['ownerPayout'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String,
      paymentScenario: json['paymentScenario'] as String? ?? 'PAY_ON_HANDOVER',
      listingVersion: json['listingVersion'] as String,
      offerVersion: json['offerVersion'] as String?,
      cancellationPolicyVersion: json['cancellationPolicyVersion'] as String?,
    );

Map<String, dynamic> _$BookingTermsToJson(_BookingTerms instance) =>
    <String, dynamic>{
      'itemTitle': instance.itemTitle,
      'lenderDisplayName': instance.lenderDisplayName,
      'pricePerDay': instance.pricePerDay,
      'days': instance.days,
      'rentalSubtotal': instance.rentalSubtotal,
      'depositAmount': instance.depositAmount,
      'platformFee': instance.platformFee,
      'ownerPayout': instance.ownerPayout,
      'total': instance.total,
      'currency': instance.currency,
      'paymentScenario': instance.paymentScenario,
      'listingVersion': instance.listingVersion,
      'offerVersion': instance.offerVersion,
      'cancellationPolicyVersion': instance.cancellationPolicyVersion,
    };

_BookingHandover _$BookingHandoverFromJson(Map<String, dynamic> json) =>
    _BookingHandover(
      area: json['area'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$BookingHandoverToJson(_BookingHandover instance) =>
    <String, dynamic>{
      'area': instance.area,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

_ParticipantBooking _$ParticipantBookingFromJson(Map<String, dynamic> json) =>
    _ParticipantBooking(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      actorRole: json['actorRole'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: json['status'] as String,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      terms: json['terms'] == null
          ? null
          : BookingTerms.fromJson(json['terms'] as Map<String, dynamic>),
      handover: json['handover'] == null
          ? null
          : BookingHandover.fromJson(json['handover'] as Map<String, dynamic>),
      counterpartyContact: json['counterpartyContact'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ParticipantBookingToJson(_ParticipantBooking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'actorRole': instance.actorRole,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'status': instance.status,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'terms': instance.terms,
      'handover': instance.handover,
      'counterpartyContact': instance.counterpartyContact,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_BookingEvidence _$BookingEvidenceFromJson(Map<String, dynamic> json) =>
    _BookingEvidence(
      id: json['id'] as String,
      sha256: json['sha256'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookingEvidenceToJson(_BookingEvidence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sha256': instance.sha256,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_BookingAct _$BookingActFromJson(Map<String, dynamic> json) => _BookingAct(
  id: json['id'] as String,
  bookingId: json['bookingId'] as String,
  authorId: json['authorId'] as String,
  stage: json['stage'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  confirmedById: json['confirmedById'] as String?,
  confirmedAt: json['confirmedAt'] == null
      ? null
      : DateTime.parse(json['confirmedAt'] as String),
  evidence: (json['evidence'] as List<dynamic>)
      .map((e) => BookingEvidence.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BookingActToJson(_BookingAct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'authorId': instance.authorId,
      'stage': instance.stage,
      'createdAt': instance.createdAt.toIso8601String(),
      'confirmedById': instance.confirmedById,
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'evidence': instance.evidence,
    };
