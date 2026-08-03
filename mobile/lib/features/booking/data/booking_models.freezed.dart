// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItemAvailability {

 bool get available;
/// Create a copy of ItemAvailability
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemAvailabilityCopyWith<ItemAvailability> get copyWith => _$ItemAvailabilityCopyWithImpl<ItemAvailability>(this as ItemAvailability, _$identity);

  /// Serializes this ItemAvailability to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemAvailability&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available);

@override
String toString() {
  return 'ItemAvailability(available: $available)';
}


}

/// @nodoc
abstract mixin class $ItemAvailabilityCopyWith<$Res>  {
  factory $ItemAvailabilityCopyWith(ItemAvailability value, $Res Function(ItemAvailability) _then) = _$ItemAvailabilityCopyWithImpl;
@useResult
$Res call({
 bool available
});




}
/// @nodoc
class _$ItemAvailabilityCopyWithImpl<$Res>
    implements $ItemAvailabilityCopyWith<$Res> {
  _$ItemAvailabilityCopyWithImpl(this._self, this._then);

  final ItemAvailability _self;
  final $Res Function(ItemAvailability) _then;

/// Create a copy of ItemAvailability
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? available = null,}) {
  return _then(_self.copyWith(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemAvailability].
extension ItemAvailabilityPatterns on ItemAvailability {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemAvailability value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemAvailability() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemAvailability value)  $default,){
final _that = this;
switch (_that) {
case _ItemAvailability():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemAvailability value)?  $default,){
final _that = this;
switch (_that) {
case _ItemAvailability() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool available)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemAvailability() when $default != null:
return $default(_that.available);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool available)  $default,) {final _that = this;
switch (_that) {
case _ItemAvailability():
return $default(_that.available);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool available)?  $default,) {final _that = this;
switch (_that) {
case _ItemAvailability() when $default != null:
return $default(_that.available);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ItemAvailability implements ItemAvailability {
  const _ItemAvailability({required this.available});
  factory _ItemAvailability.fromJson(Map<String, dynamic> json) => _$ItemAvailabilityFromJson(json);

@override final  bool available;

/// Create a copy of ItemAvailability
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemAvailabilityCopyWith<_ItemAvailability> get copyWith => __$ItemAvailabilityCopyWithImpl<_ItemAvailability>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ItemAvailabilityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemAvailability&&(identical(other.available, available) || other.available == available));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,available);

@override
String toString() {
  return 'ItemAvailability(available: $available)';
}


}

