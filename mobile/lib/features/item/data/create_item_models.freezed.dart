// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_item_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocalCreateItemDraft {

 int get step; String? get categoryId; String? get title; String? get description; String? get condition; String? get completeness; String? get handoverTerms; String? get pricePerDay; String? get publicArea; String? get depositMode; String? get depositAmount;
/// Create a copy of LocalCreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalCreateItemDraftCopyWith<LocalCreateItemDraft> get copyWith => _$LocalCreateItemDraftCopyWithImpl<LocalCreateItemDraft>(this as LocalCreateItemDraft, _$identity);

  /// Serializes this LocalCreateItemDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalCreateItemDraft&&(identical(other.step, step) || other.step == step)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.depositMode, depositMode) || other.depositMode == depositMode)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,step,categoryId,title,description,condition,completeness,handoverTerms,pricePerDay,publicArea,depositMode,depositAmount);

@override
String toString() {
  return 'LocalCreateItemDraft(step: $step, categoryId: $categoryId, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, publicArea: $publicArea, depositMode: $depositMode, depositAmount: $depositAmount)';
}


}

/// @nodoc
abstract mixin class $LocalCreateItemDraftCopyWith<$Res>  {
  factory $LocalCreateItemDraftCopyWith(LocalCreateItemDraft value, $Res Function(LocalCreateItemDraft) _then) = _$LocalCreateItemDraftCopyWithImpl;
@useResult
$Res call({
 int step, String? categoryId, String? title, String? description, String? condition, String? completeness, String? handoverTerms, String? pricePerDay, String? publicArea, String? depositMode, String? depositAmount
});




}
/// @nodoc
class _$LocalCreateItemDraftCopyWithImpl<$Res>
    implements $LocalCreateItemDraftCopyWith<$Res> {
  _$LocalCreateItemDraftCopyWithImpl(this._self, this._then);

  final LocalCreateItemDraft _self;
  final $Res Function(LocalCreateItemDraft) _then;

/// Create a copy of LocalCreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? categoryId = freezed,Object? title = freezed,Object? description = freezed,Object? condition = freezed,Object? completeness = freezed,Object? handoverTerms = freezed,Object? pricePerDay = freezed,Object? publicArea = freezed,Object? depositMode = freezed,Object? depositAmount = freezed,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,completeness: freezed == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String?,handoverTerms: freezed == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String?,pricePerDay: freezed == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as String?,publicArea: freezed == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String?,depositMode: freezed == depositMode ? _self.depositMode : depositMode // ignore: cast_nullable_to_non_nullable
as String?,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LocalCreateItemDraft].
extension LocalCreateItemDraftPatterns on LocalCreateItemDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocalCreateItemDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocalCreateItemDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocalCreateItemDraft value)  $default,){
final _that = this;
switch (_that) {
case _LocalCreateItemDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocalCreateItemDraft value)?  $default,){
final _that = this;
switch (_that) {
case _LocalCreateItemDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int step,  String? categoryId,  String? title,  String? description,  String? condition,  String? completeness,  String? handoverTerms,  String? pricePerDay,  String? publicArea,  String? depositMode,  String? depositAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocalCreateItemDraft() when $default != null:
return $default(_that.step,_that.categoryId,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.depositMode,_that.depositAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int step,  String? categoryId,  String? title,  String? description,  String? condition,  String? completeness,  String? handoverTerms,  String? pricePerDay,  String? publicArea,  String? depositMode,  String? depositAmount)  $default,) {final _that = this;
switch (_that) {
case _LocalCreateItemDraft():
return $default(_that.step,_that.categoryId,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.depositMode,_that.depositAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int step,  String? categoryId,  String? title,  String? description,  String? condition,  String? completeness,  String? handoverTerms,  String? pricePerDay,  String? publicArea,  String? depositMode,  String? depositAmount)?  $default,) {final _that = this;
switch (_that) {
case _LocalCreateItemDraft() when $default != null:
return $default(_that.step,_that.categoryId,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.depositMode,_that.depositAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LocalCreateItemDraft implements LocalCreateItemDraft {
  const _LocalCreateItemDraft({this.step = 0, this.categoryId, this.title, this.description, this.condition, this.completeness, this.handoverTerms, this.pricePerDay, this.publicArea, this.depositMode, this.depositAmount});
  factory _LocalCreateItemDraft.fromJson(Map<String, dynamic> json) => _$LocalCreateItemDraftFromJson(json);

@override@JsonKey() final  int step;
@override final  String? categoryId;
@override final  String? title;
@override final  String? description;
@override final  String? condition;
@override final  String? completeness;
@override final  String? handoverTerms;
@override final  String? pricePerDay;
@override final  String? publicArea;
@override final  String? depositMode;
@override final  String? depositAmount;

/// Create a copy of LocalCreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocalCreateItemDraftCopyWith<_LocalCreateItemDraft> get copyWith => __$LocalCreateItemDraftCopyWithImpl<_LocalCreateItemDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LocalCreateItemDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocalCreateItemDraft&&(identical(other.step, step) || other.step == step)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.depositMode, depositMode) || other.depositMode == depositMode)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,step,categoryId,title,description,condition,completeness,handoverTerms,pricePerDay,publicArea,depositMode,depositAmount);

@override
String toString() {
  return 'LocalCreateItemDraft(step: $step, categoryId: $categoryId, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, publicArea: $publicArea, depositMode: $depositMode, depositAmount: $depositAmount)';
}


}

/// @nodoc
abstract mixin class _$LocalCreateItemDraftCopyWith<$Res> implements $LocalCreateItemDraftCopyWith<$Res> {
  factory _$LocalCreateItemDraftCopyWith(_LocalCreateItemDraft value, $Res Function(_LocalCreateItemDraft) _then) = __$LocalCreateItemDraftCopyWithImpl;
@override @useResult
$Res call({
 int step, String? categoryId, String? title, String? description, String? condition, String? completeness, String? handoverTerms, String? pricePerDay, String? publicArea, String? depositMode, String? depositAmount
});




}
/// @nodoc
class __$LocalCreateItemDraftCopyWithImpl<$Res>
    implements _$LocalCreateItemDraftCopyWith<$Res> {
  __$LocalCreateItemDraftCopyWithImpl(this._self, this._then);

  final _LocalCreateItemDraft _self;
  final $Res Function(_LocalCreateItemDraft) _then;

/// Create a copy of LocalCreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? categoryId = freezed,Object? title = freezed,Object? description = freezed,Object? condition = freezed,Object? completeness = freezed,Object? handoverTerms = freezed,Object? pricePerDay = freezed,Object? publicArea = freezed,Object? depositMode = freezed,Object? depositAmount = freezed,}) {
  return _then(_LocalCreateItemDraft(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as int,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,condition: freezed == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String?,completeness: freezed == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String?,handoverTerms: freezed == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String?,pricePerDay: freezed == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as String?,publicArea: freezed == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String?,depositMode: freezed == depositMode ? _self.depositMode : depositMode // ignore: cast_nullable_to_non_nullable
as String?,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CreateItemDraft {

 String get categoryId; String get title; String get description; String get condition; String get completeness; String get handoverTerms; double get pricePerDay; String get publicArea; String get address; double get latitude; double get longitude; bool get ownershipConfirmed; bool get conditionConfirmed; bool get completenessConfirmed; bool get safetyAndMarketplaceRulesAccepted; String get listingRulesVersion;@JsonKey(includeIfNull: false) int? get depositAmountMinor;
/// Create a copy of CreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateItemDraftCopyWith<CreateItemDraft> get copyWith => _$CreateItemDraftCopyWithImpl<CreateItemDraft>(this as CreateItemDraft, _$identity);

  /// Serializes this CreateItemDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateItemDraft&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.ownershipConfirmed, ownershipConfirmed) || other.ownershipConfirmed == ownershipConfirmed)&&(identical(other.conditionConfirmed, conditionConfirmed) || other.conditionConfirmed == conditionConfirmed)&&(identical(other.completenessConfirmed, completenessConfirmed) || other.completenessConfirmed == completenessConfirmed)&&(identical(other.safetyAndMarketplaceRulesAccepted, safetyAndMarketplaceRulesAccepted) || other.safetyAndMarketplaceRulesAccepted == safetyAndMarketplaceRulesAccepted)&&(identical(other.listingRulesVersion, listingRulesVersion) || other.listingRulesVersion == listingRulesVersion)&&(identical(other.depositAmountMinor, depositAmountMinor) || other.depositAmountMinor == depositAmountMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,title,description,condition,completeness,handoverTerms,pricePerDay,publicArea,address,latitude,longitude,ownershipConfirmed,conditionConfirmed,completenessConfirmed,safetyAndMarketplaceRulesAccepted,listingRulesVersion,depositAmountMinor);

@override
String toString() {
  return 'CreateItemDraft(categoryId: $categoryId, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, publicArea: $publicArea, address: $address, latitude: $latitude, longitude: $longitude, ownershipConfirmed: $ownershipConfirmed, conditionConfirmed: $conditionConfirmed, completenessConfirmed: $completenessConfirmed, safetyAndMarketplaceRulesAccepted: $safetyAndMarketplaceRulesAccepted, listingRulesVersion: $listingRulesVersion, depositAmountMinor: $depositAmountMinor)';
}


}

/// @nodoc
abstract mixin class $CreateItemDraftCopyWith<$Res>  {
  factory $CreateItemDraftCopyWith(CreateItemDraft value, $Res Function(CreateItemDraft) _then) = _$CreateItemDraftCopyWithImpl;
@useResult
$Res call({
 String categoryId, String title, String description, String condition, String completeness, String handoverTerms, double pricePerDay, String publicArea, String address, double latitude, double longitude, bool ownershipConfirmed, bool conditionConfirmed, bool completenessConfirmed, bool safetyAndMarketplaceRulesAccepted, String listingRulesVersion,@JsonKey(includeIfNull: false) int? depositAmountMinor
});




}
/// @nodoc
class _$CreateItemDraftCopyWithImpl<$Res>
    implements $CreateItemDraftCopyWith<$Res> {
  _$CreateItemDraftCopyWithImpl(this._self, this._then);

  final CreateItemDraft _self;
  final $Res Function(CreateItemDraft) _then;

/// Create a copy of CreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? title = null,Object? description = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? pricePerDay = null,Object? publicArea = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? ownershipConfirmed = null,Object? conditionConfirmed = null,Object? completenessConfirmed = null,Object? safetyAndMarketplaceRulesAccepted = null,Object? listingRulesVersion = null,Object? depositAmountMinor = freezed,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,publicArea: null == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,ownershipConfirmed: null == ownershipConfirmed ? _self.ownershipConfirmed : ownershipConfirmed // ignore: cast_nullable_to_non_nullable
as bool,conditionConfirmed: null == conditionConfirmed ? _self.conditionConfirmed : conditionConfirmed // ignore: cast_nullable_to_non_nullable
as bool,completenessConfirmed: null == completenessConfirmed ? _self.completenessConfirmed : completenessConfirmed // ignore: cast_nullable_to_non_nullable
as bool,safetyAndMarketplaceRulesAccepted: null == safetyAndMarketplaceRulesAccepted ? _self.safetyAndMarketplaceRulesAccepted : safetyAndMarketplaceRulesAccepted // ignore: cast_nullable_to_non_nullable
as bool,listingRulesVersion: null == listingRulesVersion ? _self.listingRulesVersion : listingRulesVersion // ignore: cast_nullable_to_non_nullable
as String,depositAmountMinor: freezed == depositAmountMinor ? _self.depositAmountMinor : depositAmountMinor // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateItemDraft].
extension CreateItemDraftPatterns on CreateItemDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateItemDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateItemDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateItemDraft value)  $default,){
final _that = this;
switch (_that) {
case _CreateItemDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateItemDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CreateItemDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categoryId,  String title,  String description,  String condition,  String completeness,  String handoverTerms,  double pricePerDay,  String publicArea,  String address,  double latitude,  double longitude,  bool ownershipConfirmed,  bool conditionConfirmed,  bool completenessConfirmed,  bool safetyAndMarketplaceRulesAccepted,  String listingRulesVersion, @JsonKey(includeIfNull: false)  int? depositAmountMinor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateItemDraft() when $default != null:
return $default(_that.categoryId,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.address,_that.latitude,_that.longitude,_that.ownershipConfirmed,_that.conditionConfirmed,_that.completenessConfirmed,_that.safetyAndMarketplaceRulesAccepted,_that.listingRulesVersion,_that.depositAmountMinor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categoryId,  String title,  String description,  String condition,  String completeness,  String handoverTerms,  double pricePerDay,  String publicArea,  String address,  double latitude,  double longitude,  bool ownershipConfirmed,  bool conditionConfirmed,  bool completenessConfirmed,  bool safetyAndMarketplaceRulesAccepted,  String listingRulesVersion, @JsonKey(includeIfNull: false)  int? depositAmountMinor)  $default,) {final _that = this;
switch (_that) {
case _CreateItemDraft():
return $default(_that.categoryId,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.address,_that.latitude,_that.longitude,_that.ownershipConfirmed,_that.conditionConfirmed,_that.completenessConfirmed,_that.safetyAndMarketplaceRulesAccepted,_that.listingRulesVersion,_that.depositAmountMinor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categoryId,  String title,  String description,  String condition,  String completeness,  String handoverTerms,  double pricePerDay,  String publicArea,  String address,  double latitude,  double longitude,  bool ownershipConfirmed,  bool conditionConfirmed,  bool completenessConfirmed,  bool safetyAndMarketplaceRulesAccepted,  String listingRulesVersion, @JsonKey(includeIfNull: false)  int? depositAmountMinor)?  $default,) {final _that = this;
switch (_that) {
case _CreateItemDraft() when $default != null:
return $default(_that.categoryId,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.address,_that.latitude,_that.longitude,_that.ownershipConfirmed,_that.conditionConfirmed,_that.completenessConfirmed,_that.safetyAndMarketplaceRulesAccepted,_that.listingRulesVersion,_that.depositAmountMinor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateItemDraft implements CreateItemDraft {
  const _CreateItemDraft({required this.categoryId, required this.title, required this.description, required this.condition, required this.completeness, required this.handoverTerms, required this.pricePerDay, required this.publicArea, required this.address, required this.latitude, required this.longitude, required this.ownershipConfirmed, required this.conditionConfirmed, required this.completenessConfirmed, required this.safetyAndMarketplaceRulesAccepted, required this.listingRulesVersion, @JsonKey(includeIfNull: false) this.depositAmountMinor});
  factory _CreateItemDraft.fromJson(Map<String, dynamic> json) => _$CreateItemDraftFromJson(json);

@override final  String categoryId;
@override final  String title;
@override final  String description;
@override final  String condition;
@override final  String completeness;
@override final  String handoverTerms;
@override final  double pricePerDay;
@override final  String publicArea;
@override final  String address;
@override final  double latitude;
@override final  double longitude;
@override final  bool ownershipConfirmed;
@override final  bool conditionConfirmed;
@override final  bool completenessConfirmed;
@override final  bool safetyAndMarketplaceRulesAccepted;
@override final  String listingRulesVersion;
@override@JsonKey(includeIfNull: false) final  int? depositAmountMinor;

/// Create a copy of CreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateItemDraftCopyWith<_CreateItemDraft> get copyWith => __$CreateItemDraftCopyWithImpl<_CreateItemDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateItemDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateItemDraft&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.ownershipConfirmed, ownershipConfirmed) || other.ownershipConfirmed == ownershipConfirmed)&&(identical(other.conditionConfirmed, conditionConfirmed) || other.conditionConfirmed == conditionConfirmed)&&(identical(other.completenessConfirmed, completenessConfirmed) || other.completenessConfirmed == completenessConfirmed)&&(identical(other.safetyAndMarketplaceRulesAccepted, safetyAndMarketplaceRulesAccepted) || other.safetyAndMarketplaceRulesAccepted == safetyAndMarketplaceRulesAccepted)&&(identical(other.listingRulesVersion, listingRulesVersion) || other.listingRulesVersion == listingRulesVersion)&&(identical(other.depositAmountMinor, depositAmountMinor) || other.depositAmountMinor == depositAmountMinor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,title,description,condition,completeness,handoverTerms,pricePerDay,publicArea,address,latitude,longitude,ownershipConfirmed,conditionConfirmed,completenessConfirmed,safetyAndMarketplaceRulesAccepted,listingRulesVersion,depositAmountMinor);

@override
String toString() {
  return 'CreateItemDraft(categoryId: $categoryId, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, publicArea: $publicArea, address: $address, latitude: $latitude, longitude: $longitude, ownershipConfirmed: $ownershipConfirmed, conditionConfirmed: $conditionConfirmed, completenessConfirmed: $completenessConfirmed, safetyAndMarketplaceRulesAccepted: $safetyAndMarketplaceRulesAccepted, listingRulesVersion: $listingRulesVersion, depositAmountMinor: $depositAmountMinor)';
}


}

/// @nodoc
abstract mixin class _$CreateItemDraftCopyWith<$Res> implements $CreateItemDraftCopyWith<$Res> {
  factory _$CreateItemDraftCopyWith(_CreateItemDraft value, $Res Function(_CreateItemDraft) _then) = __$CreateItemDraftCopyWithImpl;
@override @useResult
$Res call({
 String categoryId, String title, String description, String condition, String completeness, String handoverTerms, double pricePerDay, String publicArea, String address, double latitude, double longitude, bool ownershipConfirmed, bool conditionConfirmed, bool completenessConfirmed, bool safetyAndMarketplaceRulesAccepted, String listingRulesVersion,@JsonKey(includeIfNull: false) int? depositAmountMinor
});




}
/// @nodoc
class __$CreateItemDraftCopyWithImpl<$Res>
    implements _$CreateItemDraftCopyWith<$Res> {
  __$CreateItemDraftCopyWithImpl(this._self, this._then);

  final _CreateItemDraft _self;
  final $Res Function(_CreateItemDraft) _then;

/// Create a copy of CreateItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? title = null,Object? description = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? pricePerDay = null,Object? publicArea = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? ownershipConfirmed = null,Object? conditionConfirmed = null,Object? completenessConfirmed = null,Object? safetyAndMarketplaceRulesAccepted = null,Object? listingRulesVersion = null,Object? depositAmountMinor = freezed,}) {
  return _then(_CreateItemDraft(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,publicArea: null == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,ownershipConfirmed: null == ownershipConfirmed ? _self.ownershipConfirmed : ownershipConfirmed // ignore: cast_nullable_to_non_nullable
as bool,conditionConfirmed: null == conditionConfirmed ? _self.conditionConfirmed : conditionConfirmed // ignore: cast_nullable_to_non_nullable
as bool,completenessConfirmed: null == completenessConfirmed ? _self.completenessConfirmed : completenessConfirmed // ignore: cast_nullable_to_non_nullable
as bool,safetyAndMarketplaceRulesAccepted: null == safetyAndMarketplaceRulesAccepted ? _self.safetyAndMarketplaceRulesAccepted : safetyAndMarketplaceRulesAccepted // ignore: cast_nullable_to_non_nullable
as bool,listingRulesVersion: null == listingRulesVersion ? _self.listingRulesVersion : listingRulesVersion // ignore: cast_nullable_to_non_nullable
as String,depositAmountMinor: freezed == depositAmountMinor ? _self.depositAmountMinor : depositAmountMinor // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CreateItemResult {

 String get id; String get status; bool get isUploadingPhotos; bool get photoUploadFailed;
/// Create a copy of CreateItemResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateItemResultCopyWith<CreateItemResult> get copyWith => _$CreateItemResultCopyWithImpl<CreateItemResult>(this as CreateItemResult, _$identity);

  /// Serializes this CreateItemResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateItemResult&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.isUploadingPhotos, isUploadingPhotos) || other.isUploadingPhotos == isUploadingPhotos)&&(identical(other.photoUploadFailed, photoUploadFailed) || other.photoUploadFailed == photoUploadFailed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,isUploadingPhotos,photoUploadFailed);

@override
String toString() {
  return 'CreateItemResult(id: $id, status: $status, isUploadingPhotos: $isUploadingPhotos, photoUploadFailed: $photoUploadFailed)';
}


}

/// @nodoc
abstract mixin class $CreateItemResultCopyWith<$Res>  {
  factory $CreateItemResultCopyWith(CreateItemResult value, $Res Function(CreateItemResult) _then) = _$CreateItemResultCopyWithImpl;
@useResult
$Res call({
 String id, String status, bool isUploadingPhotos, bool photoUploadFailed
});




}
/// @nodoc
class _$CreateItemResultCopyWithImpl<$Res>
    implements $CreateItemResultCopyWith<$Res> {
  _$CreateItemResultCopyWithImpl(this._self, this._then);

  final CreateItemResult _self;
  final $Res Function(CreateItemResult) _then;

/// Create a copy of CreateItemResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? isUploadingPhotos = null,Object? photoUploadFailed = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isUploadingPhotos: null == isUploadingPhotos ? _self.isUploadingPhotos : isUploadingPhotos // ignore: cast_nullable_to_non_nullable
as bool,photoUploadFailed: null == photoUploadFailed ? _self.photoUploadFailed : photoUploadFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateItemResult].
extension CreateItemResultPatterns on CreateItemResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateItemResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateItemResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateItemResult value)  $default,){
final _that = this;
switch (_that) {
case _CreateItemResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateItemResult value)?  $default,){
final _that = this;
switch (_that) {
case _CreateItemResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String status,  bool isUploadingPhotos,  bool photoUploadFailed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateItemResult() when $default != null:
return $default(_that.id,_that.status,_that.isUploadingPhotos,_that.photoUploadFailed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String status,  bool isUploadingPhotos,  bool photoUploadFailed)  $default,) {final _that = this;
switch (_that) {
case _CreateItemResult():
return $default(_that.id,_that.status,_that.isUploadingPhotos,_that.photoUploadFailed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String status,  bool isUploadingPhotos,  bool photoUploadFailed)?  $default,) {final _that = this;
switch (_that) {
case _CreateItemResult() when $default != null:
return $default(_that.id,_that.status,_that.isUploadingPhotos,_that.photoUploadFailed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateItemResult implements CreateItemResult {
  const _CreateItemResult({required this.id, required this.status, this.isUploadingPhotos = false, this.photoUploadFailed = false});
  factory _CreateItemResult.fromJson(Map<String, dynamic> json) => _$CreateItemResultFromJson(json);

@override final  String id;
@override final  String status;
@override@JsonKey() final  bool isUploadingPhotos;
@override@JsonKey() final  bool photoUploadFailed;

/// Create a copy of CreateItemResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateItemResultCopyWith<_CreateItemResult> get copyWith => __$CreateItemResultCopyWithImpl<_CreateItemResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateItemResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateItemResult&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.isUploadingPhotos, isUploadingPhotos) || other.isUploadingPhotos == isUploadingPhotos)&&(identical(other.photoUploadFailed, photoUploadFailed) || other.photoUploadFailed == photoUploadFailed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,isUploadingPhotos,photoUploadFailed);

@override
String toString() {
  return 'CreateItemResult(id: $id, status: $status, isUploadingPhotos: $isUploadingPhotos, photoUploadFailed: $photoUploadFailed)';
}


}

/// @nodoc
abstract mixin class _$CreateItemResultCopyWith<$Res> implements $CreateItemResultCopyWith<$Res> {
  factory _$CreateItemResultCopyWith(_CreateItemResult value, $Res Function(_CreateItemResult) _then) = __$CreateItemResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String status, bool isUploadingPhotos, bool photoUploadFailed
});




}
/// @nodoc
class __$CreateItemResultCopyWithImpl<$Res>
    implements _$CreateItemResultCopyWith<$Res> {
  __$CreateItemResultCopyWithImpl(this._self, this._then);

  final _CreateItemResult _self;
  final $Res Function(_CreateItemResult) _then;

/// Create a copy of CreateItemResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? isUploadingPhotos = null,Object? photoUploadFailed = null,}) {
  return _then(_CreateItemResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isUploadingPhotos: null == isUploadingPhotos ? _self.isUploadingPhotos : isUploadingPhotos // ignore: cast_nullable_to_non_nullable
as bool,photoUploadFailed: null == photoUploadFailed ? _self.photoUploadFailed : photoUploadFailed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
