// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState()';
}


}

/// @nodoc
class $AuthStateCopyWith<$Res>  {
$AuthStateCopyWith(AuthState _, $Res Function(AuthState) __);
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthLoading value)?  loading,TResult Function( AuthUnauthenticated value)?  unauthenticated,TResult Function( AuthCodeSent value)?  codeSent,TResult Function( AuthAuthenticated value)?  authenticated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthLoading() when loading != null:
return loading(_that);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthCodeSent() when codeSent != null:
return codeSent(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthLoading value)  loading,required TResult Function( AuthUnauthenticated value)  unauthenticated,required TResult Function( AuthCodeSent value)  codeSent,required TResult Function( AuthAuthenticated value)  authenticated,}){
final _that = this;
switch (_that) {
case AuthLoading():
return loading(_that);case AuthUnauthenticated():
return unauthenticated(_that);case AuthCodeSent():
return codeSent(_that);case AuthAuthenticated():
return authenticated(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthLoading value)?  loading,TResult? Function( AuthUnauthenticated value)?  unauthenticated,TResult? Function( AuthCodeSent value)?  codeSent,TResult? Function( AuthAuthenticated value)?  authenticated,}){
final _that = this;
switch (_that) {
case AuthLoading() when loading != null:
return loading(_that);case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that);case AuthCodeSent() when codeSent != null:
return codeSent(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( String? errorMessage,  bool isSubmitting)?  unauthenticated,TResult Function( String phone,  int expiresInSeconds,  String? errorMessage,  bool isSubmitting)?  codeSent,TResult Function( AuthUser user)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthLoading() when loading != null:
return loading();case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that.errorMessage,_that.isSubmitting);case AuthCodeSent() when codeSent != null:
return codeSent(_that.phone,_that.expiresInSeconds,_that.errorMessage,_that.isSubmitting);case AuthAuthenticated() when authenticated != null:
return authenticated(_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( String? errorMessage,  bool isSubmitting)  unauthenticated,required TResult Function( String phone,  int expiresInSeconds,  String? errorMessage,  bool isSubmitting)  codeSent,required TResult Function( AuthUser user)  authenticated,}) {final _that = this;
switch (_that) {
case AuthLoading():
return loading();case AuthUnauthenticated():
return unauthenticated(_that.errorMessage,_that.isSubmitting);case AuthCodeSent():
return codeSent(_that.phone,_that.expiresInSeconds,_that.errorMessage,_that.isSubmitting);case AuthAuthenticated():
return authenticated(_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( String? errorMessage,  bool isSubmitting)?  unauthenticated,TResult? Function( String phone,  int expiresInSeconds,  String? errorMessage,  bool isSubmitting)?  codeSent,TResult? Function( AuthUser user)?  authenticated,}) {final _that = this;
switch (_that) {
case AuthLoading() when loading != null:
return loading();case AuthUnauthenticated() when unauthenticated != null:
return unauthenticated(_that.errorMessage,_that.isSubmitting);case AuthCodeSent() when codeSent != null:
return codeSent(_that.phone,_that.expiresInSeconds,_that.errorMessage,_that.isSubmitting);case AuthAuthenticated() when authenticated != null:
return authenticated(_that.user);case _:
  return null;

}
}

}

/// @nodoc


class AuthLoading extends AuthState {
  const AuthLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthState.loading()';
}


}




/// @nodoc


class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.errorMessage, this.isSubmitting = false}): super._();
  

 final  String? errorMessage;
@JsonKey() final  bool isSubmitting;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUnauthenticatedCopyWith<AuthUnauthenticated> get copyWith => _$AuthUnauthenticatedCopyWithImpl<AuthUnauthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUnauthenticated&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,errorMessage,isSubmitting);

@override
String toString() {
  return 'AuthState.unauthenticated(errorMessage: $errorMessage, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $AuthUnauthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthUnauthenticatedCopyWith(AuthUnauthenticated value, $Res Function(AuthUnauthenticated) _then) = _$AuthUnauthenticatedCopyWithImpl;
@useResult
$Res call({
 String? errorMessage, bool isSubmitting
});




}
/// @nodoc
class _$AuthUnauthenticatedCopyWithImpl<$Res>
    implements $AuthUnauthenticatedCopyWith<$Res> {
  _$AuthUnauthenticatedCopyWithImpl(this._self, this._then);

  final AuthUnauthenticated _self;
  final $Res Function(AuthUnauthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorMessage = freezed,Object? isSubmitting = null,}) {
  return _then(AuthUnauthenticated(
errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AuthCodeSent extends AuthState {
  const AuthCodeSent({required this.phone, required this.expiresInSeconds, this.errorMessage, this.isSubmitting = false}): super._();
  

 final  String phone;
 final  int expiresInSeconds;
 final  String? errorMessage;
@JsonKey() final  bool isSubmitting;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthCodeSentCopyWith<AuthCodeSent> get copyWith => _$AuthCodeSentCopyWithImpl<AuthCodeSent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthCodeSent&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,phone,expiresInSeconds,errorMessage,isSubmitting);

@override
String toString() {
  return 'AuthState.codeSent(phone: $phone, expiresInSeconds: $expiresInSeconds, errorMessage: $errorMessage, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $AuthCodeSentCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthCodeSentCopyWith(AuthCodeSent value, $Res Function(AuthCodeSent) _then) = _$AuthCodeSentCopyWithImpl;
@useResult
$Res call({
 String phone, int expiresInSeconds, String? errorMessage, bool isSubmitting
});




}
/// @nodoc
class _$AuthCodeSentCopyWithImpl<$Res>
    implements $AuthCodeSentCopyWith<$Res> {
  _$AuthCodeSentCopyWithImpl(this._self, this._then);

  final AuthCodeSent _self;
  final $Res Function(AuthCodeSent) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? expiresInSeconds = null,Object? errorMessage = freezed,Object? isSubmitting = null,}) {
  return _then(AuthCodeSent(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user}): super._();
  

 final  AuthUser user;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthAuthenticatedCopyWith<AuthAuthenticated> get copyWith => _$AuthAuthenticatedCopyWithImpl<AuthAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAuthenticated&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'AuthState.authenticated(user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthAuthenticatedCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory $AuthAuthenticatedCopyWith(AuthAuthenticated value, $Res Function(AuthAuthenticated) _then) = _$AuthAuthenticatedCopyWithImpl;
@useResult
$Res call({
 AuthUser user
});


$AuthUserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthAuthenticatedCopyWithImpl<$Res>
    implements $AuthAuthenticatedCopyWith<$Res> {
  _$AuthAuthenticatedCopyWithImpl(this._self, this._then);

  final AuthAuthenticated _self;
  final $Res Function(AuthAuthenticated) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(AuthAuthenticated(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res> get user {
  
  return $AuthUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