/// @nodoc
abstract mixin class _$ItemAvailabilityCopyWith<$Res> implements $ItemAvailabilityCopyWith<$Res> {
  factory _$ItemAvailabilityCopyWith(_ItemAvailability value, $Res Function(_ItemAvailability) _then) = __$ItemAvailabilityCopyWithImpl;
@override @useResult
$Res call({
 bool available
});




}
/// @nodoc
class __$ItemAvailabilityCopyWithImpl<$Res>
    implements _$ItemAvailabilityCopyWith<$Res> {
  __$ItemAvailabilityCopyWithImpl(this._self, this._then);

  final _ItemAvailability _self;
  final $Res Function(_ItemAvailability) _then;

/// Create a copy of ItemAvailability
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? available = null,}) {
  return _then(_ItemAvailability(
available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BookingTerms {

 String get itemTitle; String? get lenderDisplayName; double get pricePerDay; int get days; double get rentalSubtotal; double? get depositAmount; double get platformFee; double get ownerPayout; double get total; String get currency; String get paymentScenario; String get listingVersion; String? get offerVersion; String? get cancellationPolicyVersion;
/// Create a copy of BookingTerms
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingTermsCopyWith<BookingTerms> get copyWith => _$BookingTermsCopyWithImpl<BookingTerms>(this as BookingTerms, _$identity);

  /// Serializes this BookingTerms to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingTerms&&(identical(other.itemTitle, itemTitle) || other.itemTitle == itemTitle)&&(identical(other.lenderDisplayName, lenderDisplayName) || other.lenderDisplayName == lenderDisplayName)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.days, days) || other.days == days)&&(identical(other.rentalSubtotal, rentalSubtotal) || other.rentalSubtotal == rentalSubtotal)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.ownerPayout, ownerPayout) || other.ownerPayout == ownerPayout)&&(identical(other.total, total) || other.total == total)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paymentScenario, paymentScenario) || other.paymentScenario == paymentScenario)&&(identical(other.listingVersion, listingVersion) || other.listingVersion == listingVersion)&&(identical(other.offerVersion, offerVersion) || other.offerVersion == offerVersion)&&(identical(other.cancellationPolicyVersion, cancellationPolicyVersion) || other.cancellationPolicyVersion == cancellationPolicyVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemTitle,lenderDisplayName,pricePerDay,days,rentalSubtotal,depositAmount,platformFee,ownerPayout,total,currency,paymentScenario,listingVersion,offerVersion,cancellationPolicyVersion);

@override
String toString() {
  return 'BookingTerms(itemTitle: $itemTitle, lenderDisplayName: $lenderDisplayName, pricePerDay: $pricePerDay, days: $days, rentalSubtotal: $rentalSubtotal, depositAmount: $depositAmount, platformFee: $platformFee, ownerPayout: $ownerPayout, total: $total, currency: $currency, paymentScenario: $paymentScenario, listingVersion: $listingVersion, offerVersion: $offerVersion, cancellationPolicyVersion: $cancellationPolicyVersion)';
}


}

/// @nodoc
abstract mixin class $BookingTermsCopyWith<$Res>  {
  factory $BookingTermsCopyWith(BookingTerms value, $Res Function(BookingTerms) _then) = _$BookingTermsCopyWithImpl;
@useResult
$Res call({
 String itemTitle, String? lenderDisplayName, double pricePerDay, int days, double rentalSubtotal, double? depositAmount, double platformFee, double ownerPayout, double total, String currency, String paymentScenario, String listingVersion, String? offerVersion, String? cancellationPolicyVersion
});




}
/// @nodoc
class _$BookingTermsCopyWithImpl<$Res>
    implements $BookingTermsCopyWith<$Res> {
  _$BookingTermsCopyWithImpl(this._self, this._then);

  final BookingTerms _self;
  final $Res Function(BookingTerms) _then;

/// Create a copy of BookingTerms
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? itemTitle = null,Object? lenderDisplayName = freezed,Object? pricePerDay = null,Object? days = null,Object? rentalSubtotal = null,Object? depositAmount = freezed,Object? platformFee = null,Object? ownerPayout = null,Object? total = null,Object? currency = null,Object? paymentScenario = null,Object? listingVersion = null,Object? offerVersion = freezed,Object? cancellationPolicyVersion = freezed,}) {
  return _then(_self.copyWith(
itemTitle: null == itemTitle ? _self.itemTitle : itemTitle // ignore: cast_nullable_to_non_nullable
as String,lenderDisplayName: freezed == lenderDisplayName ? _self.lenderDisplayName : lenderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,rentalSubtotal: null == rentalSubtotal ? _self.rentalSubtotal : rentalSubtotal // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,platformFee: null == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as double,ownerPayout: null == ownerPayout ? _self.ownerPayout : ownerPayout // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,paymentScenario: null == paymentScenario ? _self.paymentScenario : paymentScenario // ignore: cast_nullable_to_non_nullable
as String,listingVersion: null == listingVersion ? _self.listingVersion : listingVersion // ignore: cast_nullable_to_non_nullable
as String,offerVersion: freezed == offerVersion ? _self.offerVersion : offerVersion // ignore: cast_nullable_to_non_nullable
as String?,cancellationPolicyVersion: freezed == cancellationPolicyVersion ? _self.cancellationPolicyVersion : cancellationPolicyVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingTerms].
extension BookingTermsPatterns on BookingTerms {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingTerms value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingTerms() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingTerms value)  $default,){
final _that = this;
switch (_that) {
case _BookingTerms():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingTerms value)?  $default,){
final _that = this;
switch (_that) {
case _BookingTerms() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String itemTitle,  String? lenderDisplayName,  double pricePerDay,  int days,  double rentalSubtotal,  double? depositAmount,  double platformFee,  double ownerPayout,  double total,  String currency,  String paymentScenario,  String listingVersion,  String? offerVersion,  String? cancellationPolicyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingTerms() when $default != null:
return $default(_that.itemTitle,_that.lenderDisplayName,_that.pricePerDay,_that.days,_that.rentalSubtotal,_that.depositAmount,_that.platformFee,_that.ownerPayout,_that.total,_that.currency,_that.paymentScenario,_that.listingVersion,_that.offerVersion,_that.cancellationPolicyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String itemTitle,  String? lenderDisplayName,  double pricePerDay,  int days,  double rentalSubtotal,  double? depositAmount,  double platformFee,  double ownerPayout,  double total,  String currency,  String paymentScenario,  String listingVersion,  String? offerVersion,  String? cancellationPolicyVersion)  $default,) {final _that = this;
switch (_that) {
case _BookingTerms():
return $default(_that.itemTitle,_that.lenderDisplayName,_that.pricePerDay,_that.days,_that.rentalSubtotal,_that.depositAmount,_that.platformFee,_that.ownerPayout,_that.total,_that.currency,_that.paymentScenario,_that.listingVersion,_that.offerVersion,_that.cancellationPolicyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String itemTitle,  String? lenderDisplayName,  double pricePerDay,  int days,  double rentalSubtotal,  double? depositAmount,  double platformFee,  double ownerPayout,  double total,  String currency,  String paymentScenario,  String listingVersion,  String? offerVersion,  String? cancellationPolicyVersion)?  $default,) {final _that = this;
switch (_that) {
case _BookingTerms() when $default != null:
return $default(_that.itemTitle,_that.lenderDisplayName,_that.pricePerDay,_that.days,_that.rentalSubtotal,_that.depositAmount,_that.platformFee,_that.ownerPayout,_that.total,_that.currency,_that.paymentScenario,_that.listingVersion,_that.offerVersion,_that.cancellationPolicyVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingTerms implements BookingTerms {
  const _BookingTerms({required this.itemTitle, required this.lenderDisplayName, required this.pricePerDay, required this.days, required this.rentalSubtotal, required this.depositAmount, required this.platformFee, required this.ownerPayout, required this.total, required this.currency, this.paymentScenario = 'PAY_ON_HANDOVER', required this.listingVersion, required this.offerVersion, required this.cancellationPolicyVersion});
  factory _BookingTerms.fromJson(Map<String, dynamic> json) => _$BookingTermsFromJson(json);

@override final  String itemTitle;
@override final  String? lenderDisplayName;
@override final  double pricePerDay;
@override final  int days;
@override final  double rentalSubtotal;
@override final  double? depositAmount;
@override final  double platformFee;
@override final  double ownerPayout;
@override final  double total;
@override final  String currency;
@override@JsonKey() final  String paymentScenario;
@override final  String listingVersion;
@override final  String? offerVersion;
@override final  String? cancellationPolicyVersion;

/// Create a copy of BookingTerms
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingTermsCopyWith<_BookingTerms> get copyWith => __$BookingTermsCopyWithImpl<_BookingTerms>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingTermsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingTerms&&(identical(other.itemTitle, itemTitle) || other.itemTitle == itemTitle)&&(identical(other.lenderDisplayName, lenderDisplayName) || other.lenderDisplayName == lenderDisplayName)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.days, days) || other.days == days)&&(identical(other.rentalSubtotal, rentalSubtotal) || other.rentalSubtotal == rentalSubtotal)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.platformFee, platformFee) || other.platformFee == platformFee)&&(identical(other.ownerPayout, ownerPayout) || other.ownerPayout == ownerPayout)&&(identical(other.total, total) || other.total == total)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.paymentScenario, paymentScenario) || other.paymentScenario == paymentScenario)&&(identical(other.listingVersion, listingVersion) || other.listingVersion == listingVersion)&&(identical(other.offerVersion, offerVersion) || other.offerVersion == offerVersion)&&(identical(other.cancellationPolicyVersion, cancellationPolicyVersion) || other.cancellationPolicyVersion == cancellationPolicyVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,itemTitle,lenderDisplayName,pricePerDay,days,rentalSubtotal,depositAmount,platformFee,ownerPayout,total,currency,paymentScenario,listingVersion,offerVersion,cancellationPolicyVersion);

@override
String toString() {
  return 'BookingTerms(itemTitle: $itemTitle, lenderDisplayName: $lenderDisplayName, pricePerDay: $pricePerDay, days: $days, rentalSubtotal: $rentalSubtotal, depositAmount: $depositAmount, platformFee: $platformFee, ownerPayout: $ownerPayout, total: $total, currency: $currency, paymentScenario: $paymentScenario, listingVersion: $listingVersion, offerVersion: $offerVersion, cancellationPolicyVersion: $cancellationPolicyVersion)';
}


}

/// @nodoc
abstract mixin class _$BookingTermsCopyWith<$Res> implements $BookingTermsCopyWith<$Res> {
  factory _$BookingTermsCopyWith(_BookingTerms value, $Res Function(_BookingTerms) _then) = __$BookingTermsCopyWithImpl;
@override @useResult
$Res call({
 String itemTitle, String? lenderDisplayName, double pricePerDay, int days, double rentalSubtotal, double? depositAmount, double platformFee, double ownerPayout, double total, String currency, String paymentScenario, String listingVersion, String? offerVersion, String? cancellationPolicyVersion
});




}
/// @nodoc
class __$BookingTermsCopyWithImpl<$Res>
    implements _$BookingTermsCopyWith<$Res> {
  __$BookingTermsCopyWithImpl(this._self, this._then);

  final _BookingTerms _self;
  final $Res Function(_BookingTerms) _then;

/// Create a copy of BookingTerms
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? itemTitle = null,Object? lenderDisplayName = freezed,Object? pricePerDay = null,Object? days = null,Object? rentalSubtotal = null,Object? depositAmount = freezed,Object? platformFee = null,Object? ownerPayout = null,Object? total = null,Object? currency = null,Object? paymentScenario = null,Object? listingVersion = null,Object? offerVersion = freezed,Object? cancellationPolicyVersion = freezed,}) {
  return _then(_BookingTerms(
itemTitle: null == itemTitle ? _self.itemTitle : itemTitle // ignore: cast_nullable_to_non_nullable
as String,lenderDisplayName: freezed == lenderDisplayName ? _self.lenderDisplayName : lenderDisplayName // ignore: cast_nullable_to_non_nullable
as String?,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,rentalSubtotal: null == rentalSubtotal ? _self.rentalSubtotal : rentalSubtotal // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,platformFee: null == platformFee ? _self.platformFee : platformFee // ignore: cast_nullable_to_non_nullable
as double,ownerPayout: null == ownerPayout ? _self.ownerPayout : ownerPayout // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,paymentScenario: null == paymentScenario ? _self.paymentScenario : paymentScenario // ignore: cast_nullable_to_non_nullable
as String,listingVersion: null == listingVersion ? _self.listingVersion : listingVersion // ignore: cast_nullable_to_non_nullable
as String,offerVersion: freezed == offerVersion ? _self.offerVersion : offerVersion // ignore: cast_nullable_to_non_nullable
as String?,cancellationPolicyVersion: freezed == cancellationPolicyVersion ? _self.cancellationPolicyVersion : cancellationPolicyVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingHandover {

 String get area; String get address; double get latitude; double get longitude;
/// Create a copy of BookingHandover
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingHandoverCopyWith<BookingHandover> get copyWith => _$BookingHandoverCopyWithImpl<BookingHandover>(this as BookingHandover, _$identity);

  /// Serializes this BookingHandover to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingHandover&&(identical(other.area, area) || other.area == area)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,area,address,latitude,longitude);

@override
String toString() {
  return 'BookingHandover(area: $area, address: $address, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $BookingHandoverCopyWith<$Res>  {
  factory $BookingHandoverCopyWith(BookingHandover value, $Res Function(BookingHandover) _then) = _$BookingHandoverCopyWithImpl;
@useResult
$Res call({
 String area, String address, double latitude, double longitude
});




}
/// @nodoc
class _$BookingHandoverCopyWithImpl<$Res>
    implements $BookingHandoverCopyWith<$Res> {
  _$BookingHandoverCopyWithImpl(this._self, this._then);

  final BookingHandover _self;
  final $Res Function(BookingHandover) _then;

/// Create a copy of BookingHandover
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? area = null,Object? address = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingHandover].
extension BookingHandoverPatterns on BookingHandover {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingHandover value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingHandover() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingHandover value)  $default,){
final _that = this;
switch (_that) {
case _BookingHandover():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingHandover value)?  $default,){
final _that = this;
switch (_that) {
case _BookingHandover() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String area,  String address,  double latitude,  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingHandover() when $default != null:
return $default(_that.area,_that.address,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String area,  String address,  double latitude,  double longitude)  $default,) {final _that = this;
switch (_that) {
case _BookingHandover():
return $default(_that.area,_that.address,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String area,  String address,  double latitude,  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _BookingHandover() when $default != null:
return $default(_that.area,_that.address,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingHandover implements BookingHandover {
  const _BookingHandover({required this.area, required this.address, required this.latitude, required this.longitude});
  factory _BookingHandover.fromJson(Map<String, dynamic> json) => _$BookingHandoverFromJson(json);

@override final  String area;
@override final  String address;
@override final  double latitude;
@override final  double longitude;

/// Create a copy of BookingHandover
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingHandoverCopyWith<_BookingHandover> get copyWith => __$BookingHandoverCopyWithImpl<_BookingHandover>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingHandoverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingHandover&&(identical(other.area, area) || other.area == area)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,area,address,latitude,longitude);

@override
String toString() {
  return 'BookingHandover(area: $area, address: $address, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$BookingHandoverCopyWith<$Res> implements $BookingHandoverCopyWith<$Res> {
  factory _$BookingHandoverCopyWith(_BookingHandover value, $Res Function(_BookingHandover) _then) = __$BookingHandoverCopyWithImpl;
@override @useResult
$Res call({
 String area, String address, double latitude, double longitude
});




}
/// @nodoc
class __$BookingHandoverCopyWithImpl<$Res>
    implements _$BookingHandoverCopyWith<$Res> {
  __$BookingHandoverCopyWithImpl(this._self, this._then);

  final _BookingHandover _self;
  final $Res Function(_BookingHandover) _then;

/// Create a copy of BookingHandover
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? area = null,Object? address = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_BookingHandover(
area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$ParticipantBooking {

 String get id; String get itemId; String get actorRole; DateTime get startDate; DateTime get endDate; String get status; DateTime? get expiresAt; String? get cancellationReason; BookingTerms? get terms; BookingHandover? get handover; String? get counterpartyContact; DateTime get createdAt;
/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantBookingCopyWith<ParticipantBooking> get copyWith => _$ParticipantBookingCopyWithImpl<ParticipantBooking>(this as ParticipantBooking, _$identity);

  /// Serializes this ParticipantBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParticipantBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.handover, handover) || other.handover == handover)&&(identical(other.counterpartyContact, counterpartyContact) || other.counterpartyContact == counterpartyContact)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,actorRole,startDate,endDate,status,expiresAt,cancellationReason,terms,handover,counterpartyContact,createdAt);

@override
String toString() {
  return 'ParticipantBooking(id: $id, itemId: $itemId, actorRole: $actorRole, startDate: $startDate, endDate: $endDate, status: $status, expiresAt: $expiresAt, cancellationReason: $cancellationReason, terms: $terms, handover: $handover, counterpartyContact: $counterpartyContact, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ParticipantBookingCopyWith<$Res>  {
  factory $ParticipantBookingCopyWith(ParticipantBooking value, $Res Function(ParticipantBooking) _then) = _$ParticipantBookingCopyWithImpl;
@useResult
$Res call({
 String id, String itemId, String actorRole, DateTime startDate, DateTime endDate, String status, DateTime? expiresAt, String? cancellationReason, BookingTerms? terms, BookingHandover? handover, String? counterpartyContact, DateTime createdAt
});


$BookingTermsCopyWith<$Res>? get terms;$BookingHandoverCopyWith<$Res>? get handover;

}
/// @nodoc
class _$ParticipantBookingCopyWithImpl<$Res>
    implements $ParticipantBookingCopyWith<$Res> {
  _$ParticipantBookingCopyWithImpl(this._self, this._then);

  final ParticipantBooking _self;
  final $Res Function(ParticipantBooking) _then;

/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = null,Object? actorRole = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? expiresAt = freezed,Object? cancellationReason = freezed,Object? terms = freezed,Object? handover = freezed,Object? counterpartyContact = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,actorRole: null == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,terms: freezed == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as BookingTerms?,handover: freezed == handover ? _self.handover : handover // ignore: cast_nullable_to_non_nullable
as BookingHandover?,counterpartyContact: freezed == counterpartyContact ? _self.counterpartyContact : counterpartyContact // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTermsCopyWith<$Res>? get terms {
    if (_self.terms == null) {
    return null;
  }

  return $BookingTermsCopyWith<$Res>(_self.terms!, (value) {
    return _then(_self.copyWith(terms: value));
  });
}/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingHandoverCopyWith<$Res>? get handover {
    if (_self.handover == null) {
    return null;
  }

  return $BookingHandoverCopyWith<$Res>(_self.handover!, (value) {
    return _then(_self.copyWith(handover: value));
  });
}
}


/// Adds pattern-matching-related methods to [ParticipantBooking].
extension ParticipantBookingPatterns on ParticipantBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParticipantBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParticipantBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParticipantBooking value)  $default,){
final _that = this;
switch (_that) {
case _ParticipantBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParticipantBooking value)?  $default,){
final _that = this;
switch (_that) {
case _ParticipantBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String itemId,  String actorRole,  DateTime startDate,  DateTime endDate,  String status,  DateTime? expiresAt,  String? cancellationReason,  BookingTerms? terms,  BookingHandover? handover,  String? counterpartyContact,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParticipantBooking() when $default != null:
return $default(_that.id,_that.itemId,_that.actorRole,_that.startDate,_that.endDate,_that.status,_that.expiresAt,_that.cancellationReason,_that.terms,_that.handover,_that.counterpartyContact,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String itemId,  String actorRole,  DateTime startDate,  DateTime endDate,  String status,  DateTime? expiresAt,  String? cancellationReason,  BookingTerms? terms,  BookingHandover? handover,  String? counterpartyContact,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ParticipantBooking():
return $default(_that.id,_that.itemId,_that.actorRole,_that.startDate,_that.endDate,_that.status,_that.expiresAt,_that.cancellationReason,_that.terms,_that.handover,_that.counterpartyContact,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String itemId,  String actorRole,  DateTime startDate,  DateTime endDate,  String status,  DateTime? expiresAt,  String? cancellationReason,  BookingTerms? terms,  BookingHandover? handover,  String? counterpartyContact,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ParticipantBooking() when $default != null:
return $default(_that.id,_that.itemId,_that.actorRole,_that.startDate,_that.endDate,_that.status,_that.expiresAt,_that.cancellationReason,_that.terms,_that.handover,_that.counterpartyContact,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParticipantBooking implements ParticipantBooking {
  const _ParticipantBooking({required this.id, required this.itemId, required this.actorRole, required this.startDate, required this.endDate, required this.status, required this.expiresAt, required this.cancellationReason, required this.terms, required this.handover, required this.counterpartyContact, required this.createdAt});
  factory _ParticipantBooking.fromJson(Map<String, dynamic> json) => _$ParticipantBookingFromJson(json);

@override final  String id;
@override final  String itemId;
@override final  String actorRole;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  String status;
@override final  DateTime? expiresAt;
@override final  String? cancellationReason;
@override final  BookingTerms? terms;
@override final  BookingHandover? handover;
@override final  String? counterpartyContact;
@override final  DateTime createdAt;

/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantBookingCopyWith<_ParticipantBooking> get copyWith => __$ParticipantBookingCopyWithImpl<_ParticipantBooking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParticipantBookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParticipantBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.handover, handover) || other.handover == handover)&&(identical(other.counterpartyContact, counterpartyContact) || other.counterpartyContact == counterpartyContact)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,actorRole,startDate,endDate,status,expiresAt,cancellationReason,terms,handover,counterpartyContact,createdAt);

@override
String toString() {
  return 'ParticipantBooking(id: $id, itemId: $itemId, actorRole: $actorRole, startDate: $startDate, endDate: $endDate, status: $status, expiresAt: $expiresAt, cancellationReason: $cancellationReason, terms: $terms, handover: $handover, counterpartyContact: $counterpartyContact, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ParticipantBookingCopyWith<$Res> implements $ParticipantBookingCopyWith<$Res> {
  factory _$ParticipantBookingCopyWith(_ParticipantBooking value, $Res Function(_ParticipantBooking) _then) = __$ParticipantBookingCopyWithImpl;
@override @useResult
$Res call({
 String id, String itemId, String actorRole, DateTime startDate, DateTime endDate, String status, DateTime? expiresAt, String? cancellationReason, BookingTerms? terms, BookingHandover? handover, String? counterpartyContact, DateTime createdAt
});


@override $BookingTermsCopyWith<$Res>? get terms;@override $BookingHandoverCopyWith<$Res>? get handover;

}
/// @nodoc
class __$ParticipantBookingCopyWithImpl<$Res>
    implements _$ParticipantBookingCopyWith<$Res> {
  __$ParticipantBookingCopyWithImpl(this._self, this._then);

  final _ParticipantBooking _self;
  final $Res Function(_ParticipantBooking) _then;

/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = null,Object? actorRole = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? expiresAt = freezed,Object? cancellationReason = freezed,Object? terms = freezed,Object? handover = freezed,Object? counterpartyContact = freezed,Object? createdAt = null,}) {
  return _then(_ParticipantBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,actorRole: null == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,terms: freezed == terms ? _self.terms : terms // ignore: cast_nullable_to_non_nullable
as BookingTerms?,handover: freezed == handover ? _self.handover : handover // ignore: cast_nullable_to_non_nullable
as BookingHandover?,counterpartyContact: freezed == counterpartyContact ? _self.counterpartyContact : counterpartyContact // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTermsCopyWith<$Res>? get terms {
    if (_self.terms == null) {
    return null;
  }

  return $BookingTermsCopyWith<$Res>(_self.terms!, (value) {
    return _then(_self.copyWith(terms: value));
  });
}/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingHandoverCopyWith<$Res>? get handover {
    if (_self.handover == null) {
    return null;
  }

  return $BookingHandoverCopyWith<$Res>(_self.handover!, (value) {
    return _then(_self.copyWith(handover: value));
  });
}
}


/// @nodoc
mixin _$BookingEvidence {

 String get id; String get sha256; DateTime get createdAt;
/// Create a copy of BookingEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingEvidenceCopyWith<BookingEvidence> get copyWith => _$BookingEvidenceCopyWithImpl<BookingEvidence>(this as BookingEvidence, _$identity);

  /// Serializes this BookingEvidence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingEvidence&&(identical(other.id, id) || other.id == id)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sha256,createdAt);

@override
String toString() {
  return 'BookingEvidence(id: $id, sha256: $sha256, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BookingEvidenceCopyWith<$Res>  {
  factory $BookingEvidenceCopyWith(BookingEvidence value, $Res Function(BookingEvidence) _then) = _$BookingEvidenceCopyWithImpl;
@useResult
$Res call({
 String id, String sha256, DateTime createdAt
});




}
/// @nodoc
class _$BookingEvidenceCopyWithImpl<$Res>
    implements $BookingEvidenceCopyWith<$Res> {
  _$BookingEvidenceCopyWithImpl(this._self, this._then);

  final BookingEvidence _self;
  final $Res Function(BookingEvidence) _then;

/// Create a copy of BookingEvidence
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


/// Adds pattern-matching-related methods to [BookingEvidence].
extension BookingEvidencePatterns on BookingEvidence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingEvidence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingEvidence value)  $default,){
final _that = this;
switch (_that) {
case _BookingEvidence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _BookingEvidence() when $default != null:
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
case _BookingEvidence() when $default != null:
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
case _BookingEvidence():
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
case _BookingEvidence() when $default != null:
return $default(_that.id,_that.sha256,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingEvidence implements BookingEvidence {
  const _BookingEvidence({required this.id, required this.sha256, required this.createdAt});
  factory _BookingEvidence.fromJson(Map<String, dynamic> json) => _$BookingEvidenceFromJson(json);

@override final  String id;
@override final  String sha256;
@override final  DateTime createdAt;

/// Create a copy of BookingEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingEvidenceCopyWith<_BookingEvidence> get copyWith => __$BookingEvidenceCopyWithImpl<_BookingEvidence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingEvidenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingEvidence&&(identical(other.id, id) || other.id == id)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sha256,createdAt);

@override
String toString() {
  return 'BookingEvidence(id: $id, sha256: $sha256, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BookingEvidenceCopyWith<$Res> implements $BookingEvidenceCopyWith<$Res> {
  factory _$BookingEvidenceCopyWith(_BookingEvidence value, $Res Function(_BookingEvidence) _then) = __$BookingEvidenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String sha256, DateTime createdAt
});




}
/// @nodoc
class __$BookingEvidenceCopyWithImpl<$Res>
    implements _$BookingEvidenceCopyWith<$Res> {
  __$BookingEvidenceCopyWithImpl(this._self, this._then);

  final _BookingEvidence _self;
  final $Res Function(_BookingEvidence) _then;

/// Create a copy of BookingEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sha256 = null,Object? createdAt = null,}) {
  return _then(_BookingEvidence(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$BookingAct {

 String get id; String get bookingId; String get authorId; String get stage; DateTime get createdAt; String? get confirmedById; DateTime? get confirmedAt; List<BookingEvidence> get evidence;
/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingActCopyWith<BookingAct> get copyWith => _$BookingActCopyWithImpl<BookingAct>(this as BookingAct, _$identity);

  /// Serializes this BookingAct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingAct&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.confirmedById, confirmedById) || other.confirmedById == confirmedById)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&const DeepCollectionEquality().equals(other.evidence, evidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,authorId,stage,createdAt,confirmedById,confirmedAt,const DeepCollectionEquality().hash(evidence));

@override
String toString() {
  return 'BookingAct(id: $id, bookingId: $bookingId, authorId: $authorId, stage: $stage, createdAt: $createdAt, confirmedById: $confirmedById, confirmedAt: $confirmedAt, evidence: $evidence)';
}


}

/// @nodoc
abstract mixin class $BookingActCopyWith<$Res>  {
  factory $BookingActCopyWith(BookingAct value, $Res Function(BookingAct) _then) = _$BookingActCopyWithImpl;
@useResult
$Res call({
 String id, String bookingId, String authorId, String stage, DateTime createdAt, String? confirmedById, DateTime? confirmedAt, List<BookingEvidence> evidence
});




}
/// @nodoc
class _$BookingActCopyWithImpl<$Res>
    implements $BookingActCopyWith<$Res> {
  _$BookingActCopyWithImpl(this._self, this._then);

  final BookingAct _self;
  final $Res Function(BookingAct) _then;

/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bookingId = null,Object? authorId = null,Object? stage = null,Object? createdAt = null,Object? confirmedById = freezed,Object? confirmedAt = freezed,Object? evidence = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedById: freezed == confirmedById ? _self.confirmedById : confirmedById // ignore: cast_nullable_to_non_nullable
as String?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<BookingEvidence>,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingAct].
extension BookingActPatterns on BookingAct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingAct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingAct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingAct value)  $default,){
final _that = this;
switch (_that) {
case _BookingAct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingAct value)?  $default,){
final _that = this;
switch (_that) {
case _BookingAct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bookingId,  String authorId,  String stage,  DateTime createdAt,  String? confirmedById,  DateTime? confirmedAt,  List<BookingEvidence> evidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingAct() when $default != null:
return $default(_that.id,_that.bookingId,_that.authorId,_that.stage,_that.createdAt,_that.confirmedById,_that.confirmedAt,_that.evidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bookingId,  String authorId,  String stage,  DateTime createdAt,  String? confirmedById,  DateTime? confirmedAt,  List<BookingEvidence> evidence)  $default,) {final _that = this;
switch (_that) {
case _BookingAct():
return $default(_that.id,_that.bookingId,_that.authorId,_that.stage,_that.createdAt,_that.confirmedById,_that.confirmedAt,_that.evidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bookingId,  String authorId,  String stage,  DateTime createdAt,  String? confirmedById,  DateTime? confirmedAt,  List<BookingEvidence> evidence)?  $default,) {final _that = this;
switch (_that) {
case _BookingAct() when $default != null:
return $default(_that.id,_that.bookingId,_that.authorId,_that.stage,_that.createdAt,_that.confirmedById,_that.confirmedAt,_that.evidence);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingAct implements BookingAct {
  const _BookingAct({required this.id, required this.bookingId, required this.authorId, required this.stage, required this.createdAt, required this.confirmedById, required this.confirmedAt, required final  List<BookingEvidence> evidence}): _evidence = evidence;
  factory _BookingAct.fromJson(Map<String, dynamic> json) => _$BookingActFromJson(json);

@override final  String id;
@override final  String bookingId;
@override final  String authorId;
@override final  String stage;
@override final  DateTime createdAt;
@override final  String? confirmedById;
@override final  DateTime? confirmedAt;
 final  List<BookingEvidence> _evidence;
@override List<BookingEvidence> get evidence {
  if (_evidence is EqualUnmodifiableListView) return _evidence;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evidence);
}


/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingActCopyWith<_BookingAct> get copyWith => __$BookingActCopyWithImpl<_BookingAct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingActToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingAct&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.confirmedById, confirmedById) || other.confirmedById == confirmedById)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&const DeepCollectionEquality().equals(other._evidence, _evidence));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,authorId,stage,createdAt,confirmedById,confirmedAt,const DeepCollectionEquality().hash(_evidence));

@override
String toString() {
  return 'BookingAct(id: $id, bookingId: $bookingId, authorId: $authorId, stage: $stage, createdAt: $createdAt, confirmedById: $confirmedById, confirmedAt: $confirmedAt, evidence: $evidence)';
}


}

/// @nodoc
abstract mixin class _$BookingActCopyWith<$Res> implements $BookingActCopyWith<$Res> {
  factory _$BookingActCopyWith(_BookingAct value, $Res Function(_BookingAct) _then) = __$BookingActCopyWithImpl;
@override @useResult
$Res call({
 String id, String bookingId, String authorId, String stage, DateTime createdAt, String? confirmedById, DateTime? confirmedAt, List<BookingEvidence> evidence
});




}
/// @nodoc
class __$BookingActCopyWithImpl<$Res>
    implements _$BookingActCopyWith<$Res> {
  __$BookingActCopyWithImpl(this._self, this._then);

  final _BookingAct _self;
  final $Res Function(_BookingAct) _then;

/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bookingId = null,Object? authorId = null,Object? stage = null,Object? createdAt = null,Object? confirmedById = freezed,Object? confirmedAt = freezed,Object? evidence = null,}) {
  return _then(_BookingAct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedById: freezed == confirmedById ? _self.confirmedById : confirmedById // ignore: cast_nullable_to_non_nullable
as String?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,evidence: null == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<BookingEvidence>,
  ));
}


}

// dart format on
