// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CatalogCategory {

 String get id; String get name; String get slug; String get safetyNotice; String? get iconName;
/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogCategoryCopyWith<CatalogCategory> get copyWith => _$CatalogCategoryCopyWithImpl<CatalogCategory>(this as CatalogCategory, _$identity);

  /// Serializes this CatalogCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.safetyNotice, safetyNotice) || other.safetyNotice == safetyNotice)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,safetyNotice,iconName);

@override
String toString() {
  return 'CatalogCategory(id: $id, name: $name, slug: $slug, safetyNotice: $safetyNotice, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $CatalogCategoryCopyWith<$Res>  {
  factory $CatalogCategoryCopyWith(CatalogCategory value, $Res Function(CatalogCategory) _then) = _$CatalogCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String safetyNotice, String? iconName
});




}
/// @nodoc
class _$CatalogCategoryCopyWithImpl<$Res>
    implements $CatalogCategoryCopyWith<$Res> {
  _$CatalogCategoryCopyWithImpl(this._self, this._then);

  final CatalogCategory _self;
  final $Res Function(CatalogCategory) _then;

/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? safetyNotice = null,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,safetyNotice: null == safetyNotice ? _self.safetyNotice : safetyNotice // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogCategory].
extension CatalogCategoryPatterns on CatalogCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogCategory value)  $default,){
final _that = this;
switch (_that) {
case _CatalogCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogCategory value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String safetyNotice,  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.safetyNotice,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String safetyNotice,  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _CatalogCategory():
return $default(_that.id,_that.name,_that.slug,_that.safetyNotice,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String safetyNotice,  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _CatalogCategory() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.safetyNotice,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogCategory implements CatalogCategory {
  const _CatalogCategory({required this.id, required this.name, required this.slug, required this.safetyNotice, this.iconName});
  factory _CatalogCategory.fromJson(Map<String, dynamic> json) => _$CatalogCategoryFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override final  String safetyNotice;
@override final  String? iconName;

/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogCategoryCopyWith<_CatalogCategory> get copyWith => __$CatalogCategoryCopyWithImpl<_CatalogCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.safetyNotice, safetyNotice) || other.safetyNotice == safetyNotice)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug,safetyNotice,iconName);

@override
String toString() {
  return 'CatalogCategory(id: $id, name: $name, slug: $slug, safetyNotice: $safetyNotice, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$CatalogCategoryCopyWith<$Res> implements $CatalogCategoryCopyWith<$Res> {
  factory _$CatalogCategoryCopyWith(_CatalogCategory value, $Res Function(_CatalogCategory) _then) = __$CatalogCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String safetyNotice, String? iconName
});




}
/// @nodoc
class __$CatalogCategoryCopyWithImpl<$Res>
    implements _$CatalogCategoryCopyWith<$Res> {
  __$CatalogCategoryCopyWithImpl(this._self, this._then);

  final _CatalogCategory _self;
  final $Res Function(_CatalogCategory) _then;

/// Create a copy of CatalogCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? safetyNotice = null,Object? iconName = freezed,}) {
  return _then(_CatalogCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,safetyNotice: null == safetyNotice ? _self.safetyNotice : safetyNotice // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CatalogOwner {

 String get id; String? get name; String? get city; String? get avatarUrl;
/// Create a copy of CatalogOwner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogOwnerCopyWith<CatalogOwner> get copyWith => _$CatalogOwnerCopyWithImpl<CatalogOwner>(this as CatalogOwner, _$identity);

  /// Serializes this CatalogOwner to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogOwner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,city,avatarUrl);

@override
String toString() {
  return 'CatalogOwner(id: $id, name: $name, city: $city, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $CatalogOwnerCopyWith<$Res>  {
  factory $CatalogOwnerCopyWith(CatalogOwner value, $Res Function(CatalogOwner) _then) = _$CatalogOwnerCopyWithImpl;
@useResult
$Res call({
 String id, String? name, String? city, String? avatarUrl
});




}
/// @nodoc
class _$CatalogOwnerCopyWithImpl<$Res>
    implements $CatalogOwnerCopyWith<$Res> {
  _$CatalogOwnerCopyWithImpl(this._self, this._then);

  final CatalogOwner _self;
  final $Res Function(CatalogOwner) _then;

/// Create a copy of CatalogOwner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? city = freezed,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogOwner].
extension CatalogOwnerPatterns on CatalogOwner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogOwner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogOwner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogOwner value)  $default,){
final _that = this;
switch (_that) {
case _CatalogOwner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogOwner value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogOwner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  String? city,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogOwner() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  String? city,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _CatalogOwner():
return $default(_that.id,_that.name,_that.city,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  String? city,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _CatalogOwner() when $default != null:
return $default(_that.id,_that.name,_that.city,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogOwner implements CatalogOwner {
  const _CatalogOwner({required this.id, this.name, this.city, this.avatarUrl});
  factory _CatalogOwner.fromJson(Map<String, dynamic> json) => _$CatalogOwnerFromJson(json);

@override final  String id;
@override final  String? name;
@override final  String? city;
@override final  String? avatarUrl;

/// Create a copy of CatalogOwner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogOwnerCopyWith<_CatalogOwner> get copyWith => __$CatalogOwnerCopyWithImpl<_CatalogOwner>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogOwnerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogOwner&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,city,avatarUrl);

@override
String toString() {
  return 'CatalogOwner(id: $id, name: $name, city: $city, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$CatalogOwnerCopyWith<$Res> implements $CatalogOwnerCopyWith<$Res> {
  factory _$CatalogOwnerCopyWith(_CatalogOwner value, $Res Function(_CatalogOwner) _then) = __$CatalogOwnerCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, String? city, String? avatarUrl
});




}
/// @nodoc
class __$CatalogOwnerCopyWithImpl<$Res>
    implements _$CatalogOwnerCopyWith<$Res> {
  __$CatalogOwnerCopyWithImpl(this._self, this._then);

  final _CatalogOwner _self;
  final $Res Function(_CatalogOwner) _then;

/// Create a copy of CatalogOwner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? city = freezed,Object? avatarUrl = freezed,}) {
  return _then(_CatalogOwner(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CatalogPhoto {

 String get id; int get sortOrder; bool get isCover; DateTime get createdAt; String? get thumbnailUrl; String? get previewUrl;
/// Create a copy of CatalogPhoto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogPhotoCopyWith<CatalogPhoto> get copyWith => _$CatalogPhotoCopyWithImpl<CatalogPhoto>(this as CatalogPhoto, _$identity);

  /// Serializes this CatalogPhoto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isCover, isCover) || other.isCover == isCover)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sortOrder,isCover,createdAt,thumbnailUrl,previewUrl);

@override
String toString() {
  return 'CatalogPhoto(id: $id, sortOrder: $sortOrder, isCover: $isCover, createdAt: $createdAt, thumbnailUrl: $thumbnailUrl, previewUrl: $previewUrl)';
}


}

/// @nodoc
abstract mixin class $CatalogPhotoCopyWith<$Res>  {
  factory $CatalogPhotoCopyWith(CatalogPhoto value, $Res Function(CatalogPhoto) _then) = _$CatalogPhotoCopyWithImpl;
@useResult
$Res call({
 String id, int sortOrder, bool isCover, DateTime createdAt, String? thumbnailUrl, String? previewUrl
});




}
/// @nodoc
class _$CatalogPhotoCopyWithImpl<$Res>
    implements $CatalogPhotoCopyWith<$Res> {
  _$CatalogPhotoCopyWithImpl(this._self, this._then);

  final CatalogPhoto _self;
  final $Res Function(CatalogPhoto) _then;

/// Create a copy of CatalogPhoto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sortOrder = null,Object? isCover = null,Object? createdAt = null,Object? thumbnailUrl = freezed,Object? previewUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isCover: null == isCover ? _self.isCover : isCover // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogPhoto].
extension CatalogPhotoPatterns on CatalogPhoto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogPhoto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogPhoto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogPhoto value)  $default,){
final _that = this;
switch (_that) {
case _CatalogPhoto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogPhoto value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogPhoto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int sortOrder,  bool isCover,  DateTime createdAt,  String? thumbnailUrl,  String? previewUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogPhoto() when $default != null:
return $default(_that.id,_that.sortOrder,_that.isCover,_that.createdAt,_that.thumbnailUrl,_that.previewUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int sortOrder,  bool isCover,  DateTime createdAt,  String? thumbnailUrl,  String? previewUrl)  $default,) {final _that = this;
switch (_that) {
case _CatalogPhoto():
return $default(_that.id,_that.sortOrder,_that.isCover,_that.createdAt,_that.thumbnailUrl,_that.previewUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int sortOrder,  bool isCover,  DateTime createdAt,  String? thumbnailUrl,  String? previewUrl)?  $default,) {final _that = this;
switch (_that) {
case _CatalogPhoto() when $default != null:
return $default(_that.id,_that.sortOrder,_that.isCover,_that.createdAt,_that.thumbnailUrl,_that.previewUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogPhoto implements CatalogPhoto {
  const _CatalogPhoto({required this.id, required this.sortOrder, required this.isCover, required this.createdAt, this.thumbnailUrl, this.previewUrl});
  factory _CatalogPhoto.fromJson(Map<String, dynamic> json) => _$CatalogPhotoFromJson(json);

@override final  String id;
@override final  int sortOrder;
@override final  bool isCover;
@override final  DateTime createdAt;
@override final  String? thumbnailUrl;
@override final  String? previewUrl;

/// Create a copy of CatalogPhoto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogPhotoCopyWith<_CatalogPhoto> get copyWith => __$CatalogPhotoCopyWithImpl<_CatalogPhoto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogPhotoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogPhoto&&(identical(other.id, id) || other.id == id)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isCover, isCover) || other.isCover == isCover)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.thumbnailUrl, thumbnailUrl) || other.thumbnailUrl == thumbnailUrl)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sortOrder,isCover,createdAt,thumbnailUrl,previewUrl);

@override
String toString() {
  return 'CatalogPhoto(id: $id, sortOrder: $sortOrder, isCover: $isCover, createdAt: $createdAt, thumbnailUrl: $thumbnailUrl, previewUrl: $previewUrl)';
}


}

/// @nodoc
abstract mixin class _$CatalogPhotoCopyWith<$Res> implements $CatalogPhotoCopyWith<$Res> {
  factory _$CatalogPhotoCopyWith(_CatalogPhoto value, $Res Function(_CatalogPhoto) _then) = __$CatalogPhotoCopyWithImpl;
@override @useResult
$Res call({
 String id, int sortOrder, bool isCover, DateTime createdAt, String? thumbnailUrl, String? previewUrl
});




}
/// @nodoc
class __$CatalogPhotoCopyWithImpl<$Res>
    implements _$CatalogPhotoCopyWith<$Res> {
  __$CatalogPhotoCopyWithImpl(this._self, this._then);

  final _CatalogPhoto _self;
  final $Res Function(_CatalogPhoto) _then;

/// Create a copy of CatalogPhoto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sortOrder = null,Object? isCover = null,Object? createdAt = null,Object? thumbnailUrl = freezed,Object? previewUrl = freezed,}) {
  return _then(_CatalogPhoto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isCover: null == isCover ? _self.isCover : isCover // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,thumbnailUrl: freezed == thumbnailUrl ? _self.thumbnailUrl : thumbnailUrl // ignore: cast_nullable_to_non_nullable
as String?,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ApproximateLocation {

@JsonKey(fromJson: _doubleFromJson) double get latitude;@JsonKey(fromJson: _doubleFromJson) double get longitude; String get precision;
/// Create a copy of ApproximateLocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApproximateLocationCopyWith<ApproximateLocation> get copyWith => _$ApproximateLocationCopyWithImpl<ApproximateLocation>(this as ApproximateLocation, _$identity);

  /// Serializes this ApproximateLocation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApproximateLocation&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.precision, precision) || other.precision == precision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,precision);

@override
String toString() {
  return 'ApproximateLocation(latitude: $latitude, longitude: $longitude, precision: $precision)';
}


}

/// @nodoc
abstract mixin class $ApproximateLocationCopyWith<$Res>  {
  factory $ApproximateLocationCopyWith(ApproximateLocation value, $Res Function(ApproximateLocation) _then) = _$ApproximateLocationCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _doubleFromJson) double latitude,@JsonKey(fromJson: _doubleFromJson) double longitude, String precision
});




}
/// @nodoc
class _$ApproximateLocationCopyWithImpl<$Res>
    implements $ApproximateLocationCopyWith<$Res> {
  _$ApproximateLocationCopyWithImpl(this._self, this._then);

  final ApproximateLocation _self;
  final $Res Function(ApproximateLocation) _then;

/// Create a copy of ApproximateLocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = null,Object? longitude = null,Object? precision = null,}) {
  return _then(_self.copyWith(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,precision: null == precision ? _self.precision : precision // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ApproximateLocation].
extension ApproximateLocationPatterns on ApproximateLocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApproximateLocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApproximateLocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApproximateLocation value)  $default,){
final _that = this;
switch (_that) {
case _ApproximateLocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApproximateLocation value)?  $default,){
final _that = this;
switch (_that) {
case _ApproximateLocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _doubleFromJson)  double latitude, @JsonKey(fromJson: _doubleFromJson)  double longitude,  String precision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApproximateLocation() when $default != null:
return $default(_that.latitude,_that.longitude,_that.precision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _doubleFromJson)  double latitude, @JsonKey(fromJson: _doubleFromJson)  double longitude,  String precision)  $default,) {final _that = this;
switch (_that) {
case _ApproximateLocation():
return $default(_that.latitude,_that.longitude,_that.precision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _doubleFromJson)  double latitude, @JsonKey(fromJson: _doubleFromJson)  double longitude,  String precision)?  $default,) {final _that = this;
switch (_that) {
case _ApproximateLocation() when $default != null:
return $default(_that.latitude,_that.longitude,_that.precision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApproximateLocation implements ApproximateLocation {
  const _ApproximateLocation({@JsonKey(fromJson: _doubleFromJson) required this.latitude, @JsonKey(fromJson: _doubleFromJson) required this.longitude, required this.precision});
  factory _ApproximateLocation.fromJson(Map<String, dynamic> json) => _$ApproximateLocationFromJson(json);

@override@JsonKey(fromJson: _doubleFromJson) final  double latitude;
@override@JsonKey(fromJson: _doubleFromJson) final  double longitude;
@override final  String precision;

/// Create a copy of ApproximateLocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApproximateLocationCopyWith<_ApproximateLocation> get copyWith => __$ApproximateLocationCopyWithImpl<_ApproximateLocation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApproximateLocationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApproximateLocation&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.precision, precision) || other.precision == precision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,precision);

@override
String toString() {
  return 'ApproximateLocation(latitude: $latitude, longitude: $longitude, precision: $precision)';
}


}

/// @nodoc
abstract mixin class _$ApproximateLocationCopyWith<$Res> implements $ApproximateLocationCopyWith<$Res> {
  factory _$ApproximateLocationCopyWith(_ApproximateLocation value, $Res Function(_ApproximateLocation) _then) = __$ApproximateLocationCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _doubleFromJson) double latitude,@JsonKey(fromJson: _doubleFromJson) double longitude, String precision
});




}
/// @nodoc
class __$ApproximateLocationCopyWithImpl<$Res>
    implements _$ApproximateLocationCopyWith<$Res> {
  __$ApproximateLocationCopyWithImpl(this._self, this._then);

  final _ApproximateLocation _self;
  final $Res Function(_ApproximateLocation) _then;

/// Create a copy of ApproximateLocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = null,Object? longitude = null,Object? precision = null,}) {
  return _then(_ApproximateLocation(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,precision: null == precision ? _self.precision : precision // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CatalogItem {

 String get id; String get title; String get description; String get condition; String get completeness; String get handoverTerms;@JsonKey(fromJson: _doubleFromJson) double get pricePerDay;@JsonKey(fromJson: _nullableDoubleFromJson) double? get depositAmount; CatalogCategory get category; CatalogOwner get owner; String get area; ApproximateLocation get approximateLocation; List<CatalogPhoto> get photos; DateTime get createdAt; DateTime get updatedAt; String? get distanceBucket;
/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogItemCopyWith<CatalogItem> get copyWith => _$CatalogItemCopyWithImpl<CatalogItem>(this as CatalogItem, _$identity);

  /// Serializes this CatalogItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.area, area) || other.area == area)&&(identical(other.approximateLocation, approximateLocation) || other.approximateLocation == approximateLocation)&&const DeepCollectionEquality().equals(other.photos, photos)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.distanceBucket, distanceBucket) || other.distanceBucket == distanceBucket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,condition,completeness,handoverTerms,pricePerDay,depositAmount,category,owner,area,approximateLocation,const DeepCollectionEquality().hash(photos),createdAt,updatedAt,distanceBucket);

@override
String toString() {
  return 'CatalogItem(id: $id, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, depositAmount: $depositAmount, category: $category, owner: $owner, area: $area, approximateLocation: $approximateLocation, photos: $photos, createdAt: $createdAt, updatedAt: $updatedAt, distanceBucket: $distanceBucket)';
}


}

/// @nodoc
abstract mixin class $CatalogItemCopyWith<$Res>  {
  factory $CatalogItemCopyWith(CatalogItem value, $Res Function(CatalogItem) _then) = _$CatalogItemCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String condition, String completeness, String handoverTerms,@JsonKey(fromJson: _doubleFromJson) double pricePerDay,@JsonKey(fromJson: _nullableDoubleFromJson) double? depositAmount, CatalogCategory category, CatalogOwner owner, String area, ApproximateLocation approximateLocation, List<CatalogPhoto> photos, DateTime createdAt, DateTime updatedAt, String? distanceBucket
});


$CatalogCategoryCopyWith<$Res> get category;$CatalogOwnerCopyWith<$Res> get owner;$ApproximateLocationCopyWith<$Res> get approximateLocation;

}
/// @nodoc
class _$CatalogItemCopyWithImpl<$Res>
    implements $CatalogItemCopyWith<$Res> {
  _$CatalogItemCopyWithImpl(this._self, this._then);

  final CatalogItem _self;
  final $Res Function(CatalogItem) _then;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? pricePerDay = null,Object? depositAmount = freezed,Object? category = null,Object? owner = null,Object? area = null,Object? approximateLocation = null,Object? photos = null,Object? createdAt = null,Object? updatedAt = null,Object? distanceBucket = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CatalogCategory,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as CatalogOwner,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,approximateLocation: null == approximateLocation ? _self.approximateLocation : approximateLocation // ignore: cast_nullable_to_non_nullable
as ApproximateLocation,photos: null == photos ? _self.photos : photos // ignore: cast_nullable_to_non_nullable
as List<CatalogPhoto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceBucket: freezed == distanceBucket ? _self.distanceBucket : distanceBucket // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogCategoryCopyWith<$Res> get category {
  
  return $CatalogCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogOwnerCopyWith<$Res> get owner {
  
  return $CatalogOwnerCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApproximateLocationCopyWith<$Res> get approximateLocation {
  
  return $ApproximateLocationCopyWith<$Res>(_self.approximateLocation, (value) {
    return _then(_self.copyWith(approximateLocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [CatalogItem].
extension CatalogItemPatterns on CatalogItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogItem value)  $default,){
final _that = this;
switch (_that) {
case _CatalogItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogItem value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String condition,  String completeness,  String handoverTerms, @JsonKey(fromJson: _doubleFromJson)  double pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson)  double? depositAmount,  CatalogCategory category,  CatalogOwner owner,  String area,  ApproximateLocation approximateLocation,  List<CatalogPhoto> photos,  DateTime createdAt,  DateTime updatedAt,  String? distanceBucket)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.depositAmount,_that.category,_that.owner,_that.area,_that.approximateLocation,_that.photos,_that.createdAt,_that.updatedAt,_that.distanceBucket);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String condition,  String completeness,  String handoverTerms, @JsonKey(fromJson: _doubleFromJson)  double pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson)  double? depositAmount,  CatalogCategory category,  CatalogOwner owner,  String area,  ApproximateLocation approximateLocation,  List<CatalogPhoto> photos,  DateTime createdAt,  DateTime updatedAt,  String? distanceBucket)  $default,) {final _that = this;
switch (_that) {
case _CatalogItem():
return $default(_that.id,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.depositAmount,_that.category,_that.owner,_that.area,_that.approximateLocation,_that.photos,_that.createdAt,_that.updatedAt,_that.distanceBucket);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String condition,  String completeness,  String handoverTerms, @JsonKey(fromJson: _doubleFromJson)  double pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson)  double? depositAmount,  CatalogCategory category,  CatalogOwner owner,  String area,  ApproximateLocation approximateLocation,  List<CatalogPhoto> photos,  DateTime createdAt,  DateTime updatedAt,  String? distanceBucket)?  $default,) {final _that = this;
switch (_that) {
case _CatalogItem() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.condition,_that.completeness,_that.handoverTerms,_that.pricePerDay,_that.depositAmount,_that.category,_that.owner,_that.area,_that.approximateLocation,_that.photos,_that.createdAt,_that.updatedAt,_that.distanceBucket);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogItem implements CatalogItem {
  const _CatalogItem({required this.id, required this.title, required this.description, required this.condition, required this.completeness, required this.handoverTerms, @JsonKey(fromJson: _doubleFromJson) required this.pricePerDay, @JsonKey(fromJson: _nullableDoubleFromJson) this.depositAmount, required this.category, required this.owner, required this.area, required this.approximateLocation, required final  List<CatalogPhoto> photos, required this.createdAt, required this.updatedAt, this.distanceBucket}): _photos = photos;
  factory _CatalogItem.fromJson(Map<String, dynamic> json) => _$CatalogItemFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String condition;
@override final  String completeness;
@override final  String handoverTerms;
@override@JsonKey(fromJson: _doubleFromJson) final  double pricePerDay;
@override@JsonKey(fromJson: _nullableDoubleFromJson) final  double? depositAmount;
@override final  CatalogCategory category;
@override final  CatalogOwner owner;
@override final  String area;
@override final  ApproximateLocation approximateLocation;
 final  List<CatalogPhoto> _photos;
@override List<CatalogPhoto> get photos {
  if (_photos is EqualUnmodifiableListView) return _photos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_photos);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? distanceBucket;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogItemCopyWith<_CatalogItem> get copyWith => __$CatalogItemCopyWithImpl<_CatalogItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.condition, condition) || other.condition == condition)&&(identical(other.completeness, completeness) || other.completeness == completeness)&&(identical(other.handoverTerms, handoverTerms) || other.handoverTerms == handoverTerms)&&(identical(other.pricePerDay, pricePerDay) || other.pricePerDay == pricePerDay)&&(identical(other.depositAmount, depositAmount) || other.depositAmount == depositAmount)&&(identical(other.category, category) || other.category == category)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.area, area) || other.area == area)&&(identical(other.approximateLocation, approximateLocation) || other.approximateLocation == approximateLocation)&&const DeepCollectionEquality().equals(other._photos, _photos)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.distanceBucket, distanceBucket) || other.distanceBucket == distanceBucket));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,condition,completeness,handoverTerms,pricePerDay,depositAmount,category,owner,area,approximateLocation,const DeepCollectionEquality().hash(_photos),createdAt,updatedAt,distanceBucket);

@override
String toString() {
  return 'CatalogItem(id: $id, title: $title, description: $description, condition: $condition, completeness: $completeness, handoverTerms: $handoverTerms, pricePerDay: $pricePerDay, depositAmount: $depositAmount, category: $category, owner: $owner, area: $area, approximateLocation: $approximateLocation, photos: $photos, createdAt: $createdAt, updatedAt: $updatedAt, distanceBucket: $distanceBucket)';
}


}

/// @nodoc
abstract mixin class _$CatalogItemCopyWith<$Res> implements $CatalogItemCopyWith<$Res> {
  factory _$CatalogItemCopyWith(_CatalogItem value, $Res Function(_CatalogItem) _then) = __$CatalogItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String condition, String completeness, String handoverTerms,@JsonKey(fromJson: _doubleFromJson) double pricePerDay,@JsonKey(fromJson: _nullableDoubleFromJson) double? depositAmount, CatalogCategory category, CatalogOwner owner, String area, ApproximateLocation approximateLocation, List<CatalogPhoto> photos, DateTime createdAt, DateTime updatedAt, String? distanceBucket
});


@override $CatalogCategoryCopyWith<$Res> get category;@override $CatalogOwnerCopyWith<$Res> get owner;@override $ApproximateLocationCopyWith<$Res> get approximateLocation;

}
/// @nodoc
class __$CatalogItemCopyWithImpl<$Res>
    implements _$CatalogItemCopyWith<$Res> {
  __$CatalogItemCopyWithImpl(this._self, this._then);

  final _CatalogItem _self;
  final $Res Function(_CatalogItem) _then;

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? condition = null,Object? completeness = null,Object? handoverTerms = null,Object? pricePerDay = null,Object? depositAmount = freezed,Object? category = null,Object? owner = null,Object? area = null,Object? approximateLocation = null,Object? photos = null,Object? createdAt = null,Object? updatedAt = null,Object? distanceBucket = freezed,}) {
  return _then(_CatalogItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,condition: null == condition ? _self.condition : condition // ignore: cast_nullable_to_non_nullable
as String,completeness: null == completeness ? _self.completeness : completeness // ignore: cast_nullable_to_non_nullable
as String,handoverTerms: null == handoverTerms ? _self.handoverTerms : handoverTerms // ignore: cast_nullable_to_non_nullable
as String,pricePerDay: null == pricePerDay ? _self.pricePerDay : pricePerDay // ignore: cast_nullable_to_non_nullable
as double,depositAmount: freezed == depositAmount ? _self.depositAmount : depositAmount // ignore: cast_nullable_to_non_nullable
as double?,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CatalogCategory,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as CatalogOwner,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,approximateLocation: null == approximateLocation ? _self.approximateLocation : approximateLocation // ignore: cast_nullable_to_non_nullable
as ApproximateLocation,photos: null == photos ? _self._photos : photos // ignore: cast_nullable_to_non_nullable
as List<CatalogPhoto>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,distanceBucket: freezed == distanceBucket ? _self.distanceBucket : distanceBucket // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogCategoryCopyWith<$Res> get category {
  
  return $CatalogCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CatalogOwnerCopyWith<$Res> get owner {
  
  return $CatalogOwnerCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of CatalogItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApproximateLocationCopyWith<$Res> get approximateLocation {
  
  return $ApproximateLocationCopyWith<$Res>(_self.approximateLocation, (value) {
    return _then(_self.copyWith(approximateLocation: value));
  });
}
}

/// @nodoc
mixin _$CatalogState {

 List<CatalogItem> get items; bool get hasMore; int get nextOffset; bool get isLoadingMore; bool get isRefreshing; String? get refreshError;
/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogStateCopyWith<CatalogState> get copyWith => _$CatalogStateCopyWithImpl<CatalogState>(this as CatalogState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogState&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.nextOffset, nextOffset) || other.nextOffset == nextOffset)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.refreshError, refreshError) || other.refreshError == refreshError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),hasMore,nextOffset,isLoadingMore,isRefreshing,refreshError);

