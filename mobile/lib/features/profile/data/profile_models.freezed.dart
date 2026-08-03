// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

 String get id; String get phone; String get role; bool get isBlocked; DateTime get createdAt; DateTime get updatedAt; String? get name; String? get city; String? get avatarUrl; String? get kycStatus;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phone,role,isBlocked,createdAt,updatedAt,name,city,avatarUrl,kycStatus);

@override
String toString() {
  return 'UserProfile(id: $id, phone: $phone, role: $role, isBlocked: $isBlocked, createdAt: $createdAt, updatedAt: $updatedAt, name: $name, city: $city, avatarUrl: $avatarUrl, kycStatus: $kycStatus)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String id, String phone, String role, bool isBlocked, DateTime createdAt, DateTime updatedAt, String? name, String? city, String? avatarUrl, String? kycStatus
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phone = null,Object? role = null,Object? isBlocked = null,Object? createdAt = null,Object? updatedAt = null,Object? name = freezed,Object? city = freezed,Object? avatarUrl = freezed,Object? kycStatus = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String phone,  String role,  bool isBlocked,  DateTime createdAt,  DateTime updatedAt,  String? name,  String? city,  String? avatarUrl,  String? kycStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.phone,_that.role,_that.isBlocked,_that.createdAt,_that.updatedAt,_that.name,_that.city,_that.avatarUrl,_that.kycStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String phone,  String role,  bool isBlocked,  DateTime createdAt,  DateTime updatedAt,  String? name,  String? city,  String? avatarUrl,  String? kycStatus)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.id,_that.phone,_that.role,_that.isBlocked,_that.createdAt,_that.updatedAt,_that.name,_that.city,_that.avatarUrl,_that.kycStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String phone,  String role,  bool isBlocked,  DateTime createdAt,  DateTime updatedAt,  String? name,  String? city,  String? avatarUrl,  String? kycStatus)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.id,_that.phone,_that.role,_that.isBlocked,_that.createdAt,_that.updatedAt,_that.name,_that.city,_that.avatarUrl,_that.kycStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.id, required this.phone, required this.role, required this.isBlocked, required this.createdAt, required this.updatedAt, this.name, this.city, this.avatarUrl, this.kycStatus});
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

@override final  String id;
@override final  String phone;
@override final  String role;
@override final  bool isBlocked;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? name;
@override final  String? city;
@override final  String? avatarUrl;
@override final  String? kycStatus;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.role, role) || other.role == role)&&(identical(other.isBlocked, isBlocked) || other.isBlocked == isBlocked)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.name, name) || other.name == name)&&(identical(other.city, city) || other.city == city)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.kycStatus, kycStatus) || other.kycStatus == kycStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phone,role,isBlocked,createdAt,updatedAt,name,city,avatarUrl,kycStatus);

