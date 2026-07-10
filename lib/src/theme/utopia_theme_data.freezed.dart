// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'utopia_theme_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UtopiaThemeData {

/// The foundational token scale (base unit, spacing, radii) this theme
/// carries. Components resolve it through context - `context.theme.tokens`
/// or the `context.spacing` / `context.radius` shorthands - so nested
/// `UtopiaTheme`s can swap or rescale the whole system per subtree.
 UtopiaTokens get tokens; UtopiaThemeColors get colors; UtopiaThemeTextStyles get textStyles;/// Corner radius of interactive controls (fields, buttons, tiles) -
/// which radius step controls sit on is a theme decision, so this is a
/// slot rather than a fixed token alias.
 BorderRadius get borderRadius; EdgeInsets get fieldContentPadding;/// Minimum height of the content area inside a field's chrome (the
/// `UtopiaFieldWrapper` floor). Total resting field height is this plus
/// the vertical [fieldContentPadding].
 double get fieldMinHeight;/// Vertical padding above page-level content (and the sidebar rail).
 double get pageTopPadding;/// Corner radius of card surfaces (the table card, dialogs).
 BorderRadius get cardRadius;/// Height of a single table row.
 double get tileHeight;
/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaThemeDataCopyWith<UtopiaThemeData> get copyWith => _$UtopiaThemeDataCopyWithImpl<UtopiaThemeData>(this as UtopiaThemeData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaThemeData&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.colors, colors) || other.colors == colors)&&(identical(other.textStyles, textStyles) || other.textStyles == textStyles)&&(identical(other.borderRadius, borderRadius) || other.borderRadius == borderRadius)&&(identical(other.fieldContentPadding, fieldContentPadding) || other.fieldContentPadding == fieldContentPadding)&&(identical(other.fieldMinHeight, fieldMinHeight) || other.fieldMinHeight == fieldMinHeight)&&(identical(other.pageTopPadding, pageTopPadding) || other.pageTopPadding == pageTopPadding)&&(identical(other.cardRadius, cardRadius) || other.cardRadius == cardRadius)&&(identical(other.tileHeight, tileHeight) || other.tileHeight == tileHeight));
}


@override
int get hashCode => Object.hash(runtimeType,tokens,colors,textStyles,borderRadius,fieldContentPadding,fieldMinHeight,pageTopPadding,cardRadius,tileHeight);

@override
String toString() {
  return 'UtopiaThemeData(tokens: $tokens, colors: $colors, textStyles: $textStyles, borderRadius: $borderRadius, fieldContentPadding: $fieldContentPadding, fieldMinHeight: $fieldMinHeight, pageTopPadding: $pageTopPadding, cardRadius: $cardRadius, tileHeight: $tileHeight)';
}


}

