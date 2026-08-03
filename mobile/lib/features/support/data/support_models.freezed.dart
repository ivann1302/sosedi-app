// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportTicket {

 String get id; String get type; String? get bookingId; String? get bookingIssueReason; String get subject; String get message; String get status; String? get adminResponse; DateTime? get respondedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<SupportTicket> get copyWith => _$SupportTicketCopyWithImpl<SupportTicket>(this as SupportTicket, _$identity);

  /// Serializes this SupportTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.bookingIssueReason, bookingIssueReason) || other.bookingIssueReason == bookingIssueReason)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminResponse, adminResponse) || other.adminResponse == adminResponse)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,bookingId,bookingIssueReason,subject,message,status,adminResponse,respondedAt,createdAt,updatedAt);

@override
String toString() {
  return 'SupportTicket(id: $id, type: $type, bookingId: $bookingId, bookingIssueReason: $bookingIssueReason, subject: $subject, message: $message, status: $status, adminResponse: $adminResponse, respondedAt: $respondedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SupportTicketCopyWith<$Res>  {
  factory $SupportTicketCopyWith(SupportTicket value, $Res Function(SupportTicket) _then) = _$SupportTicketCopyWithImpl;
@useResult
$Res call({
 String id, String type, String? bookingId, String? bookingIssueReason, String subject, String message, String status, String? adminResponse, DateTime? respondedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$SupportTicketCopyWithImpl<$Res>
    implements $SupportTicketCopyWith<$Res> {
  _$SupportTicketCopyWithImpl(this._self, this._then);

  final SupportTicket _self;
  final $Res Function(SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? bookingId = freezed,Object? bookingIssueReason = freezed,Object? subject = null,Object? message = null,Object? status = null,Object? adminResponse = freezed,Object? respondedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,bookingIssueReason: freezed == bookingIssueReason ? _self.bookingIssueReason : bookingIssueReason // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminResponse: freezed == adminResponse ? _self.adminResponse : adminResponse // ignore: cast_nullable_to_non_nullable
as String?,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportTicket].
extension SupportTicketPatterns on SupportTicket {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicket value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicket():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicket value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  String? bookingId,  String? bookingIssueReason,  String subject,  String message,  String status,  String? adminResponse,  DateTime? respondedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.type,_that.bookingId,_that.bookingIssueReason,_that.subject,_that.message,_that.status,_that.adminResponse,_that.respondedAt,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  String? bookingId,  String? bookingIssueReason,  String subject,  String message,  String status,  String? adminResponse,  DateTime? respondedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SupportTicket():
return $default(_that.id,_that.type,_that.bookingId,_that.bookingIssueReason,_that.subject,_that.message,_that.status,_that.adminResponse,_that.respondedAt,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  String? bookingId,  String? bookingIssueReason,  String subject,  String message,  String status,  String? adminResponse,  DateTime? respondedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.type,_that.bookingId,_that.bookingIssueReason,_that.subject,_that.message,_that.status,_that.adminResponse,_that.respondedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicket implements SupportTicket {
  const _SupportTicket({required this.id, required this.type, required this.bookingId, required this.bookingIssueReason, required this.subject, required this.message, required this.status, required this.adminResponse, required this.respondedAt, required this.createdAt, required this.updatedAt});
  factory _SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

@override final  String id;
@override final  String type;
@override final  String? bookingId;
@override final  String? bookingIssueReason;
@override final  String subject;
@override final  String message;
@override final  String status;
@override final  String? adminResponse;
@override final  DateTime? respondedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketCopyWith<_SupportTicket> get copyWith => __$SupportTicketCopyWithImpl<_SupportTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.bookingIssueReason, bookingIssueReason) || other.bookingIssueReason == bookingIssueReason)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.adminResponse, adminResponse) || other.adminResponse == adminResponse)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,bookingId,bookingIssueReason,subject,message,status,adminResponse,respondedAt,createdAt,updatedAt);

@override
String toString() {
  return 'SupportTicket(id: $id, type: $type, bookingId: $bookingId, bookingIssueReason: $bookingIssueReason, subject: $subject, message: $message, status: $status, adminResponse: $adminResponse, respondedAt: $respondedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketCopyWith<$Res> implements $SupportTicketCopyWith<$Res> {
  factory _$SupportTicketCopyWith(_SupportTicket value, $Res Function(_SupportTicket) _then) = __$SupportTicketCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, String? bookingId, String? bookingIssueReason, String subject, String message, String status, String? adminResponse, DateTime? respondedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$SupportTicketCopyWithImpl<$Res>
    implements _$SupportTicketCopyWith<$Res> {
  __$SupportTicketCopyWithImpl(this._self, this._then);

  final _SupportTicket _self;
  final $Res Function(_SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? bookingId = freezed,Object? bookingIssueReason = freezed,Object? subject = null,Object? message = null,Object? status = null,Object? adminResponse = freezed,Object? respondedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_SupportTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,bookingIssueReason: freezed == bookingIssueReason ? _self.bookingIssueReason : bookingIssueReason // ignore: cast_nullable_to_non_nullable
as String?,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,adminResponse: freezed == adminResponse ? _self.adminResponse : adminResponse // ignore: cast_nullable_to_non_nullable
as String?,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CreateSupportTicketDraft {

 String get subject; String get message;
/// Create a copy of CreateSupportTicketDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateSupportTicketDraftCopyWith<CreateSupportTicketDraft> get copyWith => _$CreateSupportTicketDraftCopyWithImpl<CreateSupportTicketDraft>(this as CreateSupportTicketDraft, _$identity);

  /// Serializes this CreateSupportTicketDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateSupportTicketDraft&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subject,message);

@override
String toString() {
  return 'CreateSupportTicketDraft(subject: $subject, message: $message)';
}


}

/// @nodoc
abstract mixin class $CreateSupportTicketDraftCopyWith<$Res>  {
  factory $CreateSupportTicketDraftCopyWith(CreateSupportTicketDraft value, $Res Function(CreateSupportTicketDraft) _then) = _$CreateSupportTicketDraftCopyWithImpl;
@useResult
$Res call({
 String subject, String message
});




}
/// @nodoc
class _$CreateSupportTicketDraftCopyWithImpl<$Res>
    implements $CreateSupportTicketDraftCopyWith<$Res> {
  _$CreateSupportTicketDraftCopyWithImpl(this._self, this._then);

  final CreateSupportTicketDraft _self;
  final $Res Function(CreateSupportTicketDraft) _then;

/// Create a copy of CreateSupportTicketDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subject = null,Object? message = null,}) {
  return _then(_self.copyWith(
subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateSupportTicketDraft].
extension CreateSupportTicketDraftPatterns on CreateSupportTicketDraft {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateSupportTicketDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateSupportTicketDraft() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateSupportTicketDraft value)  $default,){
final _that = this;
switch (_that) {
case _CreateSupportTicketDraft():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateSupportTicketDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CreateSupportTicketDraft() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String subject,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateSupportTicketDraft() when $default != null:
return $default(_that.subject,_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String subject,  String message)  $default,) {final _that = this;
switch (_that) {
case _CreateSupportTicketDraft():
return $default(_that.subject,_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String subject,  String message)?  $default,) {final _that = this;
switch (_that) {
case _CreateSupportTicketDraft() when $default != null:
return $default(_that.subject,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateSupportTicketDraft implements CreateSupportTicketDraft {
  const _CreateSupportTicketDraft({required this.subject, required this.message});
  factory _CreateSupportTicketDraft.fromJson(Map<String, dynamic> json) => _$CreateSupportTicketDraftFromJson(json);

@override final  String subject;
@override final  String message;

/// Create a copy of CreateSupportTicketDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateSupportTicketDraftCopyWith<_CreateSupportTicketDraft> get copyWith => __$CreateSupportTicketDraftCopyWithImpl<_CreateSupportTicketDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateSupportTicketDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateSupportTicketDraft&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subject,message);

@override
String toString() {
  return 'CreateSupportTicketDraft(subject: $subject, message: $message)';
}


}

/// @nodoc
abstract mixin class _$CreateSupportTicketDraftCopyWith<$Res> implements $CreateSupportTicketDraftCopyWith<$Res> {
  factory _$CreateSupportTicketDraftCopyWith(_CreateSupportTicketDraft value, $Res Function(_CreateSupportTicketDraft) _then) = __$CreateSupportTicketDraftCopyWithImpl;
@override @useResult
$Res call({
 String subject, String message
});




}
/// @nodoc
class __$CreateSupportTicketDraftCopyWithImpl<$Res>
    implements _$CreateSupportTicketDraftCopyWith<$Res> {
  __$CreateSupportTicketDraftCopyWithImpl(this._self, this._then);

  final _CreateSupportTicketDraft _self;
  final $Res Function(_CreateSupportTicketDraft) _then;

/// Create a copy of CreateSupportTicketDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subject = null,Object? message = null,}) {
  return _then(_CreateSupportTicketDraft(
subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SupportAttachment {

 String get id; String get sha256; DateTime get createdAt;
/// Create a copy of SupportAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportAttachmentCopyWith<SupportAttachment> get copyWith => _$SupportAttachmentCopyWithImpl<SupportAttachment>(this as SupportAttachment, _$identity);

  /// Serializes this SupportAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sha256,createdAt);

@override
String toString() {
  return 'SupportAttachment(id: $id, sha256: $sha256, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SupportAttachmentCopyWith<$Res>  {
  factory $SupportAttachmentCopyWith(SupportAttachment value, $Res Function(SupportAttachment) _then) = _$SupportAttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String sha256, DateTime createdAt
});




}
/// @nodoc
class _$SupportAttachmentCopyWithImpl<$Res>
    implements $SupportAttachmentCopyWith<$Res> {
  _$SupportAttachmentCopyWithImpl(this._self, this._then);

  final SupportAttachment _self;
  final $Res Function(SupportAttachment) _then;

/// Create a copy of SupportAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sha256 = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportAttachment].
extension SupportAttachmentPatterns on SupportAttachment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportAttachment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportAttachment value)  $default,){
final _that = this;
switch (_that) {
case _SupportAttachment():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _SupportAttachment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sha256,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportAttachment() when $default != null:
return $default(_that.id,_that.sha256,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sha256,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportAttachment():
return $default(_that.id,_that.sha256,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sha256,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportAttachment() when $default != null:
return $default(_that.id,_that.sha256,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportAttachment implements SupportAttachment {
  const _SupportAttachment({required this.id, required this.sha256, required this.createdAt});
  factory _SupportAttachment.fromJson(Map<String, dynamic> json) => _$SupportAttachmentFromJson(json);

@override final  String id;
@override final  String sha256;
@override final  DateTime createdAt;

/// Create a copy of SupportAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportAttachmentCopyWith<_SupportAttachment> get copyWith => __$SupportAttachmentCopyWithImpl<_SupportAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sha256,createdAt);

@override
String toString() {
  return 'SupportAttachment(id: $id, sha256: $sha256, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportAttachmentCopyWith<$Res> implements $SupportAttachmentCopyWith<$Res> {
  factory _$SupportAttachmentCopyWith(_SupportAttachment value, $Res Function(_SupportAttachment) _then) = __$SupportAttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String sha256, DateTime createdAt
});




}
/// @nodoc
class __$SupportAttachmentCopyWithImpl<$Res>
    implements _$SupportAttachmentCopyWith<$Res> {
  __$SupportAttachmentCopyWithImpl(this._self, this._then);

  final _SupportAttachment _self;
  final $Res Function(_SupportAttachment) _then;

/// Create a copy of SupportAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sha256 = null,Object? createdAt = null,}) {
  return _then(_SupportAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$SupportMessage {

 String get id; String get authorRole; String get body; List<SupportAttachment> get attachments; DateTime get createdAt;
/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportMessageCopyWith<SupportMessage> get copyWith => _$SupportMessageCopyWithImpl<SupportMessage>(this as SupportMessage, _$identity);

  /// Serializes this SupportMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorRole, authorRole) || other.authorRole == authorRole)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorRole,body,const DeepCollectionEquality().hash(attachments),createdAt);

@override
String toString() {
  return 'SupportMessage(id: $id, authorRole: $authorRole, body: $body, attachments: $attachments, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SupportMessageCopyWith<$Res>  {
  factory $SupportMessageCopyWith(SupportMessage value, $Res Function(SupportMessage) _then) = _$SupportMessageCopyWithImpl;
@useResult
$Res call({
 String id, String authorRole, String body, List<SupportAttachment> attachments, DateTime createdAt
});




}
/// @nodoc
class _$SupportMessageCopyWithImpl<$Res>
    implements $SupportMessageCopyWith<$Res> {
  _$SupportMessageCopyWithImpl(this._self, this._then);

  final SupportMessage _self;
  final $Res Function(SupportMessage) _then;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorRole = null,Object? body = null,Object? attachments = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorRole: null == authorRole ? _self.authorRole : authorRole // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<SupportAttachment>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportMessage].
extension SupportMessagePatterns on SupportMessage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportMessage value)  $default,){
final _that = this;
switch (_that) {
case _SupportMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorRole,  String body,  List<SupportAttachment> attachments,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that.id,_that.authorRole,_that.body,_that.attachments,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorRole,  String body,  List<SupportAttachment> attachments,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportMessage():
return $default(_that.id,_that.authorRole,_that.body,_that.attachments,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorRole,  String body,  List<SupportAttachment> attachments,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that.id,_that.authorRole,_that.body,_that.attachments,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportMessage implements SupportMessage {
  const _SupportMessage({required this.id, required this.authorRole, required this.body, required final  List<SupportAttachment> attachments, required this.createdAt}): _attachments = attachments;
  factory _SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);

@override final  String id;
@override final  String authorRole;
@override final  String body;
 final  List<SupportAttachment> _attachments;
@override List<SupportAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override final  DateTime createdAt;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportMessageCopyWith<_SupportMessage> get copyWith => __$SupportMessageCopyWithImpl<_SupportMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorRole, authorRole) || other.authorRole == authorRole)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorRole,body,const DeepCollectionEquality().hash(_attachments),createdAt);

@override
String toString() {
  return 'SupportMessage(id: $id, authorRole: $authorRole, body: $body, attachments: $attachments, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportMessageCopyWith<$Res> implements $SupportMessageCopyWith<$Res> {
  factory _$SupportMessageCopyWith(_SupportMessage value, $Res Function(_SupportMessage) _then) = __$SupportMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorRole, String body, List<SupportAttachment> attachments, DateTime createdAt
});




}
/// @nodoc
class __$SupportMessageCopyWithImpl<$Res>
    implements _$SupportMessageCopyWith<$Res> {
  __$SupportMessageCopyWithImpl(this._self, this._then);

  final _SupportMessage _self;
  final $Res Function(_SupportMessage) _then;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorRole = null,Object? body = null,Object? attachments = null,Object? createdAt = null,}) {
  return _then(_SupportMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorRole: null == authorRole ? _self.authorRole : authorRole // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<SupportAttachment>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