@override
String toString() {
  return 'CatalogState(items: $items, hasMore: $hasMore, nextOffset: $nextOffset, isLoadingMore: $isLoadingMore, isRefreshing: $isRefreshing, refreshError: $refreshError)';
}


}

/// @nodoc
abstract mixin class $CatalogStateCopyWith<$Res>  {
  factory $CatalogStateCopyWith(CatalogState value, $Res Function(CatalogState) _then) = _$CatalogStateCopyWithImpl;
@useResult
$Res call({
 List<CatalogItem> items, bool hasMore, int nextOffset, bool isLoadingMore, bool isRefreshing, String? refreshError
});




}
/// @nodoc
class _$CatalogStateCopyWithImpl<$Res>
    implements $CatalogStateCopyWith<$Res> {
  _$CatalogStateCopyWithImpl(this._self, this._then);

  final CatalogState _self;
  final $Res Function(CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? hasMore = null,Object? nextOffset = null,Object? isLoadingMore = null,Object? isRefreshing = null,Object? refreshError = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogItem>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,nextOffset: null == nextOffset ? _self.nextOffset : nextOffset // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshError: freezed == refreshError ? _self.refreshError : refreshError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogState].
extension CatalogStatePatterns on CatalogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogState value)  $default,){
final _that = this;
switch (_that) {
case _CatalogState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogState value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CatalogItem> items,  bool hasMore,  int nextOffset,  bool isLoadingMore,  bool isRefreshing,  String? refreshError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.items,_that.hasMore,_that.nextOffset,_that.isLoadingMore,_that.isRefreshing,_that.refreshError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CatalogItem> items,  bool hasMore,  int nextOffset,  bool isLoadingMore,  bool isRefreshing,  String? refreshError)  $default,) {final _that = this;
switch (_that) {
case _CatalogState():
return $default(_that.items,_that.hasMore,_that.nextOffset,_that.isLoadingMore,_that.isRefreshing,_that.refreshError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CatalogItem> items,  bool hasMore,  int nextOffset,  bool isLoadingMore,  bool isRefreshing,  String? refreshError)?  $default,) {final _that = this;
switch (_that) {
case _CatalogState() when $default != null:
return $default(_that.items,_that.hasMore,_that.nextOffset,_that.isLoadingMore,_that.isRefreshing,_that.refreshError);case _:
  return null;

}
}

}

