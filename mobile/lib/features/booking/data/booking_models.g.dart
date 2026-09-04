// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItemAvailability _$ItemAvailabilityFromJson(Map<String, dynamic> json) =>
    _ItemAvailability(available: json['available'] as bool);

Map<String, dynamic> _$ItemAvailabilityToJson(_ItemAvailability instance) =>
    <String, dynamic>{'available': instance.available};

_BookingMoneyMinor _$BookingMoneyMinorFromJson(Map<String, dynamic> json) =>
    _BookingMoneyMinor(
      pricePerDay: _exactSafeIntegerFromJson(json['pricePerDay'] as Object),
      rentalSubtotal: _exactSafeIntegerFromJson(
        json['rentalSubtotal'] as Object,
      ),
      deposit: _exactSafeIntegerFromJson(json['deposit'] as Object),
      platformFee: _exactSafeIntegerFromJson(json['platformFee'] as Object),
      ownerPayout: _exactSafeIntegerFromJson(json['ownerPayout'] as Object),
      total: _exactSafeIntegerFromJson(json['total'] as Object),
    );

Map<String, dynamic> _$BookingMoneyMinorToJson(_BookingMoneyMinor instance) =>
    <String, dynamic>{
      'pricePerDay': instance.pricePerDay,
      'rentalSubtotal': instance.rentalSubtotal,
      'deposit': instance.deposit,
      'platformFee': instance.platformFee,
      'ownerPayout': instance.ownerPayout,
      'total': instance.total,
    };

_BookingDepositTerms _$BookingDepositTermsFromJson(Map<String, dynamic> json) =>
    _BookingDepositTerms(
      policyVersion: json['policyVersion'] as String,
      disputeWindowSeconds: _exactSafeIntegerFromJson(
        json['disputeWindowSeconds'] as Object,
      ),
    );

Map<String, dynamic> _$BookingDepositTermsToJson(
  _BookingDepositTerms instance,
) => <String, dynamic>{
  'policyVersion': instance.policyVersion,
  'disputeWindowSeconds': instance.disputeWindowSeconds,
};

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
      moneyMinor: json['moneyMinor'] == null
          ? null
          : BookingMoneyMinor.fromJson(
              json['moneyMinor'] as Map<String, dynamic>,
            ),
      depositTerms: json['depositTerms'] == null
          ? null
          : BookingDepositTerms.fromJson(
              json['depositTerms'] as Map<String, dynamic>,
            ),
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
      'moneyMinor': instance.moneyMinor,
      'depositTerms': instance.depositTerms,
      'listingVersion': instance.listingVersion,
      'offerVersion': instance.offerVersion,
      'cancellationPolicyVersion': instance.cancellationPolicyVersion,
    };

_ParticipantPayment _$ParticipantPaymentFromJson(Map<String, dynamic> json) =>
    _ParticipantPayment(
      amountMinor: _exactSafeIntegerFromJson(json['amountMinor'] as Object),
      status: json['status'] as String,
    );

Map<String, dynamic> _$ParticipantPaymentToJson(_ParticipantPayment instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'status': instance.status,
    };

_ParticipantDeposit _$ParticipantDepositFromJson(Map<String, dynamic> json) =>
    _ParticipantDeposit(
      amountMinor: _exactSafeIntegerFromJson(json['amountMinor'] as Object),
      status: json['status'] as String,
      refundedMinor: _exactSafeIntegerFromJson(json['refundedMinor'] as Object),
      releasedToLenderMinor: _exactSafeIntegerFromJson(
        json['releasedToLenderMinor'] as Object,
      ),
      policyVersion: json['policyVersion'] as String,
      disputeWindowEndsAt: json['disputeWindowEndsAt'] == null
          ? null
          : DateTime.parse(json['disputeWindowEndsAt'] as String),
    );

Map<String, dynamic> _$ParticipantDepositToJson(_ParticipantDeposit instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'status': instance.status,
      'refundedMinor': instance.refundedMinor,
      'releasedToLenderMinor': instance.releasedToLenderMinor,
      'policyVersion': instance.policyVersion,
      'disputeWindowEndsAt': instance.disputeWindowEndsAt?.toIso8601String(),
    };

