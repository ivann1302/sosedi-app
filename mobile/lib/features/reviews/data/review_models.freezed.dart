// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ParticipantReview {

 String get id; String get author; int get rating; String? get text; bool get published; bool get hidden; DateTime get publishAt; DateTime get createdAt;
/// Create a copy of ParticipantReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantReviewCopyWith<ParticipantReview> get copyWith => _$ParticipantReviewCopyWithImpl<ParticipantReview>(this as ParticipantReview, _$identity);

  /// Serializes this ParticipantReview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParticipantReview&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text)&&(identical(other.published, published) || other.published == published)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.publishAt, publishAt) || other.publishAt == publishAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,rating,text,published,hidden,publishAt,createdAt);

@override
String toString() {
  return 'ParticipantReview(id: $id, author: $author, rating: $rating, text: $text, published: $published, hidden: $hidden, publishAt: $publishAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ParticipantReviewCopyWith<$Res>  {
  factory $ParticipantReviewCopyWith(ParticipantReview value, $Res Function(ParticipantReview) _then) = _$ParticipantReviewCopyWithImpl;
@useResult
$Res call({
 String id, String author, int rating, String? text, bool published, bool hidden, DateTime publishAt, DateTime createdAt
});




}
/// @nodoc
class _$ParticipantReviewCopyWithImpl<$Res>
    implements $ParticipantReviewCopyWith<$Res> {
  _$ParticipantReviewCopyWithImpl(this._self, this._then);

  final ParticipantReview _self;
  final $Res Function(ParticipantReview) _then;

/// Create a copy of ParticipantReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? rating = null,Object? text = freezed,Object? published = null,Object? hidden = null,Object? publishAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,publishAt: null == publishAt ? _self.publishAt : publishAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ParticipantReview].
extension ParticipantReviewPatterns on ParticipantReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParticipantReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParticipantReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParticipantReview value)  $default,){
final _that = this;
switch (_that) {
case _ParticipantReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParticipantReview value)?  $default,){
final _that = this;
switch (_that) {
case _ParticipantReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String author,  int rating,  String? text,  bool published,  bool hidden,  DateTime publishAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParticipantReview() when $default != null:
return $default(_that.id,_that.author,_that.rating,_that.text,_that.published,_that.hidden,_that.publishAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String author,  int rating,  String? text,  bool published,  bool hidden,  DateTime publishAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ParticipantReview():
return $default(_that.id,_that.author,_that.rating,_that.text,_that.published,_that.hidden,_that.publishAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String author,  int rating,  String? text,  bool published,  bool hidden,  DateTime publishAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ParticipantReview() when $default != null:
return $default(_that.id,_that.author,_that.rating,_that.text,_that.published,_that.hidden,_that.publishAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParticipantReview implements ParticipantReview {
  const _ParticipantReview({required this.id, required this.author, required this.rating, required this.text, required this.published, required this.hidden, required this.publishAt, required this.createdAt});
  factory _ParticipantReview.fromJson(Map<String, dynamic> json) => _$ParticipantReviewFromJson(json);

@override final  String id;
@override final  String author;
@override final  int rating;
@override final  String? text;
@override final  bool published;
@override final  bool hidden;
@override final  DateTime publishAt;
@override final  DateTime createdAt;

/// Create a copy of ParticipantReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantReviewCopyWith<_ParticipantReview> get copyWith => __$ParticipantReviewCopyWithImpl<_ParticipantReview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParticipantReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParticipantReview&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text)&&(identical(other.published, published) || other.published == published)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.publishAt, publishAt) || other.publishAt == publishAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,rating,text,published,hidden,publishAt,createdAt);

@override
String toString() {
  return 'ParticipantReview(id: $id, author: $author, rating: $rating, text: $text, published: $published, hidden: $hidden, publishAt: $publishAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ParticipantReviewCopyWith<$Res> implements $ParticipantReviewCopyWith<$Res> {
  factory _$ParticipantReviewCopyWith(_ParticipantReview value, $Res Function(_ParticipantReview) _then) = __$ParticipantReviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String author, int rating, String? text, bool published, bool hidden, DateTime publishAt, DateTime createdAt
});




}
/// @nodoc
class __$ParticipantReviewCopyWithImpl<$Res>
    implements _$ParticipantReviewCopyWith<$Res> {
  __$ParticipantReviewCopyWithImpl(this._self, this._then);

  final _ParticipantReview _self;
  final $Res Function(_ParticipantReview) _then;

/// Create a copy of ParticipantReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? rating = null,Object? text = freezed,Object? published = null,Object? hidden = null,Object? publishAt = null,Object? createdAt = null,}) {
  return _then(_ParticipantReview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,published: null == published ? _self.published : published // ignore: cast_nullable_to_non_nullable
as bool,hidden: null == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool,publishAt: null == publishAt ? _self.publishAt : publishAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$PublicReview {

 String get id; String get authorRole; int get rating; String? get text; bool get verifiedRental; DateTime get publishedAt; DateTime get createdAt;
/// Create a copy of PublicReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicReviewCopyWith<PublicReview> get copyWith => _$PublicReviewCopyWithImpl<PublicReview>(this as PublicReview, _$identity);

  /// Serializes this PublicReview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicReview&&(identical(other.id, id) || other.id == id)&&(identical(other.authorRole, authorRole) || other.authorRole == authorRole)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text)&&(identical(other.verifiedRental, verifiedRental) || other.verifiedRental == verifiedRental)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorRole,rating,text,verifiedRental,publishedAt,createdAt);

@override
String toString() {
  return 'PublicReview(id: $id, authorRole: $authorRole, rating: $rating, text: $text, verifiedRental: $verifiedRental, publishedAt: $publishedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $PublicReviewCopyWith<$Res>  {
  factory $PublicReviewCopyWith(PublicReview value, $Res Function(PublicReview) _then) = _$PublicReviewCopyWithImpl;
@useResult
$Res call({
 String id, String authorRole, int rating, String? text, bool verifiedRental, DateTime publishedAt, DateTime createdAt
});




}
/// @nodoc
class _$PublicReviewCopyWithImpl<$Res>
    implements $PublicReviewCopyWith<$Res> {
  _$PublicReviewCopyWithImpl(this._self, this._then);

  final PublicReview _self;
  final $Res Function(PublicReview) _then;

/// Create a copy of PublicReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorRole = null,Object? rating = null,Object? text = freezed,Object? verifiedRental = null,Object? publishedAt = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorRole: null == authorRole ? _self.authorRole : authorRole // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,verifiedRental: null == verifiedRental ? _self.verifiedRental : verifiedRental // ignore: cast_nullable_to_non_nullable
as bool,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PublicReview].
extension PublicReviewPatterns on PublicReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicReview value)  $default,){
final _that = this;
switch (_that) {
case _PublicReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicReview value)?  $default,){
final _that = this;
switch (_that) {
case _PublicReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String authorRole,  int rating,  String? text,  bool verifiedRental,  DateTime publishedAt,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicReview() when $default != null:
return $default(_that.id,_that.authorRole,_that.rating,_that.text,_that.verifiedRental,_that.publishedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String authorRole,  int rating,  String? text,  bool verifiedRental,  DateTime publishedAt,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _PublicReview():
return $default(_that.id,_that.authorRole,_that.rating,_that.text,_that.verifiedRental,_that.publishedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String authorRole,  int rating,  String? text,  bool verifiedRental,  DateTime publishedAt,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _PublicReview() when $default != null:
return $default(_that.id,_that.authorRole,_that.rating,_that.text,_that.verifiedRental,_that.publishedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicReview implements PublicReview {
  const _PublicReview({required this.id, required this.authorRole, required this.rating, required this.text, required this.verifiedRental, required this.publishedAt, required this.createdAt});
  factory _PublicReview.fromJson(Map<String, dynamic> json) => _$PublicReviewFromJson(json);

@override final  String id;
@override final  String authorRole;
@override final  int rating;
@override final  String? text;
@override final  bool verifiedRental;
@override final  DateTime publishedAt;
@override final  DateTime createdAt;

/// Create a copy of PublicReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicReviewCopyWith<_PublicReview> get copyWith => __$PublicReviewCopyWithImpl<_PublicReview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicReview&&(identical(other.id, id) || other.id == id)&&(identical(other.authorRole, authorRole) || other.authorRole == authorRole)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text)&&(identical(other.verifiedRental, verifiedRental) || other.verifiedRental == verifiedRental)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorRole,rating,text,verifiedRental,publishedAt,createdAt);

@override
String toString() {
  return 'PublicReview(id: $id, authorRole: $authorRole, rating: $rating, text: $text, verifiedRental: $verifiedRental, publishedAt: $publishedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$PublicReviewCopyWith<$Res> implements $PublicReviewCopyWith<$Res> {
  factory _$PublicReviewCopyWith(_PublicReview value, $Res Function(_PublicReview) _then) = __$PublicReviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String authorRole, int rating, String? text, bool verifiedRental, DateTime publishedAt, DateTime createdAt
});




}
/// @nodoc
class __$PublicReviewCopyWithImpl<$Res>
    implements _$PublicReviewCopyWith<$Res> {
  __$PublicReviewCopyWithImpl(this._self, this._then);

  final _PublicReview _self;
  final $Res Function(_PublicReview) _then;

/// Create a copy of PublicReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorRole = null,Object? rating = null,Object? text = freezed,Object? verifiedRental = null,Object? publishedAt = null,Object? createdAt = null,}) {
  return _then(_PublicReview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,authorRole: null == authorRole ? _self.authorRole : authorRole // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,verifiedRental: null == verifiedRental ? _self.verifiedRental : verifiedRental // ignore: cast_nullable_to_non_nullable
as bool,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ReviewSummary {

 double? get average; int get count;
/// Create a copy of ReviewSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewSummaryCopyWith<ReviewSummary> get copyWith => _$ReviewSummaryCopyWithImpl<ReviewSummary>(this as ReviewSummary, _$identity);

  /// Serializes this ReviewSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewSummary&&(identical(other.average, average) || other.average == average)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,average,count);

@override
String toString() {
  return 'ReviewSummary(average: $average, count: $count)';
}


}

/// @nodoc
abstract mixin class $ReviewSummaryCopyWith<$Res>  {
  factory $ReviewSummaryCopyWith(ReviewSummary value, $Res Function(ReviewSummary) _then) = _$ReviewSummaryCopyWithImpl;
@useResult
$Res call({
 double? average, int count
});




}
/// @nodoc
class _$ReviewSummaryCopyWithImpl<$Res>
    implements $ReviewSummaryCopyWith<$Res> {
  _$ReviewSummaryCopyWithImpl(this._self, this._then);

  final ReviewSummary _self;
  final $Res Function(ReviewSummary) _then;

/// Create a copy of ReviewSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? average = freezed,Object? count = null,}) {
  return _then(_self.copyWith(
average: freezed == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double?,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewSummary].
extension ReviewSummaryPatterns on ReviewSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewSummary value)  $default,){
final _that = this;
switch (_that) {
case _ReviewSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? average,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewSummary() when $default != null:
return $default(_that.average,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? average,  int count)  $default,) {final _that = this;
switch (_that) {
case _ReviewSummary():
return $default(_that.average,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? average,  int count)?  $default,) {final _that = this;
switch (_that) {
case _ReviewSummary() when $default != null:
return $default(_that.average,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewSummary implements ReviewSummary {
  const _ReviewSummary({required this.average, required this.count});
  factory _ReviewSummary.fromJson(Map<String, dynamic> json) => _$ReviewSummaryFromJson(json);

@override final  double? average;
@override final  int count;

/// Create a copy of ReviewSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewSummaryCopyWith<_ReviewSummary> get copyWith => __$ReviewSummaryCopyWithImpl<_ReviewSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewSummary&&(identical(other.average, average) || other.average == average)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,average,count);

@override
String toString() {
  return 'ReviewSummary(average: $average, count: $count)';
}


}

/// @nodoc
abstract mixin class _$ReviewSummaryCopyWith<$Res> implements $ReviewSummaryCopyWith<$Res> {
  factory _$ReviewSummaryCopyWith(_ReviewSummary value, $Res Function(_ReviewSummary) _then) = __$ReviewSummaryCopyWithImpl;
@override @useResult
$Res call({
 double? average, int count
});




}
/// @nodoc
class __$ReviewSummaryCopyWithImpl<$Res>
    implements _$ReviewSummaryCopyWith<$Res> {
  __$ReviewSummaryCopyWithImpl(this._self, this._then);

  final _ReviewSummary _self;
  final $Res Function(_ReviewSummary) _then;

/// Create a copy of ReviewSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? average = freezed,Object? count = null,}) {
  return _then(_ReviewSummary(
average: freezed == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double?,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PublicReviewPage {

 ReviewSummary get summary; List<PublicReview> get items; String? get nextCursor;
/// Create a copy of PublicReviewPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicReviewPageCopyWith<PublicReviewPage> get copyWith => _$PublicReviewPageCopyWithImpl<PublicReviewPage>(this as PublicReviewPage, _$identity);

  /// Serializes this PublicReviewPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicReviewPage&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'PublicReviewPage(summary: $summary, items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $PublicReviewPageCopyWith<$Res>  {
  factory $PublicReviewPageCopyWith(PublicReviewPage value, $Res Function(PublicReviewPage) _then) = _$PublicReviewPageCopyWithImpl;
@useResult
$Res call({
 ReviewSummary summary, List<PublicReview> items, String? nextCursor
});


$ReviewSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$PublicReviewPageCopyWithImpl<$Res>
    implements $PublicReviewPageCopyWith<$Res> {
  _$PublicReviewPageCopyWithImpl(this._self, this._then);

  final PublicReviewPage _self;
  final $Res Function(PublicReviewPage) _then;

/// Create a copy of PublicReviewPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as ReviewSummary,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PublicReview>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PublicReviewPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewSummaryCopyWith<$Res> get summary {
  
  return $ReviewSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [PublicReviewPage].
extension PublicReviewPagePatterns on PublicReviewPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PublicReviewPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PublicReviewPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PublicReviewPage value)  $default,){
final _that = this;
switch (_that) {
case _PublicReviewPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PublicReviewPage value)?  $default,){
final _that = this;
switch (_that) {
case _PublicReviewPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReviewSummary summary,  List<PublicReview> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PublicReviewPage() when $default != null:
return $default(_that.summary,_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReviewSummary summary,  List<PublicReview> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _PublicReviewPage():
return $default(_that.summary,_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReviewSummary summary,  List<PublicReview> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _PublicReviewPage() when $default != null:
return $default(_that.summary,_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PublicReviewPage implements PublicReviewPage {
  const _PublicReviewPage({required this.summary, required final  List<PublicReview> items, required this.nextCursor}): _items = items;
  factory _PublicReviewPage.fromJson(Map<String, dynamic> json) => _$PublicReviewPageFromJson(json);

@override final  ReviewSummary summary;
 final  List<PublicReview> _items;
@override List<PublicReview> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of PublicReviewPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicReviewPageCopyWith<_PublicReviewPage> get copyWith => __$PublicReviewPageCopyWithImpl<_PublicReviewPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicReviewPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicReviewPage&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'PublicReviewPage(summary: $summary, items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$PublicReviewPageCopyWith<$Res> implements $PublicReviewPageCopyWith<$Res> {
  factory _$PublicReviewPageCopyWith(_PublicReviewPage value, $Res Function(_PublicReviewPage) _then) = __$PublicReviewPageCopyWithImpl;
@override @useResult
$Res call({
 ReviewSummary summary, List<PublicReview> items, String? nextCursor
});


@override $ReviewSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$PublicReviewPageCopyWithImpl<$Res>
    implements _$PublicReviewPageCopyWith<$Res> {
  __$PublicReviewPageCopyWithImpl(this._self, this._then);

  final _PublicReviewPage _self;
  final $Res Function(_PublicReviewPage) _then;

/// Create a copy of PublicReviewPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_PublicReviewPage(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as ReviewSummary,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PublicReview>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PublicReviewPage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewSummaryCopyWith<$Res> get summary {
  
  return $ReviewSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
