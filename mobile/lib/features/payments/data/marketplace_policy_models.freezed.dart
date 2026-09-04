// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'marketplace_policy_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MarketplaceDepositPolicy {

 bool get enabled; String get currency;@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) int? get maximumMinor; String? get policyVersion;@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) int? get disputeWindowSeconds;
/// Create a copy of MarketplaceDepositPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarketplaceDepositPolicyCopyWith<MarketplaceDepositPolicy> get copyWith => _$MarketplaceDepositPolicyCopyWithImpl<MarketplaceDepositPolicy>(this as MarketplaceDepositPolicy, _$identity);

  /// Serializes this MarketplaceDepositPolicy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketplaceDepositPolicy&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.maximumMinor, maximumMinor) || other.maximumMinor == maximumMinor)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.disputeWindowSeconds, disputeWindowSeconds) || other.disputeWindowSeconds == disputeWindowSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,currency,maximumMinor,policyVersion,disputeWindowSeconds);

@override
String toString() {
  return 'MarketplaceDepositPolicy(enabled: $enabled, currency: $currency, maximumMinor: $maximumMinor, policyVersion: $policyVersion, disputeWindowSeconds: $disputeWindowSeconds)';
}


}

/// @nodoc
abstract mixin class $MarketplaceDepositPolicyCopyWith<$Res>  {
  factory $MarketplaceDepositPolicyCopyWith(MarketplaceDepositPolicy value, $Res Function(MarketplaceDepositPolicy) _then) = _$MarketplaceDepositPolicyCopyWithImpl;
@useResult
$Res call({
 bool enabled, String currency,@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) int? maximumMinor, String? policyVersion,@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) int? disputeWindowSeconds
});




}
/// @nodoc
class _$MarketplaceDepositPolicyCopyWithImpl<$Res>
    implements $MarketplaceDepositPolicyCopyWith<$Res> {
  _$MarketplaceDepositPolicyCopyWithImpl(this._self, this._then);

  final MarketplaceDepositPolicy _self;
  final $Res Function(MarketplaceDepositPolicy) _then;

/// Create a copy of MarketplaceDepositPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? currency = null,Object? maximumMinor = freezed,Object? policyVersion = freezed,Object? disputeWindowSeconds = freezed,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,maximumMinor: freezed == maximumMinor ? _self.maximumMinor : maximumMinor // ignore: cast_nullable_to_non_nullable
as int?,policyVersion: freezed == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String?,disputeWindowSeconds: freezed == disputeWindowSeconds ? _self.disputeWindowSeconds : disputeWindowSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MarketplaceDepositPolicy].
extension MarketplaceDepositPolicyPatterns on MarketplaceDepositPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketplaceDepositPolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketplaceDepositPolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketplaceDepositPolicy value)  $default,){
final _that = this;
switch (_that) {
case _MarketplaceDepositPolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketplaceDepositPolicy value)?  $default,){
final _that = this;
switch (_that) {
case _MarketplaceDepositPolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String currency, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson)  int? maximumMinor,  String? policyVersion, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson)  int? disputeWindowSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketplaceDepositPolicy() when $default != null:
return $default(_that.enabled,_that.currency,_that.maximumMinor,_that.policyVersion,_that.disputeWindowSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String currency, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson)  int? maximumMinor,  String? policyVersion, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson)  int? disputeWindowSeconds)  $default,) {final _that = this;
switch (_that) {
case _MarketplaceDepositPolicy():
return $default(_that.enabled,_that.currency,_that.maximumMinor,_that.policyVersion,_that.disputeWindowSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String currency, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson)  int? maximumMinor,  String? policyVersion, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson)  int? disputeWindowSeconds)?  $default,) {final _that = this;
switch (_that) {
case _MarketplaceDepositPolicy() when $default != null:
return $default(_that.enabled,_that.currency,_that.maximumMinor,_that.policyVersion,_that.disputeWindowSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MarketplaceDepositPolicy implements MarketplaceDepositPolicy {
  const _MarketplaceDepositPolicy({required this.enabled, required this.currency, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson) required this.maximumMinor, required this.policyVersion, @JsonKey(fromJson: _exactNullableSafeIntegerFromJson) required this.disputeWindowSeconds});
  factory _MarketplaceDepositPolicy.fromJson(Map<String, dynamic> json) => _$MarketplaceDepositPolicyFromJson(json);

@override final  bool enabled;
@override final  String currency;
@override@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) final  int? maximumMinor;
@override final  String? policyVersion;
@override@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) final  int? disputeWindowSeconds;

/// Create a copy of MarketplaceDepositPolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MarketplaceDepositPolicyCopyWith<_MarketplaceDepositPolicy> get copyWith => __$MarketplaceDepositPolicyCopyWithImpl<_MarketplaceDepositPolicy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarketplaceDepositPolicyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketplaceDepositPolicy&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.maximumMinor, maximumMinor) || other.maximumMinor == maximumMinor)&&(identical(other.policyVersion, policyVersion) || other.policyVersion == policyVersion)&&(identical(other.disputeWindowSeconds, disputeWindowSeconds) || other.disputeWindowSeconds == disputeWindowSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,currency,maximumMinor,policyVersion,disputeWindowSeconds);

@override
String toString() {
  return 'MarketplaceDepositPolicy(enabled: $enabled, currency: $currency, maximumMinor: $maximumMinor, policyVersion: $policyVersion, disputeWindowSeconds: $disputeWindowSeconds)';
}


}

