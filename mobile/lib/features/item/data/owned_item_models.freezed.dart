// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'owned_item_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OwnedItem {

 String get id; String get title; String get description; String get condition; String get completeness; String get handoverTerms; String get status; String get publicArea; String get address;@JsonKey(fromJson: _doubleFromJson) double get latitude;@JsonKey(fromJson: _doubleFromJson) double get longitude;@JsonKey(fromJson: _doubleFromJson) double get pricePerDay;@JsonKey(fromJson: _nullableDoubleFromJson) double? get depositAmount; CatalogCategory get category; DateTime get updatedAt; List<CatalogPhoto> get photos; String? get rejectReason;
/// Create a copy of OwnedItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OwnedItemCopyWith<OwnedItem> get copyWith => _$OwnedItemCopyWithImpl<OwnedItem>(this as OwnedItem, _$identity);

  /// Serializes this OwnedItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OwnedItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.status, status) || other.status == status)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,condition,completeness,handoverTerms,status,publicArea,address,latitude,longitude,pricePerDay,depositAmount,category,updatedAt,const DeepCollectionEquality().hash(photos),rejectReason);

@override
String toString() {
  return 'OwnedItem(id: $id, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, status: $status, publicArea: $publicArea, address: $address, latitude: $latitude, longitude: $longitude, pricePerDay: $pricePerDay, depositAmount: $depositAmount, category: $category, updatedAt: $updatedAt, photos: $photos, rejectReason: $rejectReason)';
}


}

/// @nodoc
abstract mixin class $OwnedItemCopyWith<$Res>  {
  factory $OwnedItemCopyWith(OwnedItem value, $Res Function(OwnedItem) _then) = _$OwnedItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String condition, String completeness, String handoverTerms, String status, String publicArea, String address,@JsonKey(fromJson: _doubleFromJson) double latitude,@JsonKey(fromJson: _doubleFromJson) double longitude,@JsonKey(fromJson: _doubleFromJson) double pricePerDay,@JsonKey(fromJson: _nullableDoubleFromJson) double? depositAmount, CatalogCategory category, DateTime updatedAt, List<CatalogPhoto> photos, String? rejectReason
});


$CatalogCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$OwnedItemCopyWithImpl<$Res>
    implements $OwnedItemCopyWith<$Res> {
  _$OwnedItemCopyWithImpl(this._self, this._then);

  final OwnedItem _self;
  final $Res Function(OwnedItem) _then;

/// Create a copy of OwnedItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? status = null,Object? publicArea = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? pricePerDay = null,Object? depositAmount = freezed,Object? category = null,Object? updatedAt = null,Object? photos = null,Object? rejectReason = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,publicArea: null == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CatalogCategory,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<CatalogPhoto>,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of OwnedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogCategoryCopyWith<$Res> get category {
  
  return $CatalogCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [OwnedItem].
extension OwnedItemPatterns on OwnedItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OwnedItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OwnedItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OwnedItem value)  $default,){
final _that = this;
switch (_that) {
case _OwnedItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OwnedItem value)?  $default,){
final _that = this;
switch (_that) {
case _OwnedItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String condition,  String completeness,  String handoverTerms,  String status,  String publicArea,  String address, @JsonKey(fromJson: _doubleFromJson)  double latitude, @JsonKey(fromJson: _doubleFromJson)  double longitude, @JsonKey(fromJson: _doubleFromJson)  double pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson)  double? depositAmount,  CatalogCategory category,  DateTime updatedAt,  List<CatalogPhoto> photos,  String? rejectReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OwnedItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.status,_that.publicArea,_that.address,_that.latitude,_that.longitude,_that.pricePerDay,_that.depositAmount,_that.category,_that.updatedAt,_that.photos,_that.rejectReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String condition,  String completeness,  String handoverTerms,  String status,  String publicArea,  String address, @JsonKey(fromJson: _doubleFromJson)  double latitude, @JsonKey(fromJson: _doubleFromJson)  double longitude, @JsonKey(fromJson: _doubleFromJson)  double pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson)  double? depositAmount,  CatalogCategory category,  DateTime updatedAt,  List<CatalogPhoto> photos,  String? rejectReason)  $default,) {final _that = this;
switch (_that) {
case _OwnedItem():
return $default(_that.id,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.status,_that.publicArea,_that.address,_that.latitude,_that.longitude,_that.pricePerDay,_that.depositAmount,_that.category,_that.updatedAt,_that.photos,_that.rejectReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String condition,  String completeness,  String handoverTerms,  String status,  String publicArea,  String address, @JsonKey(fromJson: _doubleFromJson)  double latitude, @JsonKey(fromJson: _doubleFromJson)  double longitude, @JsonKey(fromJson: _doubleFromJson)  double pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson)  double? depositAmount,  CatalogCategory category,  DateTime updatedAt,  List<CatalogPhoto> photos,  String? rejectReason)?  $default,) {final _that = this;
switch (_that) {
case _OwnedItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.status,_that.publicArea,_that.address,_that.latitude,_that.longitude,_that.pricePerDay,_that.depositAmount,_that.category,_that.updatedAt,_that.photos,_that.rejectReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OwnedItem implements OwnedItem {
  const _OwnedItem({required this.id, required this.title, required this.description, required this.condition, required this.completeness, required this.handoverTerms, required this.status, required this.publicArea, required this.address, @JsonKey(fromJson: _doubleFromJson) required this.latitude, @JsonKey(fromJson: _doubleFromJson) required this.longitude, @JsonKey(fromJson: _doubleFromJson) required this.pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson) required this.depositAmount, required this.category, required this.updatedAt, required final  List<CatalogPhoto> photos, this.rejectReason}): _photos = photos;
  factory _OwnedItem.fromJson(Map<String, dynamic> json) => _$OwnedItemFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String condition;
@override final  String completeness;
@override final  String handoverTerms;
@override final  String status;
@override final  String publicArea;
@override final  String address;
@override@JsonKey(fromJson: _doubleFromJson) final  double latitude;
@override@JsonKey(fromJson: _doubleFromJson) final  double longitude;
@override@JsonKey(fromJson: _doubleFromJson) final  double pricePerDay;
@override@JsonKey(fromJson: _nullableDoubleFromJson) final  double? depositAmount;
@override final  CatalogCategory category;
@override final  DateTime updatedAt;
 final  List<CatalogPhoto> _photos;
@override List<CatalogPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  String? rejectReason;

/// Create a copy of OwnedItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OwnedItemCopyWith<_OwnedItem> get copyWith => __$OwnedItemCopyWithImpl<_OwnedItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OwnedItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OwnedItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.status, status) || other.status == status)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.rejectReason, rejectReason) || other.rejectReason == rejectReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,condition,completeness,handoverTerms,status,publicArea,address,latitude,longitude,pricePerDay,depositAmount,category,updatedAt,const DeepCollectionEquality().hash(_photos),rejectReason);

@override
String toString() {
  return 'OwnedItem(id: $id, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, status: $status, publicArea: $publicArea, address: $address, latitude: $latitude, longitude: $longitude, pricePerDay: $pricePerDay, depositAmount: $depositAmount, category: $category, updatedAt: $updatedAt, photos: $photos, rejectReason: $rejectReason)';
}


}

/// @nodoc
abstract mixin class _$OwnedItemCopyWith<$Res> implements $OwnedItemCopyWith<$Res> {
  factory _$OwnedItemCopyWith(_OwnedItem value, $Res Function(_OwnedItem) _then) = __$OwnedItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String condition, String completeness, String handoverTerms, String status, String publicArea, String address,@JsonKey(fromJson: _doubleFromJson) double latitude,@JsonKey(fromJson: _doubleFromJson) double longitude,@JsonKey(fromJson: _doubleFromJson) double pricePerDay,@JsonKey(fromJson: _nullableDoubleFromJson) double? depositAmount, CatalogCategory category, DateTime updatedAt, List<CatalogPhoto> photos, String? rejectReason
});