_FinancialDisputeEvidence _$FinancialDisputeEvidenceFromJson(
  Map<String, dynamic> json,
) => _FinancialDisputeEvidence(
  id: json['id'] as String,
  sha256: json['sha256'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$FinancialDisputeEvidenceToJson(
  _FinancialDisputeEvidence instance,
) => <String, dynamic>{
  'id': instance.id,
  'sha256': instance.sha256,
  'createdAt': instance.createdAt.toIso8601String(),
};

_FinancialDispute _$FinancialDisputeFromJson(Map<String, dynamic> json) =>
    _FinancialDispute(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      openedById: json['openedById'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      evidence: (json['evidence'] as List<dynamic>)
          .map(
            (e) => FinancialDisputeEvidence.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$FinancialDisputeToJson(_FinancialDispute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'openedById': instance.openedById,
      'reason': instance.reason,
      'description': instance.description,
      'status': instance.status,
      'openedAt': instance.openedAt.toIso8601String(),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'evidence': instance.evidence,
    };

_FakeCheckoutResult _$FakeCheckoutResultFromJson(Map<String, dynamic> json) =>
    _FakeCheckoutResult(
      outcome: json['outcome'] as String,
      errorCode: json['errorCode'] as String?,
    );

Map<String, dynamic> _$FakeCheckoutResultToJson(_FakeCheckoutResult instance) =>
    <String, dynamic>{
      'outcome': instance.outcome,
      'errorCode': instance.errorCode,
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

_BookingNextAction _$BookingNextActionFromJson(Map<String, dynamic> json) =>
    _BookingNextAction(
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$BookingNextActionToJson(_BookingNextAction instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
    };

_ParticipantBooking _$ParticipantBookingFromJson(
  Map<String, dynamic> json,
) => _ParticipantBooking(
  id: json['id'] as String,
  itemId: json['itemId'] as String,
  actorRole: json['actorRole'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  status: json['status'] as String,
  nextAction: BookingNextAction.fromJson(
    json['nextAction'] as Map<String, dynamic>,
  ),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  cancellationReason: json['cancellationReason'] as String?,
  terms: json['terms'] == null
      ? null
      : BookingTerms.fromJson(json['terms'] as Map<String, dynamic>),
  payment: json['payment'] == null
      ? null
      : ParticipantPayment.fromJson(json['payment'] as Map<String, dynamic>),
  deposit: json['deposit'] == null
      ? null
      : ParticipantDeposit.fromJson(json['deposit'] as Map<String, dynamic>),
  financialDispute: json['financialDispute'] == null
      ? null
      : FinancialDispute.fromJson(
          json['financialDispute'] as Map<String, dynamic>,
        ),
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
      'nextAction': instance.nextAction,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'cancellationReason': instance.cancellationReason,
      'terms': instance.terms,
      'payment': instance.payment,
      'deposit': instance.deposit,
      'financialDispute': instance.financialDispute,
      'handover': instance.handover,
      'counterpartyContact': instance.counterpartyContact,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_BookingIssueReceipt _$BookingIssueReceiptFromJson(Map<String, dynamic> json) =>
    _BookingIssueReceipt(
      id: json['id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookingIssueReceiptToJson(
  _BookingIssueReceipt instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
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

_HandoverReadinessInput _$HandoverReadinessInputFromJson(
  Map<String, dynamic> json,
) => _HandoverReadinessInput(
  isWorking: json['isWorking'] as bool,
  isComplete: json['isComplete'] as bool,
  visibleDefects: json['visibleDefects'] as String,
);

Map<String, dynamic> _$HandoverReadinessInputToJson(
  _HandoverReadinessInput instance,
) => <String, dynamic>{
  'isWorking': instance.isWorking,
  'isComplete': instance.isComplete,
  'visibleDefects': instance.visibleDefects,
};

_BookingReadiness _$BookingReadinessFromJson(Map<String, dynamic> json) =>
    _BookingReadiness(
      isWorking: json['isWorking'] as bool,
      isComplete: json['isComplete'] as bool,
      visibleDefects: json['visibleDefects'] as String,
      declaredAt: DateTime.parse(json['declaredAt'] as String),
      declaration: json['declaration'] as String,
    );

Map<String, dynamic> _$BookingReadinessToJson(_BookingReadiness instance) =>
    <String, dynamic>{
      'isWorking': instance.isWorking,
      'isComplete': instance.isComplete,
      'visibleDefects': instance.visibleDefects,
      'declaredAt': instance.declaredAt.toIso8601String(),
      'declaration': instance.declaration,
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
  readiness: json['readiness'] == null
      ? null
      : BookingReadiness.fromJson(json['readiness'] as Map<String, dynamic>),
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
      'readiness': instance.readiness,
    };

_BookingMessage _$BookingMessageFromJson(Map<String, dynamic> json) =>
    _BookingMessage(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      author: json['author'] as String,
      clientMessageId: json['clientMessageId'] as String?,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookingMessageToJson(_BookingMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookingId': instance.bookingId,
      'author': instance.author,
      'clientMessageId': instance.clientMessageId,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_BookingMessagePage _$BookingMessagePageFromJson(Map<String, dynamic> json) =>
    _BookingMessagePage(
      items: (json['items'] as List<dynamic>)
          .map((e) => BookingMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$BookingMessagePageToJson(_BookingMessagePage instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