@override
String toString() {
  return 'UserProfile(id: $id, phone: $phone, role: $role, isBlocked: $isBlocked, createdAt: $createdAt, updatedAt: $updatedAt, name: $name, city: $city, avatarUrl: $avatarUrl, kycStatus: $kycStatus)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String phone, String role, bool isBlocked, DateTime createdAt, DateTime updatedAt, String? name, String? city, String? avatarUrl, String? kycStatus
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phone = null,Object? role = null,Object? isBlocked = null,Object? createdAt = null,Object? updatedAt = null,Object? name = freezed,Object? city = freezed,Object? avatarUrl = freezed,Object? kycStatus = freezed,}) {
  return _then(_UserProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isBlocked: null == isBlocked ? _self.isBlocked : isBlocked // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,kycStatus: freezed == kycStatus ? _self.kycStatus : kycStatus // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PresignedAvatarUpload {

 String get intentId; String get uploadUrl; Map<String, String> get fields;
/// Create a copy of PresignedAvatarUpload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PresignedAvatarUploadCopyWith<PresignedAvatarUpload> get copyWith => _$PresignedAvatarUploadCopyWithImpl<PresignedAvatarUpload>(this as PresignedAvatarUpload, _$identity);

  /// Serializes this PresignedAvatarUpload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PresignedAvatarUpload&&(identical(other.intentId, intentId) || other.intentId == intentId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&const DeepCollectionEquality().equals(other.fields, fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intentId,uploadUrl,const DeepCollectionEquality().hash(fields));

@override
String toString() {
  return 'PresignedAvatarUpload(intentId: $intentId, uploadUrl: $uploadUrl, fields: $fields)';
}


}

/// @nodoc
abstract mixin class $PresignedAvatarUploadCopyWith<$Res>  {
  factory $PresignedAvatarUploadCopyWith(PresignedAvatarUpload value, $Res Function(PresignedAvatarUpload) _then) = _$PresignedAvatarUploadCopyWithImpl;
@useResult
$Res call({
 String intentId, String uploadUrl, Map<String, String> fields
});




}
/// @nodoc
class _$PresignedAvatarUploadCopyWithImpl<$Res>
    implements $PresignedAvatarUploadCopyWith<$Res> {
  _$PresignedAvatarUploadCopyWithImpl(this._self, this._then);

  final PresignedAvatarUpload _self;
  final $Res Function(PresignedAvatarUpload) _then;

/// Create a copy of PresignedAvatarUpload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? intentId = null,Object? uploadUrl = null,Object? fields = null,}) {
  return _then(_self.copyWith(
intentId: null == intentId ? _self.intentId : intentId // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PresignedAvatarUpload].
extension PresignedAvatarUploadPatterns on PresignedAvatarUpload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PresignedAvatarUpload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PresignedAvatarUpload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PresignedAvatarUpload value)  $default,){
final _that = this;
switch (_that) {
case _PresignedAvatarUpload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PresignedAvatarUpload value)?  $default,){
final _that = this;
switch (_that) {
case _PresignedAvatarUpload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String intentId,  String uploadUrl,  Map<String, String> fields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PresignedAvatarUpload() when $default != null:
return $default(_that.intentId,_that.uploadUrl,_that.fields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String intentId,  String uploadUrl,  Map<String, String> fields)  $default,) {final _that = this;
switch (_that) {
case _PresignedAvatarUpload():
return $default(_that.intentId,_that.uploadUrl,_that.fields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String intentId,  String uploadUrl,  Map<String, String> fields)?  $default,) {final _that = this;
switch (_that) {
case _PresignedAvatarUpload() when $default != null:
return $default(_that.intentId,_that.uploadUrl,_that.fields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PresignedAvatarUpload implements PresignedAvatarUpload {
  const _PresignedAvatarUpload({required this.intentId, required this.uploadUrl, required final  Map<String, String> fields}): _fields = fields;
  factory _PresignedAvatarUpload.fromJson(Map<String, dynamic> json) => _$PresignedAvatarUploadFromJson(json);

@override final  String intentId;
@override final  String uploadUrl;
 final  Map<String, String> _fields;
@override Map<String, String> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}


/// Create a copy of PresignedAvatarUpload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PresignedAvatarUploadCopyWith<_PresignedAvatarUpload> get copyWith => __$PresignedAvatarUploadCopyWithImpl<_PresignedAvatarUpload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PresignedAvatarUploadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PresignedAvatarUpload&&(identical(other.intentId, intentId) || other.intentId == intentId)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&const DeepCollectionEquality().equals(other._fields, _fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,intentId,uploadUrl,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'PresignedAvatarUpload(intentId: $intentId, uploadUrl: $uploadUrl, fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$PresignedAvatarUploadCopyWith<$Res> implements $PresignedAvatarUploadCopyWith<$Res> {
  factory _$PresignedAvatarUploadCopyWith(_PresignedAvatarUpload value, $Res Function(_PresignedAvatarUpload) _then) = __$PresignedAvatarUploadCopyWithImpl;
@override @useResult
$Res call({
 String intentId, String uploadUrl, Map<String, String> fields
});




}
/// @nodoc
class __$PresignedAvatarUploadCopyWithImpl<$Res>
    implements _$PresignedAvatarUploadCopyWith<$Res> {
  __$PresignedAvatarUploadCopyWithImpl(this._self, this._then);

  final _PresignedAvatarUpload _self;
  final $Res Function(_PresignedAvatarUpload) _then;

/// Create a copy of PresignedAvatarUpload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? intentId = null,Object? uploadUrl = null,Object? fields = null,}) {
  return _then(_PresignedAvatarUpload(
intentId: null == intentId ? _self.intentId : intentId // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}


/// @nodoc
mixin _$AvatarUploadResult {

 String get avatarUrl;
/// Create a copy of AvatarUploadResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvatarUploadResultCopyWith<AvatarUploadResult> get copyWith => _$AvatarUploadResultCopyWithImpl<AvatarUploadResult>(this as AvatarUploadResult, _$identity);

  /// Serializes this AvatarUploadResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvatarUploadResult&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarUrl);

@override
String toString() {
  return 'AvatarUploadResult(avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $AvatarUploadResultCopyWith<$Res>  {
  factory $AvatarUploadResultCopyWith(AvatarUploadResult value, $Res Function(AvatarUploadResult) _then) = _$AvatarUploadResultCopyWithImpl;
@useResult
$Res call({
 String avatarUrl
});




}
/// @nodoc
class _$AvatarUploadResultCopyWithImpl<$Res>
    implements $AvatarUploadResultCopyWith<$Res> {
  _$AvatarUploadResultCopyWithImpl(this._self, this._then);

  final AvatarUploadResult _self;
  final $Res Function(AvatarUploadResult) _then;

/// Create a copy of AvatarUploadResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avatarUrl = null,}) {
  return _then(_self.copyWith(
avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AvatarUploadResult].
extension AvatarUploadResultPatterns on AvatarUploadResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvatarUploadResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvatarUploadResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvatarUploadResult value)  $default,){
final _that = this;
switch (_that) {
case _AvatarUploadResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvatarUploadResult value)?  $default,){
final _that = this;
switch (_that) {
case _AvatarUploadResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvatarUploadResult() when $default != null:
return $default(_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _AvatarUploadResult():
return $default(_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _AvatarUploadResult() when $default != null:
return $default(_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvatarUploadResult implements AvatarUploadResult {
  const _AvatarUploadResult({required this.avatarUrl});
  factory _AvatarUploadResult.fromJson(Map<String, dynamic> json) => _$AvatarUploadResultFromJson(json);

@override final  String avatarUrl;

/// Create a copy of AvatarUploadResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvatarUploadResultCopyWith<_AvatarUploadResult> get copyWith => __$AvatarUploadResultCopyWithImpl<_AvatarUploadResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvatarUploadResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvatarUploadResult&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,avatarUrl);

@override
String toString() {
  return 'AvatarUploadResult(avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$AvatarUploadResultCopyWith<$Res> implements $AvatarUploadResultCopyWith<$Res> {
  factory _$AvatarUploadResultCopyWith(_AvatarUploadResult value, $Res Function(_AvatarUploadResult) _then) = __$AvatarUploadResultCopyWithImpl;
@override @useResult
$Res call({
 String avatarUrl
});




}
/// @nodoc
class __$AvatarUploadResultCopyWithImpl<$Res>
    implements _$AvatarUploadResultCopyWith<$Res> {
  __$AvatarUploadResultCopyWithImpl(this._self, this._then);

  final _AvatarUploadResult _self;
  final $Res Function(_AvatarUploadResult) _then;

/// Create a copy of AvatarUploadResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avatarUrl = null,}) {
  return _then(_AvatarUploadResult(
avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AccountClosureResult {

 String get status; DateTime get requestedAt; DateTime? get anonymizedAt;
/// Create a copy of AccountClosureResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountClosureResultCopyWith<AccountClosureResult> get copyWith => _$AccountClosureResultCopyWithImpl<AccountClosureResult>(this as AccountClosureResult, _$identity);

  /// Serializes this AccountClosureResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountClosureResult&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.anonymizedAt, anonymizedAt) || other.anonymizedAt == anonymizedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,requestedAt,anonymizedAt);

@override
String toString() {
  return 'AccountClosureResult(status: $status, requestedAt: $requestedAt, anonymizedAt: $anonymizedAt)';
}


}

/// @nodoc
abstract mixin class $AccountClosureResultCopyWith<$Res>  {
  factory $AccountClosureResultCopyWith(AccountClosureResult value, $Res Function(AccountClosureResult) _then) = _$AccountClosureResultCopyWithImpl;
@useResult
$Res call({
 String status, DateTime requestedAt, DateTime? anonymizedAt
});




}
/// @nodoc
class _$AccountClosureResultCopyWithImpl<$Res>
    implements $AccountClosureResultCopyWith<$Res> {
  _$AccountClosureResultCopyWithImpl(this._self, this._then);

  final AccountClosureResult _self;
  final $Res Function(AccountClosureResult) _then;

/// Create a copy of AccountClosureResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? requestedAt = null,Object? anonymizedAt = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,anonymizedAt: freezed == anonymizedAt ? _self.anonymizedAt : anonymizedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountClosureResult].
extension AccountClosureResultPatterns on AccountClosureResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountClosureResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountClosureResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountClosureResult value)  $default,){
final _that = this;
switch (_that) {
case _AccountClosureResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountClosureResult value)?  $default,){
final _that = this;
switch (_that) {
case _AccountClosureResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  DateTime requestedAt,  DateTime? anonymizedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountClosureResult() when $default != null:
return $default(_that.status,_that.requestedAt,_that.anonymizedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  DateTime requestedAt,  DateTime? anonymizedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountClosureResult():
return $default(_that.status,_that.requestedAt,_that.anonymizedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  DateTime requestedAt,  DateTime? anonymizedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountClosureResult() when $default != null:
return $default(_that.status,_that.requestedAt,_that.anonymizedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AccountClosureResult implements AccountClosureResult {
  const _AccountClosureResult({required this.status, required this.requestedAt, this.anonymizedAt});
  factory _AccountClosureResult.fromJson(Map<String, dynamic> json) => _$AccountClosureResultFromJson(json);

@override final  String status;
@override final  DateTime requestedAt;
@override final  DateTime? anonymizedAt;

/// Create a copy of AccountClosureResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountClosureResultCopyWith<_AccountClosureResult> get copyWith => __$AccountClosureResultCopyWithImpl<_AccountClosureResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AccountClosureResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountClosureResult&&(identical(other.status, status) || other.status == status)&&(identical(other.requestedAt, requestedAt) || other.requestedAt == requestedAt)&&(identical(other.anonymizedAt, anonymizedAt) || other.anonymizedAt == anonymizedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,requestedAt,anonymizedAt);

@override
String toString() {
  return 'AccountClosureResult(status: $status, requestedAt: $requestedAt, anonymizedAt: $anonymizedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountClosureResultCopyWith<$Res> implements $AccountClosureResultCopyWith<$Res> {
  factory _$AccountClosureResultCopyWith(_AccountClosureResult value, $Res Function(_AccountClosureResult) _then) = __$AccountClosureResultCopyWithImpl;
@override @useResult
$Res call({
 String status, DateTime requestedAt, DateTime? anonymizedAt
});




}
/// @nodoc
class __$AccountClosureResultCopyWithImpl<$Res>
    implements _$AccountClosureResultCopyWith<$Res> {
  __$AccountClosureResultCopyWithImpl(this._self, this._then);

  final _AccountClosureResult _self;
  final $Res Function(_AccountClosureResult) _then;

/// Create a copy of AccountClosureResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? requestedAt = null,Object? anonymizedAt = freezed,}) {
  return _then(_AccountClosureResult(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,requestedAt: null == requestedAt ? _self.requestedAt : requestedAt // ignore: cast_nullable_to_non_nullable
as DateTime,anonymizedAt: freezed == anonymizedAt ? _self.anonymizedAt : anonymizedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$UserStepUpResult {

 String get stepUpToken; int get expiresInSeconds;
/// Create a copy of UserStepUpResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserStepUpResultCopyWith<UserStepUpResult> get copyWith => _$UserStepUpResultCopyWithImpl<UserStepUpResult>(this as UserStepUpResult, _$identity);

  /// Serializes this UserStepUpResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserStepUpResult&&(identical(other.stepUpToken, stepUpToken) || other.stepUpToken == stepUpToken)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stepUpToken,expiresInSeconds);

@override
String toString() {
  return 'UserStepUpResult(stepUpToken: $stepUpToken, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class $UserStepUpResultCopyWith<$Res>  {
  factory $UserStepUpResultCopyWith(UserStepUpResult value, $Res Function(UserStepUpResult) _then) = _$UserStepUpResultCopyWithImpl;
@useResult
$Res call({
 String stepUpToken, int expiresInSeconds
});




}
/// @nodoc
class _$UserStepUpResultCopyWithImpl<$Res>
    implements $UserStepUpResultCopyWith<$Res> {
  _$UserStepUpResultCopyWithImpl(this._self, this._then);

  final UserStepUpResult _self;
  final $Res Function(UserStepUpResult) _then;

/// Create a copy of UserStepUpResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stepUpToken = null,Object? expiresInSeconds = null,}) {
  return _then(_self.copyWith(
stepUpToken: null == stepUpToken ? _self.stepUpToken : stepUpToken // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserStepUpResult].
extension UserStepUpResultPatterns on UserStepUpResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserStepUpResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserStepUpResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserStepUpResult value)  $default,){
final _that = this;
switch (_that) {
case _UserStepUpResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserStepUpResult value)?  $default,){
final _that = this;
switch (_that) {
case _UserStepUpResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stepUpToken,  int expiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserStepUpResult() when $default != null:
return $default(_that.stepUpToken,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stepUpToken,  int expiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _UserStepUpResult():
return $default(_that.stepUpToken,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stepUpToken,  int expiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _UserStepUpResult() when $default != null:
return $default(_that.stepUpToken,_that.expiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserStepUpResult implements UserStepUpResult {
  const _UserStepUpResult({required this.stepUpToken, required this.expiresInSeconds});
  factory _UserStepUpResult.fromJson(Map<String, dynamic> json) => _$UserStepUpResultFromJson(json);

@override final  String stepUpToken;
@override final  int expiresInSeconds;

/// Create a copy of UserStepUpResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserStepUpResultCopyWith<_UserStepUpResult> get copyWith => __$UserStepUpResultCopyWithImpl<_UserStepUpResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserStepUpResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserStepUpResult&&(identical(other.stepUpToken, stepUpToken) || other.stepUpToken == stepUpToken)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stepUpToken,expiresInSeconds);

@override
String toString() {
  return 'UserStepUpResult(stepUpToken: $stepUpToken, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$UserStepUpResultCopyWith<$Res> implements $UserStepUpResultCopyWith<$Res> {
  factory _$UserStepUpResultCopyWith(_UserStepUpResult value, $Res Function(_UserStepUpResult) _then) = __$UserStepUpResultCopyWithImpl;
@override @useResult
$Res call({
 String stepUpToken, int expiresInSeconds
});




}
/// @nodoc
class __$UserStepUpResultCopyWithImpl<$Res>
    implements _$UserStepUpResultCopyWith<$Res> {
  __$UserStepUpResultCopyWithImpl(this._self, this._then);

  final _UserStepUpResult _self;
  final $Res Function(_UserStepUpResult) _then;

/// Create a copy of UserStepUpResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stepUpToken = null,Object? expiresInSeconds = null,}) {
  return _then(_UserStepUpResult(
stepUpToken: null == stepUpToken ? _self.stepUpToken : stepUpToken // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$UserDataExport {

 String get schemaVersion; DateTime get generatedAt; String get retentionPolicyVersion; Map<String, Object?> get profile; List<Map<String, Object?>> get listings; List<Map<String, Object?>> get bookings; List<Map<String, Object?>> get inbox; List<Map<String, Object?>> get support; List<Map<String, Object?>> get reports; List<Map<String, Object?>> get blocks; List<Map<String, Object?>> get documentAcceptances; List<Map<String, Object?>> get financialHistory; List<Map<String, Object?>> get fileManifest; Map<String, Object?> get processing;
/// Create a copy of UserDataExport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDataExportCopyWith<UserDataExport> get copyWith => _$UserDataExportCopyWithImpl<UserDataExport>(this as UserDataExport, _$identity);

  /// Serializes this UserDataExport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDataExport&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.retentionPolicyVersion, retentionPolicyVersion) || other.retentionPolicyVersion == retentionPolicyVersion)&&const DeepCollectionEquality().equals(other.profile, profile)&&const DeepCollectionEquality().equals(other.listings, listings)&&const DeepCollectionEquality().equals(other.bookings, bookings)&&const DeepCollectionEquality().equals(other.inbox, inbox)&&const DeepCollectionEquality().equals(other.support, support)&&const DeepCollectionEquality().equals(other.reports, reports)&&const DeepCollectionEquality().equals(other.blocks, blocks)&&const DeepCollectionEquality().equals(other.documentAcceptances, documentAcceptances)&&const DeepCollectionEquality().equals(other.financialHistory, financialHistory)&&const DeepCollectionEquality().equals(other.fileManifest, fileManifest)&&const DeepCollectionEquality().equals(other.processing, processing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,generatedAt,retentionPolicyVersion,const DeepCollectionEquality().hash(profile),const DeepCollectionEquality().hash(listings),const DeepCollectionEquality().hash(bookings),const DeepCollectionEquality().hash(inbox),const DeepCollectionEquality().hash(support),const DeepCollectionEquality().hash(reports),const DeepCollectionEquality().hash(blocks),const DeepCollectionEquality().hash(documentAcceptances),const DeepCollectionEquality().hash(financialHistory),const DeepCollectionEquality().hash(fileManifest),const DeepCollectionEquality().hash(processing));

@override
String toString() {
  return 'UserDataExport(schemaVersion: $schemaVersion, generatedAt: $generatedAt, retentionPolicyVersion: $retentionPolicyVersion, profile: $profile, listings: $listings, bookings: $bookings, inbox: $inbox, support: $support, reports: $reports, blocks: $blocks, documentAcceptances: $documentAcceptances, financialHistory: $financialHistory, fileManifest: $fileManifest, processing: $processing)';
}


}

/// @nodoc
abstract mixin class $UserDataExportCopyWith<$Res>  {
  factory $UserDataExportCopyWith(UserDataExport value, $Res Function(UserDataExport) _then) = _$UserDataExportCopyWithImpl;
@useResult
$Res call({
 String schemaVersion, DateTime generatedAt, String retentionPolicyVersion, Map<String, Object?> profile, List<Map<String, Object?>> listings, List<Map<String, Object?>> bookings, List<Map<String, Object?>> inbox, List<Map<String, Object?>> support, List<Map<String, Object?>> reports, List<Map<String, Object?>> blocks, List<Map<String, Object?>> documentAcceptances, List<Map<String, Object?>> financialHistory, List<Map<String, Object?>> fileManifest, Map<String, Object?> processing
});




}
/// @nodoc
class _$UserDataExportCopyWithImpl<$Res>
    implements $UserDataExportCopyWith<$Res> {
  _$UserDataExportCopyWithImpl(this._self, this._then);

  final UserDataExport _self;
  final $Res Function(UserDataExport) _then;

/// Create a copy of UserDataExport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? generatedAt = null,Object? retentionPolicyVersion = null,Object? profile = null,Object? listings = null,Object? bookings = null,Object? inbox = null,Object? support = null,Object? reports = null,Object? blocks = null,Object? documentAcceptances = null,Object? financialHistory = null,Object? fileManifest = null,Object? processing = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,retentionPolicyVersion: null == retentionPolicyVersion ? _self.retentionPolicyVersion : retentionPolicyVersion // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,listings: null == listings ? _self.listings : listings // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,bookings: null == bookings ? _self.bookings : bookings // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,inbox: null == inbox ? _self.inbox : inbox // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,support: null == support ? _self.support : support // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,reports: null == reports ? _self.reports : reports // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,blocks: null == blocks ? _self.blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,documentAcceptances: null == documentAcceptances ? _self.documentAcceptances : documentAcceptances // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,financialHistory: null == financialHistory ? _self.financialHistory : financialHistory // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,fileManifest: null == fileManifest ? _self.fileManifest : fileManifest // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,processing: null == processing ? _self.processing : processing // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserDataExport].
extension UserDataExportPatterns on UserDataExport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserDataExport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserDataExport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserDataExport value)  $default,){
final _that = this;
switch (_that) {
case _UserDataExport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserDataExport value)?  $default,){
final _that = this;
switch (_that) {
case _UserDataExport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schemaVersion,  DateTime generatedAt,  String retentionPolicyVersion,  Map<String, Object?> profile,  List<Map<String, Object?>> listings,  List<Map<String, Object?>> bookings,  List<Map<String, Object?>> inbox,  List<Map<String, Object?>> support,  List<Map<String, Object?>> reports,  List<Map<String, Object?>> blocks,  List<Map<String, Object?>> documentAcceptances,  List<Map<String, Object?>> financialHistory,  List<Map<String, Object?>> fileManifest,  Map<String, Object?> processing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserDataExport() when $default != null:
return $default(_that.schemaVersion,_that.generatedAt,_that.retentionPolicyVersion,_that.profile,_that.listings,_that.bookings,_that.inbox,_that.support,_that.reports,_that.blocks,_that.documentAcceptances,_that.financialHistory,_that.fileManifest,_that.processing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schemaVersion,  DateTime generatedAt,  String retentionPolicyVersion,  Map<String, Object?> profile,  List<Map<String, Object?>> listings,  List<Map<String, Object?>> bookings,  List<Map<String, Object?>> inbox,  List<Map<String, Object?>> support,  List<Map<String, Object?>> reports,  List<Map<String, Object?>> blocks,  List<Map<String, Object?>> documentAcceptances,  List<Map<String, Object?>> financialHistory,  List<Map<String, Object?>> fileManifest,  Map<String, Object?> processing)  $default,) {final _that = this;
switch (_that) {
case _UserDataExport():
return $default(_that.schemaVersion,_that.generatedAt,_that.retentionPolicyVersion,_that.profile,_that.listings,_that.bookings,_that.inbox,_that.support,_that.reports,_that.blocks,_that.documentAcceptances,_that.financialHistory,_that.fileManifest,_that.processing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schemaVersion,  DateTime generatedAt,  String retentionPolicyVersion,  Map<String, Object?> profile,  List<Map<String, Object?>> listings,  List<Map<String, Object?>> bookings,  List<Map<String, Object?>> inbox,  List<Map<String, Object?>> support,  List<Map<String, Object?>> reports,  List<Map<String, Object?>> blocks,  List<Map<String, Object?>> documentAcceptances,  List<Map<String, Object?>> financialHistory,  List<Map<String, Object?>> fileManifest,  Map<String, Object?> processing)?  $default,) {final _that = this;
switch (_that) {
case _UserDataExport() when $default != null:
return $default(_that.schemaVersion,_that.generatedAt,_that.retentionPolicyVersion,_that.profile,_that.listings,_that.bookings,_that.inbox,_that.support,_that.reports,_that.blocks,_that.documentAcceptances,_that.financialHistory,_that.fileManifest,_that.processing);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserDataExport implements UserDataExport {
  const _UserDataExport({required this.schemaVersion, required this.generatedAt, required this.retentionPolicyVersion, required final  Map<String, Object?> profile, required final  List<Map<String, Object?>> listings, required final  List<Map<String, Object?>> bookings, required final  List<Map<String, Object?>> inbox, required final  List<Map<String, Object?>> support, required final  List<Map<String, Object?>> reports, required final  List<Map<String, Object?>> blocks, required final  List<Map<String, Object?>> documentAcceptances, required final  List<Map<String, Object?>> financialHistory, required final  List<Map<String, Object?>> fileManifest, required final  Map<String, Object?> processing}): _profile = profile,_listings = listings,_bookings = bookings,_inbox = inbox,_support = support,_reports = reports,_blocks = blocks,_documentAcceptances = documentAcceptances,_financialHistory = financialHistory,_fileManifest = fileManifest,_processing = processing;
  factory _UserDataExport.fromJson(Map<String, dynamic> json) => _$UserDataExportFromJson(json);

@override final  String schemaVersion;
@override final  DateTime generatedAt;
@override final  String retentionPolicyVersion;
 final  Map<String, Object?> _profile;
@override Map<String, Object?> get profile {
  if (_profile is EqualUnmodifiableMapView) return _profile;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_profile);
}

 final  List<Map<String, Object?>> _listings;
@override List<Map<String, Object?>> get listings {
  if (_listings is EqualUnmodifiableListView) return _listings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_listings);
}

 final  List<Map<String, Object?>> _bookings;
@override List<Map<String, Object?>> get bookings {
  if (_bookings is EqualUnmodifiableListView) return _bookings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookings);
}

 final  List<Map<String, Object?>> _inbox;
@override List<Map<String, Object?>> get inbox {
  if (_inbox is EqualUnmodifiableListView) return _inbox;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_inbox);
}

 final  List<Map<String, Object?>> _support;
@override List<Map<String, Object?>> get support {
  if (_support is EqualUnmodifiableListView) return _support;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_support);
}

 final  List<Map<String, Object?>> _reports;
@override List<Map<String, Object?>> get reports {
  if (_reports is EqualUnmodifiableListView) return _reports;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reports);
}

 final  List<Map<String, Object?>> _blocks;
@override List<Map<String, Object?>> get blocks {
  if (_blocks is EqualUnmodifiableListView) return _blocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blocks);
}

 final  List<Map<String, Object?>> _documentAcceptances;
@override List<Map<String, Object?>> get documentAcceptances {
  if (_documentAcceptances is EqualUnmodifiableListView) return _documentAcceptances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documentAcceptances);
}

 final  List<Map<String, Object?>> _financialHistory;
@override List<Map<String, Object?>> get financialHistory {
  if (_financialHistory is EqualUnmodifiableListView) return _financialHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_financialHistory);
}

 final  List<Map<String, Object?>> _fileManifest;
@override List<Map<String, Object?>> get fileManifest {
  if (_fileManifest is EqualUnmodifiableListView) return _fileManifest;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fileManifest);
}

 final  Map<String, Object?> _processing;
@override Map<String, Object?> get processing {
  if (_processing is EqualUnmodifiableMapView) return _processing;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_processing);
}


/// Create a copy of UserDataExport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserDataExportCopyWith<_UserDataExport> get copyWith => __$UserDataExportCopyWithImpl<_UserDataExport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserDataExportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserDataExport&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.retentionPolicyVersion, retentionPolicyVersion) || other.retentionPolicyVersion == retentionPolicyVersion)&&const DeepCollectionEquality().equals(other._profile, _profile)&&const DeepCollectionEquality().equals(other._listings, _listings)&&const DeepCollectionEquality().equals(other._bookings, _bookings)&&const DeepCollectionEquality().equals(other._inbox, _inbox)&&const DeepCollectionEquality().equals(other._support, _support)&&const DeepCollectionEquality().equals(other._reports, _reports)&&const DeepCollectionEquality().equals(other._blocks, _blocks)&&const DeepCollectionEquality().equals(other._documentAcceptances, _documentAcceptances)&&const DeepCollectionEquality().equals(other._financialHistory, _financialHistory)&&const DeepCollectionEquality().equals(other._fileManifest, _fileManifest)&&const DeepCollectionEquality().equals(other._processing, _processing));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,generatedAt,retentionPolicyVersion,const DeepCollectionEquality().hash(_profile),const DeepCollectionEquality().hash(_listings),const DeepCollectionEquality().hash(_bookings),const DeepCollectionEquality().hash(_inbox),const DeepCollectionEquality().hash(_support),const DeepCollectionEquality().hash(_reports),const DeepCollectionEquality().hash(_blocks),const DeepCollectionEquality().hash(_documentAcceptances),const DeepCollectionEquality().hash(_financialHistory),const DeepCollectionEquality().hash(_fileManifest),const DeepCollectionEquality().hash(_processing));

@override
String toString() {
  return 'UserDataExport(schemaVersion: $schemaVersion, generatedAt: $generatedAt, retentionPolicyVersion: $retentionPolicyVersion, profile: $profile, listings: $listings, bookings: $bookings, inbox: $inbox, support: $support, reports: $reports, blocks: $blocks, documentAcceptances: $documentAcceptances, financialHistory: $financialHistory, fileManifest: $fileManifest, processing: $processing)';
}


}

/// @nodoc
abstract mixin class _$UserDataExportCopyWith<$Res> implements $UserDataExportCopyWith<$Res> {
  factory _$UserDataExportCopyWith(_UserDataExport value, $Res Function(_UserDataExport) _then) = __$UserDataExportCopyWithImpl;
@override @useResult
$Res call({
 String schemaVersion, DateTime generatedAt, String retentionPolicyVersion, Map<String, Object?> profile, List<Map<String, Object?>> listings, List<Map<String, Object?>> bookings, List<Map<String, Object?>> inbox, List<Map<String, Object?>> support, List<Map<String, Object?>> reports, List<Map<String, Object?>> blocks, List<Map<String, Object?>> documentAcceptances, List<Map<String, Object?>> financialHistory, List<Map<String, Object?>> fileManifest, Map<String, Object?> processing
});




}
/// @nodoc
class __$UserDataExportCopyWithImpl<$Res>
    implements _$UserDataExportCopyWith<$Res> {
  __$UserDataExportCopyWithImpl(this._self, this._then);

  final _UserDataExport _self;
  final $Res Function(_UserDataExport) _then;

/// Create a copy of UserDataExport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? generatedAt = null,Object? retentionPolicyVersion = null,Object? profile = null,Object? listings = null,Object? bookings = null,Object? inbox = null,Object? support = null,Object? reports = null,Object? blocks = null,Object? documentAcceptances = null,Object? financialHistory = null,Object? fileManifest = null,Object? processing = null,}) {
  return _then(_UserDataExport(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,retentionPolicyVersion: null == retentionPolicyVersion ? _self.retentionPolicyVersion : retentionPolicyVersion // ignore: cast_nullable_to_non_nullable
as String,profile: null == profile ? _self._profile : profile // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,listings: null == listings ? _self._listings : listings // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,bookings: null == bookings ? _self._bookings : bookings // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,inbox: null == inbox ? _self._inbox : inbox // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,support: null == support ? _self._support : support // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,reports: null == reports ? _self._reports : reports // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,blocks: null == blocks ? _self._blocks : blocks // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,documentAcceptances: null == documentAcceptances ? _self._documentAcceptances : documentAcceptances // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,financialHistory: null == financialHistory ? _self._financialHistory : financialHistory // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,fileManifest: null == fileManifest ? _self._fileManifest : fileManifest // ignore: cast_nullable_to_non_nullable
as List<Map<String, Object?>>,processing: null == processing ? _self._processing : processing // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