/// @nodoc


class _CatalogState implements CatalogState {
  const _CatalogState({required final  List<CatalogItem> items, required this.hasMore, required this.nextOffset, this.isLoadingMore = false, this.isRefreshing = false, this.refreshError}): _items = items;
  

 final  List<CatalogItem> _items;
@override List<CatalogItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  bool hasMore;
@override final  int nextOffset;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool isRefreshing;
@override final  String? refreshError;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogStateCopyWith<_CatalogState> get copyWith => __$CatalogStateCopyWithImpl<_CatalogState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogState&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.nextOffset, nextOffset) || other.nextOffset == nextOffset)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing)&&(identical(other.refreshError, refreshError) || other.refreshError == refreshError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore,nextOffset,isLoadingMore,isRefreshing,refreshError);

@override
String toString() {
  return 'CatalogState(items: $items, hasMore: $hasMore, nextOffset: $nextOffset, isLoadingMore: $isLoadingMore, isRefreshing: $isRefreshing, refreshError: $refreshError)';
}


}

/// @nodoc
abstract mixin class _$CatalogStateCopyWith<$Res> implements $CatalogStateCopyWith<$Res> {
  factory _$CatalogStateCopyWith(_CatalogState value, $Res Function(_CatalogState) _then) = __$CatalogStateCopyWithImpl;
@override @useResult
$Res call({
 List<CatalogItem> items, bool hasMore, int nextOffset, bool isLoadingMore, bool isRefreshing, String? refreshError
});




}
/// @nodoc
class __$CatalogStateCopyWithImpl<$Res>
    implements _$CatalogStateCopyWith<$Res> {
  __$CatalogStateCopyWithImpl(this._self, this._then);

  final _CatalogState _self;
  final $Res Function(_CatalogState) _then;

/// Create a copy of CatalogState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,Object? nextOffset = null,Object? isLoadingMore = null,Object? isRefreshing = null,Object? refreshError = freezed,}) {
  return _then(_CatalogState(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CatalogItem>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,nextOffset: null == nextOffset ? _self.nextOffset : nextOffset // ignore: cast_nullable_to_non_nullable
as int,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,refreshError: freezed == refreshError ? _self.refreshError : refreshError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