/// @nodoc
abstract mixin class $UtopiaThemeDataCopyWith<$Res>  {
  factory $UtopiaThemeDataCopyWith(UtopiaThemeData value, $Res Function(UtopiaThemeData) _then) = _$UtopiaThemeDataCopyWithImpl;
@useResult
$Res call({
 UtopiaTokens tokens, UtopiaThemeColors colors, UtopiaThemeTextStyles textStyles, BorderRadius borderRadius, EdgeInsets fieldContentPadding, double fieldMinHeight, double pageTopPadding, BorderRadius cardRadius, double tileHeight
});


$UtopiaTokensCopyWith<$Res> get tokens;$UtopiaThemeColorsCopyWith<$Res> get colors;$UtopiaThemeTextStylesCopyWith<$Res> get textStyles;

}
/// @nodoc
class _$UtopiaThemeDataCopyWithImpl<$Res>
    implements $UtopiaThemeDataCopyWith<$Res> {
  _$UtopiaThemeDataCopyWithImpl(this._self, this._then);

  final UtopiaThemeData _self;
  final $Res Function(UtopiaThemeData) _then;

/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tokens = null,Object? colors = null,Object? textStyles = null,Object? borderRadius = null,Object? fieldContentPadding = null,Object? fieldMinHeight = null,Object? pageTopPadding = null,Object? cardRadius = null,Object? tileHeight = null,}) {
  return _then(_self.copyWith(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as UtopiaTokens,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as UtopiaThemeColors,textStyles: null == textStyles ? _self.textStyles : textStyles // ignore: cast_nullable_to_non_nullable
as UtopiaThemeTextStyles,borderRadius: null == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as BorderRadius,fieldContentPadding: null == fieldContentPadding ? _self.fieldContentPadding : fieldContentPadding // ignore: cast_nullable_to_non_nullable
as EdgeInsets,fieldMinHeight: null == fieldMinHeight ? _self.fieldMinHeight : fieldMinHeight // ignore: cast_nullable_to_non_nullable
as double,pageTopPadding: null == pageTopPadding ? _self.pageTopPadding : pageTopPadding // ignore: cast_nullable_to_non_nullable
as double,cardRadius: null == cardRadius ? _self.cardRadius : cardRadius // ignore: cast_nullable_to_non_nullable
as BorderRadius,tileHeight: null == tileHeight ? _self.tileHeight : tileHeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaTokensCopyWith<$Res> get tokens {
  
  return $UtopiaTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaThemeColorsCopyWith<$Res> get colors {
  
  return $UtopiaThemeColorsCopyWith<$Res>(_self.colors, (value) {
    return _then(_self.copyWith(colors: value));
  });
}/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaThemeTextStylesCopyWith<$Res> get textStyles {
  
  return $UtopiaThemeTextStylesCopyWith<$Res>(_self.textStyles, (value) {
    return _then(_self.copyWith(textStyles: value));
  });
}
}


/// Adds pattern-matching-related methods to [UtopiaThemeData].
extension UtopiaThemeDataPatterns on UtopiaThemeData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaThemeData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaThemeData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaThemeData value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaThemeData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaThemeData value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaThemeData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UtopiaTokens tokens,  UtopiaThemeColors colors,  UtopiaThemeTextStyles textStyles,  BorderRadius borderRadius,  EdgeInsets fieldContentPadding,  double fieldMinHeight,  double pageTopPadding,  BorderRadius cardRadius,  double tileHeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaThemeData() when $default != null:
return $default(_that.tokens,_that.colors,_that.textStyles,_that.borderRadius,_that.fieldContentPadding,_that.fieldMinHeight,_that.pageTopPadding,_that.cardRadius,_that.tileHeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UtopiaTokens tokens,  UtopiaThemeColors colors,  UtopiaThemeTextStyles textStyles,  BorderRadius borderRadius,  EdgeInsets fieldContentPadding,  double fieldMinHeight,  double pageTopPadding,  BorderRadius cardRadius,  double tileHeight)  $default,) {final _that = this;
switch (_that) {
case _UtopiaThemeData():
return $default(_that.tokens,_that.colors,_that.textStyles,_that.borderRadius,_that.fieldContentPadding,_that.fieldMinHeight,_that.pageTopPadding,_that.cardRadius,_that.tileHeight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UtopiaTokens tokens,  UtopiaThemeColors colors,  UtopiaThemeTextStyles textStyles,  BorderRadius borderRadius,  EdgeInsets fieldContentPadding,  double fieldMinHeight,  double pageTopPadding,  BorderRadius cardRadius,  double tileHeight)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaThemeData() when $default != null:
return $default(_that.tokens,_that.colors,_that.textStyles,_that.borderRadius,_that.fieldContentPadding,_that.fieldMinHeight,_that.pageTopPadding,_that.cardRadius,_that.tileHeight);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaThemeData extends UtopiaThemeData {
  const _UtopiaThemeData({this.tokens = const UtopiaTokens(), required this.colors, required this.textStyles, required this.borderRadius, required this.fieldContentPadding, this.fieldMinHeight = 44.0, required this.pageTopPadding, this.cardRadius = const BorderRadius.all(Radius.circular(16)), this.tileHeight = 58.0}): super._();
  

/// The foundational token scale (base unit, spacing, radii) this theme
/// carries. Components resolve it through context - `context.theme.tokens`
/// or the `context.spacing` / `context.radius` shorthands - so nested
/// `UtopiaTheme`s can swap or rescale the whole system per subtree.
@override@JsonKey() final  UtopiaTokens tokens;
@override final  UtopiaThemeColors colors;
@override final  UtopiaThemeTextStyles textStyles;
/// Corner radius of interactive controls (fields, buttons, tiles) -
/// which radius step controls sit on is a theme decision, so this is a
/// slot rather than a fixed token alias.
@override final  BorderRadius borderRadius;
@override final  EdgeInsets fieldContentPadding;
/// Minimum height of the content area inside a field's chrome (the
/// `UtopiaFieldWrapper` floor). Total resting field height is this plus
/// the vertical [fieldContentPadding].
@override@JsonKey() final  double fieldMinHeight;
/// Vertical padding above page-level content (and the sidebar rail).
@override final  double pageTopPadding;
/// Corner radius of card surfaces (the table card, dialogs).
@override@JsonKey() final  BorderRadius cardRadius;
/// Height of a single table row.
@override@JsonKey() final  double tileHeight;

/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaThemeDataCopyWith<_UtopiaThemeData> get copyWith => __$UtopiaThemeDataCopyWithImpl<_UtopiaThemeData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaThemeData&&(identical(other.tokens, tokens) || other.tokens == tokens)&&(identical(other.colors, colors) || other.colors == colors)&&(identical(other.textStyles, textStyles) || other.textStyles == textStyles)&&(identical(other.borderRadius, borderRadius) || other.borderRadius == borderRadius)&&(identical(other.fieldContentPadding, fieldContentPadding) || other.fieldContentPadding == fieldContentPadding)&&(identical(other.fieldMinHeight, fieldMinHeight) || other.fieldMinHeight == fieldMinHeight)&&(identical(other.pageTopPadding, pageTopPadding) || other.pageTopPadding == pageTopPadding)&&(identical(other.cardRadius, cardRadius) || other.cardRadius == cardRadius)&&(identical(other.tileHeight, tileHeight) || other.tileHeight == tileHeight));
}


@override
int get hashCode => Object.hash(runtimeType,tokens,colors,textStyles,borderRadius,fieldContentPadding,fieldMinHeight,pageTopPadding,cardRadius,tileHeight);

@override
String toString() {
  return 'UtopiaThemeData(tokens: $tokens, colors: $colors, textStyles: $textStyles, borderRadius: $borderRadius, fieldContentPadding: $fieldContentPadding, fieldMinHeight: $fieldMinHeight, pageTopPadding: $pageTopPadding, cardRadius: $cardRadius, tileHeight: $tileHeight)';
}


}

/// @nodoc
abstract mixin class _$UtopiaThemeDataCopyWith<$Res> implements $UtopiaThemeDataCopyWith<$Res> {
  factory _$UtopiaThemeDataCopyWith(_UtopiaThemeData value, $Res Function(_UtopiaThemeData) _then) = __$UtopiaThemeDataCopyWithImpl;
@override @useResult
$Res call({
 UtopiaTokens tokens, UtopiaThemeColors colors, UtopiaThemeTextStyles textStyles, BorderRadius borderRadius, EdgeInsets fieldContentPadding, double fieldMinHeight, double pageTopPadding, BorderRadius cardRadius, double tileHeight
});


@override $UtopiaTokensCopyWith<$Res> get tokens;@override $UtopiaThemeColorsCopyWith<$Res> get colors;@override $UtopiaThemeTextStylesCopyWith<$Res> get textStyles;

}
/// @nodoc
class __$UtopiaThemeDataCopyWithImpl<$Res>
    implements _$UtopiaThemeDataCopyWith<$Res> {
  __$UtopiaThemeDataCopyWithImpl(this._self, this._then);

  final _UtopiaThemeData _self;
  final $Res Function(_UtopiaThemeData) _then;

/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tokens = null,Object? colors = null,Object? textStyles = null,Object? borderRadius = null,Object? fieldContentPadding = null,Object? fieldMinHeight = null,Object? pageTopPadding = null,Object? cardRadius = null,Object? tileHeight = null,}) {
  return _then(_UtopiaThemeData(
tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as UtopiaTokens,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as UtopiaThemeColors,textStyles: null == textStyles ? _self.textStyles : textStyles // ignore: cast_nullable_to_non_nullable
as UtopiaThemeTextStyles,borderRadius: null == borderRadius ? _self.borderRadius : borderRadius // ignore: cast_nullable_to_non_nullable
as BorderRadius,fieldContentPadding: null == fieldContentPadding ? _self.fieldContentPadding : fieldContentPadding // ignore: cast_nullable_to_non_nullable
as EdgeInsets,fieldMinHeight: null == fieldMinHeight ? _self.fieldMinHeight : fieldMinHeight // ignore: cast_nullable_to_non_nullable
as double,pageTopPadding: null == pageTopPadding ? _self.pageTopPadding : pageTopPadding // ignore: cast_nullable_to_non_nullable
as double,cardRadius: null == cardRadius ? _self.cardRadius : cardRadius // ignore: cast_nullable_to_non_nullable
as BorderRadius,tileHeight: null == tileHeight ? _self.tileHeight : tileHeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaTokensCopyWith<$Res> get tokens {
  
  return $UtopiaTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaThemeColorsCopyWith<$Res> get colors {
  
  return $UtopiaThemeColorsCopyWith<$Res>(_self.colors, (value) {
    return _then(_self.copyWith(colors: value));
  });
}/// Create a copy of UtopiaThemeData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaThemeTextStylesCopyWith<$Res> get textStyles {
  
  return $UtopiaThemeTextStylesCopyWith<$Res>(_self.textStyles, (value) {
    return _then(_self.copyWith(textStyles: value));
  });
}
}

// dart format on