/// @nodoc
abstract mixin class _$MarketplaceDepositPolicyCopyWith<$Res> implements $MarketplaceDepositPolicyCopyWith<$Res> {
  factory _$MarketplaceDepositPolicyCopyWith(_MarketplaceDepositPolicy value, $Res Function(_MarketplaceDepositPolicy) _then) = __$MarketplaceDepositPolicyCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String currency,@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) int? maximumMinor, String? policyVersion,@JsonKey(fromJson: _exactNullableSafeIntegerFromJson) int? disputeWindowSeconds
});




}
/// @nodoc
class __$MarketplaceDepositPolicyCopyWithImpl<$Res>
    implements _$MarketplaceDepositPolicyCopyWith<$Res> {
  __$MarketplaceDepositPolicyCopyWithImpl(this._self, this._then);

  final _MarketplaceDepositPolicy _self;
  final $Res Function(_MarketplaceDepositPolicy) _then;

/// Create a copy of MarketplaceDepositPolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? currency = null,Object? maximumMinor = freezed,Object? policyVersion = freezed,Object? disputeWindowSeconds = freezed,}) {
  return _then(_MarketplaceDepositPolicy(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,maximumMinor: freezed == maximumMinor ? _self.maximumMinor : maximumMinor // ignore: cast_nullable_to_non_nullable
as int?,policyVersion: freezed == policyVersion ? _self.policyVersion : policyVersion // ignore: cast_nullable_to_non_nullable
as String?,disputeWindowSeconds: freezed == disputeWindowSeconds ? _self.disputeWindowSeconds : disputeWindowSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$MarketplacePolicy {

 PaymentScenario get paymentScenario; MarketplaceDepositPolicy get deposit;

  /// Serializes this MarketplacePolicy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarketplacePolicy&&(identical(other.paymentScenario, paymentScenario) || other.paymentScenario == paymentScenario)&&(identical(other.deposit, deposit) || other.deposit == deposit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentScenario,deposit);

@override
String toString() {
  return 'MarketplacePolicy(paymentScenario: $paymentScenario, deposit: $deposit)';
}


}




/// Adds pattern-matching-related methods to [MarketplacePolicy].
extension MarketplacePolicyPatterns on MarketplacePolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MarketplacePolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MarketplacePolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MarketplacePolicy value)  $default,){
final _that = this;
switch (_that) {
case _MarketplacePolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MarketplacePolicy value)?  $default,){
final _that = this;
switch (_that) {
case _MarketplacePolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PaymentScenario paymentScenario,  MarketplaceDepositPolicy deposit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MarketplacePolicy() when $default != null:
return $default(_that.paymentScenario,_that.deposit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PaymentScenario paymentScenario,  MarketplaceDepositPolicy deposit)  $default,) {final _that = this;
switch (_that) {
case _MarketplacePolicy():
return $default(_that.paymentScenario,_that.deposit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PaymentScenario paymentScenario,  MarketplaceDepositPolicy deposit)?  $default,) {final _that = this;
switch (_that) {
case _MarketplacePolicy() when $default != null:
return $default(_that.paymentScenario,_that.deposit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MarketplacePolicy implements MarketplacePolicy {
  const _MarketplacePolicy({required this.paymentScenario, required this.deposit});
  factory _MarketplacePolicy.fromJson(Map<String, dynamic> json) => _$MarketplacePolicyFromJson(json);

@override final  PaymentScenario paymentScenario;
@override final  MarketplaceDepositPolicy deposit;


@override
Map<String, dynamic> toJson() {
  return _$MarketplacePolicyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MarketplacePolicy&&(identical(other.paymentScenario, paymentScenario) || other.paymentScenario == paymentScenario)&&(identical(other.deposit, deposit) || other.deposit == deposit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,paymentScenario,deposit);

@override
String toString() {
  return 'MarketplacePolicy(paymentScenario: $paymentScenario, deposit: $deposit)';
}


}




// dart format on
