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
mixin _$BookingNextAction {

 String get code; String get title; String get description;
/// Create a copy of BookingNextAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingNextActionCopyWith<BookingNextAction> get copyWith => _$BookingNextActionCopyWithImpl<BookingNextAction>(this as BookingNextAction, _$identity);

  /// Serializes this BookingNextAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingNextAction&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,title,description);

@override
String toString() {
  return 'BookingNextAction(code: $code, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class $BookingNextActionCopyWith<$Res>  {
  factory $BookingNextActionCopyWith(BookingNextAction value, $Res Function(BookingNextAction) _then) = _$BookingNextActionCopyWithImpl;
@useResult
$Res call({
 String code, String title, String description
});




}
/// @nodoc
class _$BookingNextActionCopyWithImpl<$Res>
    implements $BookingNextActionCopyWith<$Res> {
  _$BookingNextActionCopyWithImpl(this._self, this._then);

  final BookingNextAction _self;
  final $Res Function(BookingNextAction) _then;

/// Create a copy of BookingNextAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? title = null,Object? description = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingNextAction].
extension BookingNextActionPatterns on BookingNextAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingNextAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingNextAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingNextAction value)  $default,){
final _that = this;
switch (_that) {
case _BookingNextAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingNextAction value)?  $default,){
final _that = this;
switch (_that) {
case _BookingNextAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String title,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingNextAction() when $default != null:
return $default(_that.code,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String title,  String description)  $default,) {final _that = this;
switch (_that) {
case _BookingNextAction():
return $default(_that.code,_that.title,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String title,  String description)?  $default,) {final _that = this;
switch (_that) {
case _BookingNextAction() when $default != null:
return $default(_that.code,_that.title,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingNextAction implements BookingNextAction {
  const _BookingNextAction({required this.code, required this.title, required this.description});
  factory _BookingNextAction.fromJson(Map<String, dynamic> json) => _$BookingNextActionFromJson(json);

@override final  String code;
@override final  String title;
@override final  String description;

/// Create a copy of BookingNextAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingNextActionCopyWith<_BookingNextAction> get copyWith => __$BookingNextActionCopyWithImpl<_BookingNextAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingNextActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingNextAction&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,title,description);

@override
String toString() {
  return 'BookingNextAction(code: $code, title: $title, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BookingNextActionCopyWith<$Res> implements $BookingNextActionCopyWith<$Res> {
  factory _$BookingNextActionCopyWith(_BookingNextAction value, $Res Function(_BookingNextAction) _then) = __$BookingNextActionCopyWithImpl;
@override @useResult
$Res call({
 String code, String title, String description
});




}
/// @nodoc
class __$BookingNextActionCopyWithImpl<$Res>
    implements _$BookingNextActionCopyWith<$Res> {
  __$BookingNextActionCopyWithImpl(this._self, this._then);

  final _BookingNextAction _self;
  final $Res Function(_BookingNextAction) _then;

/// Create a copy of BookingNextAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? title = null,Object? description = null,}) {
  return _then(_BookingNextAction(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ParticipantBooking {

 String get id; String get itemId; String get actorRole; DateTime get startDate; DateTime get endDate; String get status; BookingNextAction get nextAction; DateTime? get expiresAt; String? get cancellationReason; BookingTerms? get terms; BookingHandover? get handover; String? get counterpartyContact; DateTime get createdAt;
/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantBookingCopyWith<ParticipantBooking> get copyWith => _$ParticipantBookingCopyWithImpl<ParticipantBooking>(this as ParticipantBooking, _$identity);

  /// Serializes this ParticipantBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParticipantBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.handover, handover) || other.handover == handover)&&(identical(other.counterpartyContact, counterpartyContact) || other.counterpartyContact == counterpartyContact)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,actorRole,startDate,endDate,status,nextAction,expiresAt,cancellationReason,terms,handover,counterpartyContact,createdAt);

@override
String toString() {
  return 'ParticipantBooking(id: $id, itemId: $itemId, actorRole: $actorRole, startDate: $startDate, endDate: $endDate, status: $status, nextAction: $nextAction, expiresAt: $expiresAt, cancellationReason: $cancellationReason, terms: $terms, handover: $handover, counterpartyContact: $counterpartyContact, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ParticipantBookingCopyWith<$Res>  {
  factory $ParticipantBookingCopyWith(ParticipantBooking value, $Res Function(ParticipantBooking) _then) = _$ParticipantBookingCopyWithImpl;
@useResult
$Res call({
 String id, String itemId, String actorRole, DateTime startDate, DateTime endDate, String status, BookingNextAction nextAction, DateTime? expiresAt, String? cancellationReason, BookingTerms? terms, BookingHandover? handover, String? counterpartyContact, DateTime createdAt
});


$BookingNextActionCopyWith<$Res> get nextAction;$BookingTermsCopyWith<$Res>? get terms;$BookingHandoverCopyWith<$Res>? get handover;

}
/// @nodoc
class _$ParticipantBookingCopyWithImpl<$Res>
    implements $ParticipantBookingCopyWith<$Res> {
  _$ParticipantBookingCopyWithImpl(this._self, this._then);

  final ParticipantBooking _self;
  final $Res Function(ParticipantBooking) _then;

/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = null,Object? actorRole = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? nextAction = null,Object? expiresAt = freezed,Object? cancellationReason = freezed,Object? terms = freezed,Object? handover = freezed,Object? counterpartyContact = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,actorRole: null == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,nextAction: null == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as BookingNextAction,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
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
$BookingNextActionCopyWith<$Res> get nextAction {

  return $BookingNextActionCopyWith<$Res>(_self.nextAction, (value) {
    return _then(_self.copyWith(nextAction: value));
  });
}/// Create a copy of ParticipantBooking
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String itemId,  String actorRole,  DateTime startDate,  DateTime endDate,  String status,  BookingNextAction nextAction,  DateTime? expiresAt,  String? cancellationReason,  BookingTerms? terms,  BookingHandover? handover,  String? counterpartyContact,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParticipantBooking() when $default != null:
return $default(_that.id,_that.itemId,_that.actorRole,_that.startDate,_that.endDate,_that.status,_that.nextAction,_that.expiresAt,_that.cancellationReason,_that.terms,_that.handover,_that.counterpartyContact,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String itemId,  String actorRole,  DateTime startDate,  DateTime endDate,  String status,  BookingNextAction nextAction,  DateTime? expiresAt,  String? cancellationReason,  BookingTerms? terms,  BookingHandover? handover,  String? counterpartyContact,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ParticipantBooking():
return $default(_that.id,_that.itemId,_that.actorRole,_that.startDate,_that.endDate,_that.status,_that.nextAction,_that.expiresAt,_that.cancellationReason,_that.terms,_that.handover,_that.counterpartyContact,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String itemId,  String actorRole,  DateTime startDate,  DateTime endDate,  String status,  BookingNextAction nextAction,  DateTime? expiresAt,  String? cancellationReason,  BookingTerms? terms,  BookingHandover? handover,  String? counterpartyContact,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ParticipantBooking() when $default != null:
return $default(_that.id,_that.itemId,_that.actorRole,_that.startDate,_that.endDate,_that.status,_that.nextAction,_that.expiresAt,_that.cancellationReason,_that.terms,_that.handover,_that.counterpartyContact,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParticipantBooking implements ParticipantBooking {
  const _ParticipantBooking({required this.id, required this.itemId, required this.actorRole, required this.startDate, required this.endDate, required this.status, required this.nextAction, required this.expiresAt, required this.cancellationReason, required this.terms, required this.handover, required this.counterpartyContact, required this.createdAt});
  factory _ParticipantBooking.fromJson(Map<String, dynamic> json) => _$ParticipantBookingFromJson(json);

@override final  String id;
@override final  String itemId;
@override final  String actorRole;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  String status;
@override final  BookingNextAction nextAction;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParticipantBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.terms, terms) || other.terms == terms)&&(identical(other.handover, handover) || other.handover == handover)&&(identical(other.counterpartyContact, counterpartyContact) || other.counterpartyContact == counterpartyContact)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,actorRole,startDate,endDate,status,nextAction,expiresAt,cancellationReason,terms,handover,counterpartyContact,createdAt);

@override
String toString() {
  return 'ParticipantBooking(id: $id, itemId: $itemId, actorRole: $actorRole, startDate: $startDate, endDate: $endDate, status: $status, nextAction: $nextAction, expiresAt: $expiresAt, cancellationReason: $cancellationReason, terms: $terms, handover: $handover, counterpartyContact: $counterpartyContact, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ParticipantBookingCopyWith<$Res> implements $ParticipantBookingCopyWith<$Res> {
  factory _$ParticipantBookingCopyWith(_ParticipantBooking value, $Res Function(_ParticipantBooking) _then) = __$ParticipantBookingCopyWithImpl;
@override @useResult
$Res call({
 String id, String itemId, String actorRole, DateTime startDate, DateTime endDate, String status, BookingNextAction nextAction, DateTime? expiresAt, String? cancellationReason, BookingTerms? terms, BookingHandover? handover, String? counterpartyContact, DateTime createdAt
});


@override $BookingNextActionCopyWith<$Res> get nextAction;@override $BookingTermsCopyWith<$Res>? get terms;@override $BookingHandoverCopyWith<$Res>? get handover;

}
/// @nodoc
class __$ParticipantBookingCopyWithImpl<$Res>
    implements _$ParticipantBookingCopyWith<$Res> {
  __$ParticipantBookingCopyWithImpl(this._self, this._then);

  final _ParticipantBooking _self;
  final $Res Function(_ParticipantBooking) _then;

/// Create a copy of ParticipantBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = null,Object? actorRole = null,Object? startDate = null,Object? endDate = null,Object? status = null,Object? nextAction = null,Object? expiresAt = freezed,Object? cancellationReason = freezed,Object? terms = freezed,Object? handover = freezed,Object? counterpartyContact = freezed,Object? createdAt = null,}) {
  return _then(_ParticipantBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,actorRole: null == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,nextAction: null == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as BookingNextAction,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
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
$BookingNextActionCopyWith<$Res> get nextAction {

  return $BookingNextActionCopyWith<$Res>(_self.nextAction, (value) {
    return _then(_self.copyWith(nextAction: value));
  });
}/// Create a copy of ParticipantBooking
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
mixin _$BookingIssueReceipt {

 String get id; String get status; DateTime get createdAt;
/// Create a copy of BookingIssueReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingIssueReceiptCopyWith<BookingIssueReceipt> get copyWith => _$BookingIssueReceiptCopyWithImpl<BookingIssueReceipt>(this as BookingIssueReceipt, _$identity);

  /// Serializes this BookingIssueReceipt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingIssueReceipt&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,createdAt);

@override
String toString() {
  return 'BookingIssueReceipt(id: $id, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BookingIssueReceiptCopyWith<$Res>  {
  factory $BookingIssueReceiptCopyWith(BookingIssueReceipt value, $Res Function(BookingIssueReceipt) _then) = _$BookingIssueReceiptCopyWithImpl;
@useResult
$Res call({
 String id, String status, DateTime createdAt
});




}
/// @nodoc
class _$BookingIssueReceiptCopyWithImpl<$Res>
    implements $BookingIssueReceiptCopyWith<$Res> {
  _$BookingIssueReceiptCopyWithImpl(this._self, this._then);

  final BookingIssueReceipt _self;
  final $Res Function(BookingIssueReceipt) _then;

/// Create a copy of BookingIssueReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingIssueReceipt].
extension BookingIssueReceiptPatterns on BookingIssueReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingIssueReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingIssueReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingIssueReceipt value)  $default,){
final _that = this;
switch (_that) {
case _BookingIssueReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingIssueReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _BookingIssueReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingIssueReceipt() when $default != null:
return $default(_that.id,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BookingIssueReceipt():
return $default(_that.id,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingIssueReceipt() when $default != null:
return $default(_that.id,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingIssueReceipt implements BookingIssueReceipt {
  const _BookingIssueReceipt({required this.id, required this.status, required this.createdAt});
  factory _BookingIssueReceipt.fromJson(Map<String, dynamic> json) => _$BookingIssueReceiptFromJson(json);

@override final  String id;
@override final  String status;
@override final  DateTime createdAt;

/// Create a copy of BookingIssueReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingIssueReceiptCopyWith<_BookingIssueReceipt> get copyWith => __$BookingIssueReceiptCopyWithImpl<_BookingIssueReceipt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingIssueReceiptToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingIssueReceipt&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,createdAt);

@override
String toString() {
  return 'BookingIssueReceipt(id: $id, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BookingIssueReceiptCopyWith<$Res> implements $BookingIssueReceiptCopyWith<$Res> {
  factory _$BookingIssueReceiptCopyWith(_BookingIssueReceipt value, $Res Function(_BookingIssueReceipt) _then) = __$BookingIssueReceiptCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, DateTime createdAt
});




}
/// @nodoc
class __$BookingIssueReceiptCopyWithImpl<$Res>
    implements _$BookingIssueReceiptCopyWith<$Res> {
  __$BookingIssueReceiptCopyWithImpl(this._self, this._then);

  final _BookingIssueReceipt _self;
  final $Res Function(_BookingIssueReceipt) _then;

/// Create a copy of BookingIssueReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_BookingIssueReceipt(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
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
mixin _$HandoverReadinessInput {

 bool get isWorking; bool get isComplete; String get visibleDefects;
/// Create a copy of HandoverReadinessInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HandoverReadinessInputCopyWith<HandoverReadinessInput> get copyWith => _$HandoverReadinessInputCopyWithImpl<HandoverReadinessInput>(this as HandoverReadinessInput, _$identity);

  /// Serializes this HandoverReadinessInput to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HandoverReadinessInput&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.visibleDefects, visibleDefects) || other.visibleDefects == visibleDefects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isWorking,isComplete,visibleDefects);

@override
String toString() {
  return 'HandoverReadinessInput(isWorking: $isWorking, isComplete: $isComplete, visibleDefects: $visibleDefects)';
}


}

/// @nodoc
abstract mixin class $HandoverReadinessInputCopyWith<$Res>  {
  factory $HandoverReadinessInputCopyWith(HandoverReadinessInput value, $Res Function(HandoverReadinessInput) _then) = _$HandoverReadinessInputCopyWithImpl;
@useResult
$Res call({
 bool isWorking, bool isComplete, String visibleDefects
});




}
/// @nodoc
class _$HandoverReadinessInputCopyWithImpl<$Res>
    implements $HandoverReadinessInputCopyWith<$Res> {
  _$HandoverReadinessInputCopyWithImpl(this._self, this._then);

  final HandoverReadinessInput _self;
  final $Res Function(HandoverReadinessInput) _then;

/// Create a copy of HandoverReadinessInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isWorking = null,Object? isComplete = null,Object? visibleDefects = null,}) {
  return _then(_self.copyWith(
isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,visibleDefects: null == visibleDefects ? _self.visibleDefects : visibleDefects // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HandoverReadinessInput].
extension HandoverReadinessInputPatterns on HandoverReadinessInput {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HandoverReadinessInput value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HandoverReadinessInput() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HandoverReadinessInput value)  $default,){
final _that = this;
switch (_that) {
case _HandoverReadinessInput():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HandoverReadinessInput value)?  $default,){
final _that = this;
switch (_that) {
case _HandoverReadinessInput() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isWorking,  bool isComplete,  String visibleDefects)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HandoverReadinessInput() when $default != null:
return $default(_that.isWorking,_that.isComplete,_that.visibleDefects);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isWorking,  bool isComplete,  String visibleDefects)  $default,) {final _that = this;
switch (_that) {
case _HandoverReadinessInput():
return $default(_that.isWorking,_that.isComplete,_that.visibleDefects);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isWorking,  bool isComplete,  String visibleDefects)?  $default,) {final _that = this;
switch (_that) {
case _HandoverReadinessInput() when $default != null:
return $default(_that.isWorking,_that.isComplete,_that.visibleDefects);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HandoverReadinessInput implements HandoverReadinessInput {
  const _HandoverReadinessInput({required this.isWorking, required this.isComplete, required this.visibleDefects});
  factory _HandoverReadinessInput.fromJson(Map<String, dynamic> json) => _$HandoverReadinessInputFromJson(json);

@override final  bool isWorking;
@override final  bool isComplete;
@override final  String visibleDefects;

/// Create a copy of HandoverReadinessInput
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HandoverReadinessInputCopyWith<_HandoverReadinessInput> get copyWith => __$HandoverReadinessInputCopyWithImpl<_HandoverReadinessInput>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HandoverReadinessInputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HandoverReadinessInput&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.visibleDefects, visibleDefects) || other.visibleDefects == visibleDefects));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isWorking,isComplete,visibleDefects);

@override
String toString() {
  return 'HandoverReadinessInput(isWorking: $isWorking, isComplete: $isComplete, visibleDefects: $visibleDefects)';
}


}

/// @nodoc
abstract mixin class _$HandoverReadinessInputCopyWith<$Res> implements $HandoverReadinessInputCopyWith<$Res> {
  factory _$HandoverReadinessInputCopyWith(_HandoverReadinessInput value, $Res Function(_HandoverReadinessInput) _then) = __$HandoverReadinessInputCopyWithImpl;
@override @useResult
$Res call({
 bool isWorking, bool isComplete, String visibleDefects
});




}
/// @nodoc
class __$HandoverReadinessInputCopyWithImpl<$Res>
    implements _$HandoverReadinessInputCopyWith<$Res> {
  __$HandoverReadinessInputCopyWithImpl(this._self, this._then);

  final _HandoverReadinessInput _self;
  final $Res Function(_HandoverReadinessInput) _then;

/// Create a copy of HandoverReadinessInput
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isWorking = null,Object? isComplete = null,Object? visibleDefects = null,}) {
  return _then(_HandoverReadinessInput(
isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,visibleDefects: null == visibleDefects ? _self.visibleDefects : visibleDefects // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingReadiness {

 bool get isWorking; bool get isComplete; String get visibleDefects; DateTime get declaredAt; String get declaration;
/// Create a copy of BookingReadiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingReadinessCopyWith<BookingReadiness> get copyWith => _$BookingReadinessCopyWithImpl<BookingReadiness>(this as BookingReadiness, _$identity);

  /// Serializes this BookingReadiness to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingReadiness&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.visibleDefects, visibleDefects) || other.visibleDefects == visibleDefects)&&(identical(other.declaredAt, declaredAt) || other.declaredAt == declaredAt)&&(identical(other.declaration, declaration) || other.declaration == declaration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isWorking,isComplete,visibleDefects,declaredAt,declaration);

@override
String toString() {
  return 'BookingReadiness(isWorking: $isWorking, isComplete: $isComplete, visibleDefects: $visibleDefects, declaredAt: $declaredAt, declaration: $declaration)';
}


}

/// @nodoc
abstract mixin class $BookingReadinessCopyWith<$Res>  {
  factory $BookingReadinessCopyWith(BookingReadiness value, $Res Function(BookingReadiness) _then) = _$BookingReadinessCopyWithImpl;
@useResult
$Res call({
 bool isWorking, bool isComplete, String visibleDefects, DateTime declaredAt, String declaration
});




}
/// @nodoc
class _$BookingReadinessCopyWithImpl<$Res>
    implements $BookingReadinessCopyWith<$Res> {
  _$BookingReadinessCopyWithImpl(this._self, this._then);

  final BookingReadiness _self;
  final $Res Function(BookingReadiness) _then;

/// Create a copy of BookingReadiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isWorking = null,Object? isComplete = null,Object? visibleDefects = null,Object? declaredAt = null,Object? declaration = null,}) {
  return _then(_self.copyWith(
isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,visibleDefects: null == visibleDefects ? _self.visibleDefects : visibleDefects // ignore: cast_nullable_to_non_nullable
as String,declaredAt: null == declaredAt ? _self.declaredAt : declaredAt // ignore: cast_nullable_to_non_nullable
as DateTime,declaration: null == declaration ? _self.declaration : declaration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingReadiness].
extension BookingReadinessPatterns on BookingReadiness {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingReadiness value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingReadiness() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingReadiness value)  $default,){
final _that = this;
switch (_that) {
case _BookingReadiness():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingReadiness value)?  $default,){
final _that = this;
switch (_that) {
case _BookingReadiness() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isWorking,  bool isComplete,  String visibleDefects,  DateTime declaredAt,  String declaration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingReadiness() when $default != null:
return $default(_that.isWorking,_that.isComplete,_that.visibleDefects,_that.declaredAt,_that.declaration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isWorking,  bool isComplete,  String visibleDefects,  DateTime declaredAt,  String declaration)  $default,) {final _that = this;
switch (_that) {
case _BookingReadiness():
return $default(_that.isWorking,_that.isComplete,_that.visibleDefects,_that.declaredAt,_that.declaration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isWorking,  bool isComplete,  String visibleDefects,  DateTime declaredAt,  String declaration)?  $default,) {final _that = this;
switch (_that) {
case _BookingReadiness() when $default != null:
return $default(_that.isWorking,_that.isComplete,_that.visibleDefects,_that.declaredAt,_that.declaration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingReadiness implements BookingReadiness {
  const _BookingReadiness({required this.isWorking, required this.isComplete, required this.visibleDefects, required this.declaredAt, required this.declaration});
  factory _BookingReadiness.fromJson(Map<String, dynamic> json) => _$BookingReadinessFromJson(json);

@override final  bool isWorking;
@override final  bool isComplete;
@override final  String visibleDefects;
@override final  DateTime declaredAt;
@override final  String declaration;

/// Create a copy of BookingReadiness
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingReadinessCopyWith<_BookingReadiness> get copyWith => __$BookingReadinessCopyWithImpl<_BookingReadiness>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingReadinessToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingReadiness&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.visibleDefects, visibleDefects) || other.visibleDefects == visibleDefects)&&(identical(other.declaredAt, declaredAt) || other.declaredAt == declaredAt)&&(identical(other.declaration, declaration) || other.declaration == declaration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isWorking,isComplete,visibleDefects,declaredAt,declaration);

@override
String toString() {
  return 'BookingReadiness(isWorking: $isWorking, isComplete: $isComplete, visibleDefects: $visibleDefects, declaredAt: $declaredAt, declaration: $declaration)';
}


}

/// @nodoc
abstract mixin class _$BookingReadinessCopyWith<$Res> implements $BookingReadinessCopyWith<$Res> {
  factory _$BookingReadinessCopyWith(_BookingReadiness value, $Res Function(_BookingReadiness) _then) = __$BookingReadinessCopyWithImpl;
@override @useResult
$Res call({
 bool isWorking, bool isComplete, String visibleDefects, DateTime declaredAt, String declaration
});




}
/// @nodoc
class __$BookingReadinessCopyWithImpl<$Res>
    implements _$BookingReadinessCopyWith<$Res> {
  __$BookingReadinessCopyWithImpl(this._self, this._then);

  final _BookingReadiness _self;
  final $Res Function(_BookingReadiness) _then;

/// Create a copy of BookingReadiness
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isWorking = null,Object? isComplete = null,Object? visibleDefects = null,Object? declaredAt = null,Object? declaration = null,}) {
  return _then(_BookingReadiness(
isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,visibleDefects: null == visibleDefects ? _self.visibleDefects : visibleDefects // ignore: cast_nullable_to_non_nullable
as String,declaredAt: null == declaredAt ? _self.declaredAt : declaredAt // ignore: cast_nullable_to_non_nullable
as DateTime,declaration: null == declaration ? _self.declaration : declaration // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingAct {

 String get id; String get bookingId; String get authorId; String get stage; DateTime get createdAt; String? get confirmedById; DateTime? get confirmedAt; List<BookingEvidence> get evidence; BookingReadiness? get readiness;
/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingActCopyWith<BookingAct> get copyWith => _$BookingActCopyWithImpl<BookingAct>(this as BookingAct, _$identity);

  /// Serializes this BookingAct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingAct&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.confirmedById, confirmedById) || other.confirmedById == confirmedById)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&const DeepCollectionEquality().equals(other.evidence, evidence)&&(identical(other.readiness, readiness) || other.readiness == readiness));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,authorId,stage,createdAt,confirmedById,confirmedAt,const DeepCollectionEquality().hash(evidence),readiness);

@override
String toString() {
  return 'BookingAct(id: $id, bookingId: $bookingId, authorId: $authorId, stage: $stage, createdAt: $createdAt, confirmedById: $confirmedById, confirmedAt: $confirmedAt, evidence: $evidence, readiness: $readiness)';
}


}

/// @nodoc
abstract mixin class $BookingActCopyWith<$Res>  {
  factory $BookingActCopyWith(BookingAct value, $Res Function(BookingAct) _then) = _$BookingActCopyWithImpl;
@useResult
$Res call({
 String id, String bookingId, String authorId, String stage, DateTime createdAt, String? confirmedById, DateTime? confirmedAt, List<BookingEvidence> evidence, BookingReadiness? readiness
});


$BookingReadinessCopyWith<$Res>? get readiness;

}
/// @nodoc
class _$BookingActCopyWithImpl<$Res>
    implements $BookingActCopyWith<$Res> {
  _$BookingActCopyWithImpl(this._self, this._then);

  final BookingAct _self;
  final $Res Function(BookingAct) _then;

/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bookingId = null,Object? authorId = null,Object? stage = null,Object? createdAt = null,Object? confirmedById = freezed,Object? confirmedAt = freezed,Object? evidence = null,Object? readiness = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedById: freezed == confirmedById ? _self.confirmedById : confirmedById // ignore: cast_nullable_to_non_nullable
as String?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<BookingEvidence>,readiness: freezed == readiness ? _self.readiness : readiness // ignore: cast_nullable_to_non_nullable
as BookingReadiness?,
  ));
}
/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingReadinessCopyWith<$Res>? get readiness {
    if (_self.readiness == null) {
    return null;
  }

  return $BookingReadinessCopyWith<$Res>(_self.readiness!, (value) {
    return _then(_self.copyWith(readiness: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bookingId,  String authorId,  String stage,  DateTime createdAt,  String? confirmedById,  DateTime? confirmedAt,  List<BookingEvidence> evidence,  BookingReadiness? readiness)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingAct() when $default != null:
return $default(_that.id,_that.bookingId,_that.authorId,_that.stage,_that.createdAt,_that.confirmedById,_that.confirmedAt,_that.evidence,_that.readiness);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bookingId,  String authorId,  String stage,  DateTime createdAt,  String? confirmedById,  DateTime? confirmedAt,  List<BookingEvidence> evidence,  BookingReadiness? readiness)  $default,) {final _that = this;
switch (_that) {
case _BookingAct():
return $default(_that.id,_that.bookingId,_that.authorId,_that.stage,_that.createdAt,_that.confirmedById,_that.confirmedAt,_that.evidence,_that.readiness);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bookingId,  String authorId,  String stage,  DateTime createdAt,  String? confirmedById,  DateTime? confirmedAt,  List<BookingEvidence> evidence,  BookingReadiness? readiness)?  $default,) {final _that = this;
switch (_that) {
case _BookingAct() when $default != null:
return $default(_that.id,_that.bookingId,_that.authorId,_that.stage,_that.createdAt,_that.confirmedById,_that.confirmedAt,_that.evidence,_that.readiness);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingAct implements BookingAct {
  const _BookingAct({required this.id, required this.bookingId, required this.authorId, required this.stage, required this.createdAt, required this.confirmedById, required this.confirmedAt, required final  List<BookingEvidence> evidence, this.readiness}): _evidence = evidence;
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

@override final  BookingReadiness? readiness;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingAct&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.confirmedById, confirmedById) || other.confirmedById == confirmedById)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&const DeepCollectionEquality().equals(other._evidence, _evidence)&&(identical(other.readiness, readiness) || other.readiness == readiness));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,authorId,stage,createdAt,confirmedById,confirmedAt,const DeepCollectionEquality().hash(_evidence),readiness);

@override
String toString() {
  return 'BookingAct(id: $id, bookingId: $bookingId, authorId: $authorId, stage: $stage, createdAt: $createdAt, confirmedById: $confirmedById, confirmedAt: $confirmedAt, evidence: $evidence, readiness: $readiness)';
}


}

/// @nodoc
abstract mixin class _$BookingActCopyWith<$Res> implements $BookingActCopyWith<$Res> {
  factory _$BookingActCopyWith(_BookingAct value, $Res Function(_BookingAct) _then) = __$BookingActCopyWithImpl;
@override @useResult
$Res call({
 String id, String bookingId, String authorId, String stage, DateTime createdAt, String? confirmedById, DateTime? confirmedAt, List<BookingEvidence> evidence, BookingReadiness? readiness
});


@override $BookingReadinessCopyWith<$Res>? get readiness;

}
/// @nodoc
class __$BookingActCopyWithImpl<$Res>
    implements _$BookingActCopyWith<$Res> {
  __$BookingActCopyWithImpl(this._self, this._then);

  final _BookingAct _self;
  final $Res Function(_BookingAct) _then;

/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bookingId = null,Object? authorId = null,Object? stage = null,Object? createdAt = null,Object? confirmedById = freezed,Object? confirmedAt = freezed,Object? evidence = null,Object? readiness = freezed,}) {
  return _then(_BookingAct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,authorId: null == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,confirmedById: freezed == confirmedById ? _self.confirmedById : confirmedById // ignore: cast_nullable_to_non_nullable
as String?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,evidence: null == evidence ? _self._evidence : evidence // ignore: cast_nullable_to_non_nullable
as List<BookingEvidence>,readiness: freezed == readiness ? _self.readiness : readiness // ignore: cast_nullable_to_non_nullable
as BookingReadiness?,
  ));
}

/// Create a copy of BookingAct
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingReadinessCopyWith<$Res>? get readiness {
    if (_self.readiness == null) {
    return null;
  }

  return $BookingReadinessCopyWith<$Res>(_self.readiness!, (value) {
    return _then(_self.copyWith(readiness: value));
  });
}
}


/// @nodoc
mixin _$BookingMessage {

 String get id; String get bookingId; String get author; String? get clientMessageId; String get body; DateTime get createdAt;
/// Create a copy of BookingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingMessageCopyWith<BookingMessage> get copyWith => _$BookingMessageCopyWithImpl<BookingMessage>(this as BookingMessage, _$identity);

  /// Serializes this BookingMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.author, author) || other.author == author)&&(identical(other.clientMessageId, clientMessageId) || other.clientMessageId == clientMessageId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,author,clientMessageId,body,createdAt);

@override
String toString() {
  return 'BookingMessage(id: $id, bookingId: $bookingId, author: $author, clientMessageId: $clientMessageId, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $BookingMessageCopyWith<$Res>  {
  factory $BookingMessageCopyWith(BookingMessage value, $Res Function(BookingMessage) _then) = _$BookingMessageCopyWithImpl;
@useResult
$Res call({
 String id, String bookingId, String author, String? clientMessageId, String body, DateTime createdAt
});




}
/// @nodoc
class _$BookingMessageCopyWithImpl<$Res>
    implements $BookingMessageCopyWith<$Res> {
  _$BookingMessageCopyWithImpl(this._self, this._then);

  final BookingMessage _self;
  final $Res Function(BookingMessage) _then;

/// Create a copy of BookingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bookingId = null,Object? author = null,Object? clientMessageId = freezed,Object? body = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,clientMessageId: freezed == clientMessageId ? _self.clientMessageId : clientMessageId // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingMessage].
extension BookingMessagePatterns on BookingMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingMessage value)  $default,){
final _that = this;
switch (_that) {
case _BookingMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingMessage value)?  $default,){
final _that = this;
switch (_that) {
case _BookingMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bookingId,  String author,  String? clientMessageId,  String body,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingMessage() when $default != null:
return $default(_that.id,_that.bookingId,_that.author,_that.clientMessageId,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bookingId,  String author,  String? clientMessageId,  String body,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _BookingMessage():
return $default(_that.id,_that.bookingId,_that.author,_that.clientMessageId,_that.body,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bookingId,  String author,  String? clientMessageId,  String body,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingMessage() when $default != null:
return $default(_that.id,_that.bookingId,_that.author,_that.clientMessageId,_that.body,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingMessage implements BookingMessage {
  const _BookingMessage({required this.id, required this.bookingId, required this.author, required this.clientMessageId, required this.body, required this.createdAt});
  factory _BookingMessage.fromJson(Map<String, dynamic> json) => _$BookingMessageFromJson(json);

@override final  String id;
@override final  String bookingId;
@override final  String author;
@override final  String? clientMessageId;
@override final  String body;
@override final  DateTime createdAt;

/// Create a copy of BookingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingMessageCopyWith<_BookingMessage> get copyWith => __$BookingMessageCopyWithImpl<_BookingMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.author, author) || other.author == author)&&(identical(other.clientMessageId, clientMessageId) || other.clientMessageId == clientMessageId)&&(identical(other.body, body) || other.body == body)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,author,clientMessageId,body,createdAt);

@override
String toString() {
  return 'BookingMessage(id: $id, bookingId: $bookingId, author: $author, clientMessageId: $clientMessageId, body: $body, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$BookingMessageCopyWith<$Res> implements $BookingMessageCopyWith<$Res> {
  factory _$BookingMessageCopyWith(_BookingMessage value, $Res Function(_BookingMessage) _then) = __$BookingMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String bookingId, String author, String? clientMessageId, String body, DateTime createdAt
});




}
/// @nodoc
class __$BookingMessageCopyWithImpl<$Res>
    implements _$BookingMessageCopyWith<$Res> {
  __$BookingMessageCopyWithImpl(this._self, this._then);

  final _BookingMessage _self;
  final $Res Function(_BookingMessage) _then;

/// Create a copy of BookingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bookingId = null,Object? author = null,Object? clientMessageId = freezed,Object? body = null,Object? createdAt = null,}) {
  return _then(_BookingMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,clientMessageId: freezed == clientMessageId ? _self.clientMessageId : clientMessageId // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$BookingMessagePage {

 List<BookingMessage> get items; String? get nextCursor;
/// Create a copy of BookingMessagePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingMessagePageCopyWith<BookingMessagePage> get copyWith => _$BookingMessagePageCopyWithImpl<BookingMessagePage>(this as BookingMessagePage, _$identity);

  /// Serializes this BookingMessagePage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingMessagePage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'BookingMessagePage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $BookingMessagePageCopyWith<$Res>  {
  factory $BookingMessagePageCopyWith(BookingMessagePage value, $Res Function(BookingMessagePage) _then) = _$BookingMessagePageCopyWithImpl;
@useResult
$Res call({
 List<BookingMessage> items, String? nextCursor
});




}
/// @nodoc
class _$BookingMessagePageCopyWithImpl<$Res>
    implements $BookingMessagePageCopyWith<$Res> {
  _$BookingMessagePageCopyWithImpl(this._self, this._then);

  final BookingMessagePage _self;
  final $Res Function(BookingMessagePage) _then;

/// Create a copy of BookingMessagePage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<BookingMessage>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingMessagePage].
extension BookingMessagePagePatterns on BookingMessagePage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingMessagePage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingMessagePage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingMessagePage value)  $default,){
final _that = this;
switch (_that) {
case _BookingMessagePage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingMessagePage value)?  $default,){
final _that = this;
switch (_that) {
case _BookingMessagePage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BookingMessage> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingMessagePage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BookingMessage> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _BookingMessagePage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BookingMessage> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _BookingMessagePage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingMessagePage implements BookingMessagePage {
  const _BookingMessagePage({required final  List<BookingMessage> items, required this.nextCursor}): _items = items;
  factory _BookingMessagePage.fromJson(Map<String, dynamic> json) => _$BookingMessagePageFromJson(json);

 final  List<BookingMessage> _items;
@override List<BookingMessage> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of BookingMessagePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingMessagePageCopyWith<_BookingMessagePage> get copyWith => __$BookingMessagePageCopyWithImpl<_BookingMessagePage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingMessagePageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingMessagePage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'BookingMessagePage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$BookingMessagePageCopyWith<$Res> implements $BookingMessagePageCopyWith<$Res> {
  factory _$BookingMessagePageCopyWith(_BookingMessagePage value, $Res Function(_BookingMessagePage) _then) = __$BookingMessagePageCopyWithImpl;
@override @useResult
$Res call({
 List<BookingMessage> items, String? nextCursor
});




}
/// @nodoc
class __$BookingMessagePageCopyWithImpl<$Res>
    implements _$BookingMessagePageCopyWith<$Res> {
  __$BookingMessagePageCopyWithImpl(this._self, this._then);

  final _BookingMessagePage _self;
  final $Res Function(_BookingMessagePage) _then;

/// Create a copy of BookingMessagePage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_BookingMessagePage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<BookingMessage>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