@override $CatalogCategoryCopyWith<$Res> get category;

}
/// @nodoc
class __$OwnedItemCopyWithImpl<$Res>
    implements _$OwnedItemCopyWith<$Res> {
  __$OwnedItemCopyWithImpl(this._self, this._then);

  final _OwnedItem _self;
  final $Res Function(_OwnedItem) _then;

/// Create a copy of OwnedItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? status = null,Object? publicArea = null,Object? address = null,Object? latitude = null,Object? longitude = null,Object? pricePerDay = null,Object? depositAmount = freezed,Object? category = null,Object? updatedAt = null,Object? photos = null,Object? rejectReason = freezed,}) {
  return _then(_OwnedItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,publicArea: null == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CatalogCategory,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<CatalogPhoto>,rejectReason: freezed == rejectReason ? _self.rejectReason : rejectReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of OwnedItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogCategoryCopyWith<$Res> get category {
  
  return $CatalogCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$UpdateItemDraft {

 String get title; String get description; String get categoryId; String get condition; String get completeness; String get handoverTerms; double get pricePerDay; String get publicArea; String get address; double get latitude; double get longitude;
/// Create a copy of UpdateItemDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateItemDraftCopyWith<UpdateItemDraft> get copyWith => _$UpdateItemDraftCopyWithImpl<UpdateItemDraft>(this as UpdateItemDraft, _$identity);

  /// Serializes this UpdateItemDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateItemDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,condition,completeness,handoverTerms,pricePerDay,publicArea,address,latitude,longitude);

@override
String toString() {
  return 'UpdateItemDraft(title: $title, description: $description, categoryId: $categoryId, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, publicArea: $publicArea, address: $address, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $UpdateItemDraftCopyWith<$Res>  {
  factory $UpdateItemDraftCopyWith(UpdateItemDraft value, $Res Function(UpdateItemDraft) _then) = _$UpdateItemDraftCopyWithImpl;
@useResult
$Res call({
 String title, String description, String categoryId, String condition, String completeness, String handoverTerms, double pricePerDay, String publicArea, String address, double latitude, double longitude
});




}
/// @nodoc
class _$UpdateItemDraftCopyWithImpl<$Res>
    implements $UpdateItemDraftCopyWith<$Res> {
  _$UpdateItemDraftCopyWithImpl(this._self, this._then);

  final UpdateItemDraft _self;
  final $Res Function(UpdateItemDraft) _then;

/// Create a copy of UpdateItemDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? categoryId = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? pricePerDay = null,Object? publicArea = null,Object? address = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,publicArea: null == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateItemDraft].
extension UpdateItemDraftPatterns on UpdateItemDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateItemDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateItemDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateItemDraft value)  $default,){
final _that = this;
switch (_that) {
case _UpdateItemDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateItemDraft value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateItemDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String categoryId,  String condition,  String completeness,  String handoverTerms,  double pricePerDay,  String publicArea,  String address,  double latitude,  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateItemDraft() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.address,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String categoryId,  String condition,  String completeness,  String handoverTerms,  double pricePerDay,  String publicArea,  String address,  double latitude,  double longitude)  $default,) {final _that = this;
switch (_that) {
case _UpdateItemDraft():
return $default(_that.title,_that.description,_that.categoryId,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.address,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String categoryId,  String condition,  String completeness,  String handoverTerms,  double pricePerDay,  String publicArea,  String address,  double latitude,  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _UpdateItemDraft() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.publicArea,_that.address,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateItemDraft implements UpdateItemDraft {
  const _UpdateItemDraft({required this.title, required this.description, required this.categoryId, required this.condition, required this.completeness, required this.handoverTerms, required this.pricePerDay, required this.publicArea, required this.address, required this.latitude, required this.longitude});
  factory _UpdateItemDraft.fromJson(Map<String, dynamic> json) => _$UpdateItemDraftFromJson(json);

@override final  String title;
@override final  String description;
@override final  String categoryId;
@override final  String condition;
@override final  String completeness;
@override final  String handoverTerms;
@override final  double pricePerDay;
@override final  String publicArea;
@override final  String address;
@override final  double latitude;
@override final  double longitude;

/// Create a copy of UpdateItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateItemDraftCopyWith<_UpdateItemDraft> get copyWith => __$UpdateItemDraftCopyWithImpl<_UpdateItemDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateItemDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateItemDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.publicArea, publicArea) || other.publicArea == publicArea)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,condition,completeness,handoverTerms,pricePerDay,publicArea,address,latitude,longitude);

@override
String toString() {
  return 'UpdateItemDraft(title: $title, description: $description, categoryId: $categoryId, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, publicArea: $publicArea, address: $address, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$UpdateItemDraftCopyWith<$Res> implements $UpdateItemDraftCopyWith<$Res> {
  factory _$UpdateItemDraftCopyWith(_UpdateItemDraft value, $Res Function(_UpdateItemDraft) _then) = __$UpdateItemDraftCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String categoryId, String condition, String completeness, String handoverTerms, double pricePerDay, String publicArea, String address, double latitude, double longitude
});




}
/// @nodoc
class __$UpdateItemDraftCopyWithImpl<$Res>
    implements _$UpdateItemDraftCopyWith<$Res> {
  __$UpdateItemDraftCopyWithImpl(this._self, this._then);

  final _UpdateItemDraft _self;
  final $Res Function(_UpdateItemDraft) _then;

/// Create a copy of UpdateItemDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? categoryId = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? pricePerDay = null,Object? publicArea = null,Object? address = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_UpdateItemDraft(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,publicArea: null == publicArea ? _self.publicArea : publicArea // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$UnavailablePeriod {

 String get id; String get itemId; DateTime get startDate; DateTime get endDate; DateTime get createdAt;
/// Create a copy of UnavailablePeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnavailablePeriodCopyWith<UnavailablePeriod> get copyWith => _$UnavailablePeriodCopyWithImpl<UnavailablePeriod>(this as UnavailablePeriod, _$identity);

  /// Serializes this UnavailablePeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnavailablePeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,startDate,endDate,createdAt);

@override
String toString() {
  return 'UnavailablePeriod(id: $id, itemId: $itemId, startDate: $startDate, endDate: $endDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UnavailablePeriodCopyWith<$Res>  {
  factory $UnavailablePeriodCopyWith(UnavailablePeriod value, $Res Function(UnavailablePeriod) _then) = _$UnavailablePeriodCopyWithImpl;
@useResult
$Res call({
 String id, String itemId, DateTime startDate, DateTime endDate, DateTime createdAt
});




}
/// @nodoc
class _$UnavailablePeriodCopyWithImpl<$Res>
    implements $UnavailablePeriodCopyWith<$Res> {
  _$UnavailablePeriodCopyWithImpl(this._self, this._then);

  final UnavailablePeriod _self;
  final $Res Function(UnavailablePeriod) _then;

/// Create a copy of UnavailablePeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? itemId = null,Object? startDate = null,Object? endDate = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UnavailablePeriod].
extension UnavailablePeriodPatterns on UnavailablePeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnavailablePeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnavailablePeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnavailablePeriod value)  $default,){
final _that = this;
switch (_that) {
case _UnavailablePeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnavailablePeriod value)?  $default,){
final _that = this;
switch (_that) {
case _UnavailablePeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String itemId,  DateTime startDate,  DateTime endDate,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnavailablePeriod() when $default != null:
return $default(_that.id,_that.itemId,_that.startDate,_that.endDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String itemId,  DateTime startDate,  DateTime endDate,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _UnavailablePeriod():
return $default(_that.id,_that.itemId,_that.startDate,_that.endDate,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String itemId,  DateTime startDate,  DateTime endDate,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _UnavailablePeriod() when $default != null:
return $default(_that.id,_that.itemId,_that.startDate,_that.endDate,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnavailablePeriod implements UnavailablePeriod {
  const _UnavailablePeriod({required this.id, required this.itemId, required this.startDate, required this.endDate, required this.createdAt});
  factory _UnavailablePeriod.fromJson(Map<String, dynamic> json) => _$UnavailablePeriodFromJson(json);

@override final  String id;
@override final  String itemId;
@override final  DateTime startDate;
@override final  DateTime endDate;
@override final  DateTime createdAt;

/// Create a copy of UnavailablePeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnavailablePeriodCopyWith<_UnavailablePeriod> get copyWith => __$UnavailablePeriodCopyWithImpl<_UnavailablePeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnavailablePeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnavailablePeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.itemId, itemId) || other.itemId == itemId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,itemId,startDate,endDate,createdAt);

@override
String toString() {
  return 'UnavailablePeriod(id: $id, itemId: $itemId, startDate: $startDate, endDate: $endDate, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UnavailablePeriodCopyWith<$Res> implements $UnavailablePeriodCopyWith<$Res> {
  factory _$UnavailablePeriodCopyWith(_UnavailablePeriod value, $Res Function(_UnavailablePeriod) _then) = __$UnavailablePeriodCopyWithImpl;
@override @useResult
$Res call({
 String id, String itemId, DateTime startDate, DateTime endDate, DateTime createdAt
});




}
/// @nodoc
class __$UnavailablePeriodCopyWithImpl<$Res>
    implements _$UnavailablePeriodCopyWith<$Res> {
  __$UnavailablePeriodCopyWithImpl(this._self, this._then);

  final _UnavailablePeriod _self;
  final $Res Function(_UnavailablePeriod) _then;

/// Create a copy of UnavailablePeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? itemId = null,Object? startDate = null,Object? endDate = null,Object? createdAt = null,}) {
  return _then(_UnavailablePeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,itemId: null == itemId ? _self.itemId : itemId // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CreateUnavailablePeriodDraft {

 String get startDate; String get endDate;
/// Create a copy of CreateUnavailablePeriodDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateUnavailablePeriodDraftCopyWith<CreateUnavailablePeriodDraft> get copyWith => _$CreateUnavailablePeriodDraftCopyWithImpl<CreateUnavailablePeriodDraft>(this as CreateUnavailablePeriodDraft, _$identity);

  /// Serializes this CreateUnavailablePeriodDraft to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUnavailablePeriodDraft&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'CreateUnavailablePeriodDraft(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $CreateUnavailablePeriodDraftCopyWith<$Res>  {
  factory $CreateUnavailablePeriodDraftCopyWith(CreateUnavailablePeriodDraft value, $Res Function(CreateUnavailablePeriodDraft) _then) = _$CreateUnavailablePeriodDraftCopyWithImpl;
@useResult
$Res call({
 String startDate, String endDate
});




}
/// @nodoc
class _$CreateUnavailablePeriodDraftCopyWithImpl<$Res>
    implements $CreateUnavailablePeriodDraftCopyWith<$Res> {
  _$CreateUnavailablePeriodDraftCopyWithImpl(this._self, this._then);

  final CreateUnavailablePeriodDraft _self;
  final $Res Function(CreateUnavailablePeriodDraft) _then;

/// Create a copy of CreateUnavailablePeriodDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDate = null,Object? endDate = null,}) {
  return _then(_self.copyWith(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateUnavailablePeriodDraft].
extension CreateUnavailablePeriodDraftPatterns on CreateUnavailablePeriodDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateUnavailablePeriodDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateUnavailablePeriodDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateUnavailablePeriodDraft value)  $default,){
final _that = this;
switch (_that) {
case _CreateUnavailablePeriodDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateUnavailablePeriodDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CreateUnavailablePeriodDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String startDate,  String endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateUnavailablePeriodDraft() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String startDate,  String endDate)  $default,) {final _that = this;
switch (_that) {
case _CreateUnavailablePeriodDraft():
return $default(_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String startDate,  String endDate)?  $default,) {final _that = this;
switch (_that) {
case _CreateUnavailablePeriodDraft() when $default != null:
return $default(_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateUnavailablePeriodDraft implements CreateUnavailablePeriodDraft {
  const _CreateUnavailablePeriodDraft({required this.startDate, required this.endDate});
  factory _CreateUnavailablePeriodDraft.fromJson(Map<String, dynamic> json) => _$CreateUnavailablePeriodDraftFromJson(json);

@override final  String startDate;
@override final  String endDate;

/// Create a copy of CreateUnavailablePeriodDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateUnavailablePeriodDraftCopyWith<_CreateUnavailablePeriodDraft> get copyWith => __$CreateUnavailablePeriodDraftCopyWithImpl<_CreateUnavailablePeriodDraft>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateUnavailablePeriodDraftToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateUnavailablePeriodDraft&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,startDate,endDate);

@override
String toString() {
  return 'CreateUnavailablePeriodDraft(startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$CreateUnavailablePeriodDraftCopyWith<$Res> implements $CreateUnavailablePeriodDraftCopyWith<$Res> {
  factory _$CreateUnavailablePeriodDraftCopyWith(_CreateUnavailablePeriodDraft value, $Res Function(_CreateUnavailablePeriodDraft) _then) = __$CreateUnavailablePeriodDraftCopyWithImpl;
@override @useResult
$Res call({
 String startDate, String endDate
});




}
/// @nodoc
class __$CreateUnavailablePeriodDraftCopyWithImpl<$Res>
    implements _$CreateUnavailablePeriodDraftCopyWith<$Res> {
  __$CreateUnavailablePeriodDraftCopyWithImpl(this._self, this._then);

  final _CreateUnavailablePeriodDraft _self;
  final $Res Function(_CreateUnavailablePeriodDraft) _then;

/// Create a copy of CreateUnavailablePeriodDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? endDate = null,}) {
  return _then(_CreateUnavailablePeriodDraft(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
