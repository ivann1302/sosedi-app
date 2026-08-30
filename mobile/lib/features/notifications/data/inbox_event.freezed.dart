// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'inbox_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InboxEvent {

 String get eventId; String? get bookingId; String? get supportTicketId; String? get itemId; String get eventType; DateTime? get readAt; DateTime get createdAt;
/// Create a copy of InboxEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxEventCopyWith<InboxEvent> get copyWith => _$InboxEventCopyWithImpl<InboxEvent>(this as InboxEvent, _$identity);

  /// Serializes this InboxEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,bookingId,supportTicketId,itemId,eventType,readAt,createdAt);

@override
String toString() {
  return 'InboxEvent(eventId: $eventId, bookingId: $bookingId, supportTicketId: $supportTicketId, itemId: $itemId, eventType: $eventType, readAt: $readAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InboxEventCopyWith<$Res>  {
  factory $InboxEventCopyWith(InboxEvent value, $Res Function(InboxEvent) _then) = _$InboxEventCopyWithImpl;
@useResult
$Res call({
 String eventId, String? bookingId, String? supportTicketId, String? itemId, String eventType, DateTime? readAt, DateTime createdAt
});




}
/// @nodoc
class _$InboxEventCopyWithImpl<$Res>
    implements $InboxEventCopyWith<$Res> {
  _$InboxEventCopyWithImpl(this._self, this._then);

  final InboxEvent _self;
  final $Res Function(InboxEvent) _then;

/// Create a copy of InboxEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? bookingId = freezed,Object? supportTicketId = freezed,Object? itemId = freezed,Object? eventType = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,supportTicketId: freezed == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxEvent].
extension InboxEventPatterns on InboxEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxEvent value)  $default,){
final _that = this;
switch (_that) {
case _InboxEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxEvent value)?  $default,){
final _that = this;
switch (_that) {
case _InboxEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String? bookingId,  String? supportTicketId,  String? itemId,  String eventType,  DateTime? readAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxEvent() when $default != null:
return $default(_that.eventId,_that.bookingId,_that.supportTicketId,_that.itemId,_that.eventType,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String? bookingId,  String? supportTicketId,  String? itemId,  String eventType,  DateTime? readAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _InboxEvent():
return $default(_that.eventId,_that.bookingId,_that.supportTicketId,_that.itemId,_that.eventType,_that.readAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String? bookingId,  String? supportTicketId,  String? itemId,  String eventType,  DateTime? readAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InboxEvent() when $default != null:
return $default(_that.eventId,_that.bookingId,_that.supportTicketId,_that.itemId,_that.eventType,_that.readAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxEvent implements InboxEvent {
  const _InboxEvent({required this.eventId, required this.bookingId, required this.supportTicketId, required this.itemId, required this.eventType, required this.readAt, required this.createdAt});
  factory _InboxEvent.fromJson(Map<String, dynamic> json) => _$InboxEventFromJson(json);

@override final  String eventId;
@override final  String? bookingId;
@override final  String? supportTicketId;
@override final  String? itemId;
@override final  String eventType;
@override final  DateTime? readAt;
@override final  DateTime createdAt;

/// Create a copy of InboxEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxEventCopyWith<_InboxEvent> get copyWith => __$InboxEventCopyWithImpl<_InboxEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxEvent&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,bookingId,supportTicketId,itemId,eventType,readAt,createdAt);

@override
String toString() {
  return 'InboxEvent(eventId: $eventId, bookingId: $bookingId, supportTicketId: $supportTicketId, itemId: $itemId, eventType: $eventType, readAt: $readAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InboxEventCopyWith<$Res> implements $InboxEventCopyWith<$Res> {
  factory _$InboxEventCopyWith(_InboxEvent value, $Res Function(_InboxEvent) _then) = __$InboxEventCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String? bookingId, String? supportTicketId, String? itemId, String eventType, DateTime? readAt, DateTime createdAt
});




}
/// @nodoc
class __$InboxEventCopyWithImpl<$Res>
    implements _$InboxEventCopyWith<$Res> {
  __$InboxEventCopyWithImpl(this._self, this._then);

  final _InboxEvent _self;
  final $Res Function(_InboxEvent) _then;

/// Create a copy of InboxEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? bookingId = freezed,Object? supportTicketId = freezed,Object? itemId = freezed,Object? eventType = null,Object? readAt = freezed,Object? createdAt = null,}) {
  return _then(_InboxEvent(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,supportTicketId: freezed == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$InboxEventDetails {

 String get eventId; String get eventType; String? get bookingId; String? get supportTicketId; String? get itemId;
/// Create a copy of InboxEventDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxEventDetailsCopyWith<InboxEventDetails> get copyWith => _$InboxEventDetailsCopyWithImpl<InboxEventDetails>(this as InboxEventDetails, _$identity);

  /// Serializes this InboxEventDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxEventDetails&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId)&&(identical(other.itemId, itemId) || other.itemId == itemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,eventType,bookingId,supportTicketId,itemId);

@override
String toString() {
  return 'InboxEventDetails(eventId: $eventId, eventType: $eventType, bookingId: $bookingId, supportTicketId: $supportTicketId, itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class $InboxEventDetailsCopyWith<$Res>  {
  factory $InboxEventDetailsCopyWith(InboxEventDetails value, $Res Function(InboxEventDetails) _then) = _$InboxEventDetailsCopyWithImpl;
@useResult
$Res call({
 String eventId, String eventType, String? bookingId, String? supportTicketId, String? itemId
});




}
/// @nodoc
class _$InboxEventDetailsCopyWithImpl<$Res>
    implements $InboxEventDetailsCopyWith<$Res> {
  _$InboxEventDetailsCopyWithImpl(this._self, this._then);

  final InboxEventDetails _self;
  final $Res Function(InboxEventDetails) _then;

/// Create a copy of InboxEventDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eventId = null,Object? eventType = null,Object? bookingId = freezed,Object? supportTicketId = freezed,Object? itemId = freezed,}) {
  return _then(_self.copyWith(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,supportTicketId: freezed == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxEventDetails].
extension InboxEventDetailsPatterns on InboxEventDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxEventDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxEventDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxEventDetails value)  $default,){
final _that = this;
switch (_that) {
case _InboxEventDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxEventDetails value)?  $default,){
final _that = this;
switch (_that) {
case _InboxEventDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String eventId,  String eventType,  String? bookingId,  String? supportTicketId,  String? itemId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxEventDetails() when $default != null:
return $default(_that.eventId,_that.eventType,_that.bookingId,_that.supportTicketId,_that.itemId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String eventId,  String eventType,  String? bookingId,  String? supportTicketId,  String? itemId)  $default,) {final _that = this;
switch (_that) {
case _InboxEventDetails():
return $default(_that.eventId,_that.eventType,_that.bookingId,_that.supportTicketId,_that.itemId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String eventId,  String eventType,  String? bookingId,  String? supportTicketId,  String? itemId)?  $default,) {final _that = this;
switch (_that) {
case _InboxEventDetails() when $default != null:
return $default(_that.eventId,_that.eventType,_that.bookingId,_that.supportTicketId,_that.itemId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxEventDetails implements InboxEventDetails {
  const _InboxEventDetails({required this.eventId, required this.eventType, this.bookingId, this.supportTicketId, this.itemId});
  factory _InboxEventDetails.fromJson(Map<String, dynamic> json) => _$InboxEventDetailsFromJson(json);

@override final  String eventId;
@override final  String eventType;
@override final  String? bookingId;
@override final  String? supportTicketId;
@override final  String? itemId;

/// Create a copy of InboxEventDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxEventDetailsCopyWith<_InboxEventDetails> get copyWith => __$InboxEventDetailsCopyWithImpl<_InboxEventDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxEventDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxEventDetails&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId)&&(identical(other.itemId, itemId) || other.itemId == itemId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eventId,eventType,bookingId,supportTicketId,itemId);

@override
String toString() {
  return 'InboxEventDetails(eventId: $eventId, eventType: $eventType, bookingId: $bookingId, supportTicketId: $supportTicketId, itemId: $itemId)';
}


}

/// @nodoc
abstract mixin class _$InboxEventDetailsCopyWith<$Res> implements $InboxEventDetailsCopyWith<$Res> {
  factory _$InboxEventDetailsCopyWith(_InboxEventDetails value, $Res Function(_InboxEventDetails) _then) = __$InboxEventDetailsCopyWithImpl;
@override @useResult
$Res call({
 String eventId, String eventType, String? bookingId, String? supportTicketId, String? itemId
});




}
/// @nodoc
class __$InboxEventDetailsCopyWithImpl<$Res>
    implements _$InboxEventDetailsCopyWith<$Res> {
  __$InboxEventDetailsCopyWithImpl(this._self, this._then);

  final _InboxEventDetails _self;
  final $Res Function(_InboxEventDetails) _then;

/// Create a copy of InboxEventDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eventId = null,Object? eventType = null,Object? bookingId = freezed,Object? supportTicketId = freezed,Object? itemId = freezed,}) {
  return _then(_InboxEventDetails(
eventId: null == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,bookingId: freezed == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String?,supportTicketId: freezed == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as String?,itemId: freezed == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InboxPage {

 List<InboxEvent> get items; String? get nextCursor;
/// Create a copy of InboxPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InboxPageCopyWith<InboxPage> get copyWith => _$InboxPageCopyWithImpl<InboxPage>(this as InboxPage, _$identity);

  /// Serializes this InboxPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InboxPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'InboxPage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $InboxPageCopyWith<$Res>  {
  factory $InboxPageCopyWith(InboxPage value, $Res Function(InboxPage) _then) = _$InboxPageCopyWithImpl;
@useResult
$Res call({
 List<InboxEvent> items, String? nextCursor
});




}
/// @nodoc
class _$InboxPageCopyWithImpl<$Res>
    implements $InboxPageCopyWith<$Res> {
  _$InboxPageCopyWithImpl(this._self, this._then);

  final InboxPage _self;
  final $Res Function(InboxPage) _then;

/// Create a copy of InboxPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<InboxEvent>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InboxPage].
extension InboxPagePatterns on InboxPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InboxPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InboxPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InboxPage value)  $default,){
final _that = this;
switch (_that) {
case _InboxPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InboxPage value)?  $default,){
final _that = this;
switch (_that) {
case _InboxPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InboxEvent> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InboxPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InboxEvent> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _InboxPage():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InboxEvent> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _InboxPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InboxPage implements InboxPage {
  const _InboxPage({required final  List<InboxEvent> items, required this.nextCursor}): _items = items;
  factory _InboxPage.fromJson(Map<String, dynamic> json) => _$InboxPageFromJson(json);

 final  List<InboxEvent> _items;
@override List<InboxEvent> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of InboxPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InboxPageCopyWith<_InboxPage> get copyWith => __$InboxPageCopyWithImpl<_InboxPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InboxPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InboxPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'InboxPage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$InboxPageCopyWith<$Res> implements $InboxPageCopyWith<$Res> {
  factory _$InboxPageCopyWith(_InboxPage value, $Res Function(_InboxPage) _then) = __$InboxPageCopyWithImpl;
@override @useResult
$Res call({
 List<InboxEvent> items, String? nextCursor
});




}
/// @nodoc
class __$InboxPageCopyWithImpl<$Res>
    implements _$InboxPageCopyWith<$Res> {
  __$InboxPageCopyWithImpl(this._self, this._then);

  final _InboxPage _self;
  final $Res Function(_InboxPage) _then;

/// Create a copy of InboxPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_InboxPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<InboxEvent>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
