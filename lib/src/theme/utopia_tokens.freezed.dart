// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'utopia_tokens.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UtopiaTokens {

/// The base unit of the design system. Every spacing and radius token is
/// a multiple of this value. For a one-off multiple outside the named
/// scale, derive it explicitly (`tokens.x * 5`) so it rescales with the
/// system.
 double get x;/// Spacing scale - gaps, margins and padding.
 UtopiaSpacingTokens get spacing;/// Corner-radius scale.
 UtopiaRadiusTokens get radius;/// Stroke-width scale for borders and dividers.
 UtopiaBorderTokens get borders;/// Elevation (box-shadow) presets.
 UtopiaShadowTokens get shadows;/// Font-weight steps.
 UtopiaFontWeightTokens get fontWeights;/// Motion-timing scale.
 UtopiaDurationTokens get durations;/// Responsive layout thresholds.
 UtopiaBreakpointTokens get breakpoints;
/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaTokensCopyWith<UtopiaTokens> get copyWith => _$UtopiaTokensCopyWithImpl<UtopiaTokens>(this as UtopiaTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaTokens&&(identical(other.x, x) || other.x == x)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.radius, radius) || other.radius == radius)&&(identical(other.borders, borders) || other.borders == borders)&&(identical(other.shadows, shadows) || other.shadows == shadows)&&(identical(other.fontWeights, fontWeights) || other.fontWeights == fontWeights)&&(identical(other.durations, durations) || other.durations == durations)&&(identical(other.breakpoints, breakpoints) || other.breakpoints == breakpoints));
}


@override
int get hashCode => Object.hash(runtimeType,x,spacing,radius,borders,shadows,fontWeights,durations,breakpoints);

@override
String toString() {
  return 'UtopiaTokens(x: $x, spacing: $spacing, radius: $radius, borders: $borders, shadows: $shadows, fontWeights: $fontWeights, durations: $durations, breakpoints: $breakpoints)';
}


}

/// @nodoc
abstract mixin class $UtopiaTokensCopyWith<$Res>  {
  factory $UtopiaTokensCopyWith(UtopiaTokens value, $Res Function(UtopiaTokens) _then) = _$UtopiaTokensCopyWithImpl;
@useResult
$Res call({
 double x, UtopiaSpacingTokens spacing, UtopiaRadiusTokens radius, UtopiaBorderTokens borders, UtopiaShadowTokens shadows, UtopiaFontWeightTokens fontWeights, UtopiaDurationTokens durations, UtopiaBreakpointTokens breakpoints
});


$UtopiaSpacingTokensCopyWith<$Res> get spacing;$UtopiaRadiusTokensCopyWith<$Res> get radius;$UtopiaBorderTokensCopyWith<$Res> get borders;$UtopiaShadowTokensCopyWith<$Res> get shadows;$UtopiaFontWeightTokensCopyWith<$Res> get fontWeights;$UtopiaDurationTokensCopyWith<$Res> get durations;$UtopiaBreakpointTokensCopyWith<$Res> get breakpoints;

}
/// @nodoc
class _$UtopiaTokensCopyWithImpl<$Res>
    implements $UtopiaTokensCopyWith<$Res> {
  _$UtopiaTokensCopyWithImpl(this._self, this._then);

  final UtopiaTokens _self;
  final $Res Function(UtopiaTokens) _then;

/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? spacing = null,Object? radius = null,Object? borders = null,Object? shadows = null,Object? fontWeights = null,Object? durations = null,Object? breakpoints = null,}) {
  return _then(_self.copyWith(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as UtopiaSpacingTokens,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as UtopiaRadiusTokens,borders: null == borders ? _self.borders : borders // ignore: cast_nullable_to_non_nullable
as UtopiaBorderTokens,shadows: null == shadows ? _self.shadows : shadows // ignore: cast_nullable_to_non_nullable
as UtopiaShadowTokens,fontWeights: null == fontWeights ? _self.fontWeights : fontWeights // ignore: cast_nullable_to_non_nullable
as UtopiaFontWeightTokens,durations: null == durations ? _self.durations : durations // ignore: cast_nullable_to_non_nullable
as UtopiaDurationTokens,breakpoints: null == breakpoints ? _self.breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as UtopiaBreakpointTokens,
  ));
}
/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaSpacingTokensCopyWith<$Res> get spacing {
  
  return $UtopiaSpacingTokensCopyWith<$Res>(_self.spacing, (value) {
    return _then(_self.copyWith(spacing: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaRadiusTokensCopyWith<$Res> get radius {
  
  return $UtopiaRadiusTokensCopyWith<$Res>(_self.radius, (value) {
    return _then(_self.copyWith(radius: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaBorderTokensCopyWith<$Res> get borders {
  
  return $UtopiaBorderTokensCopyWith<$Res>(_self.borders, (value) {
    return _then(_self.copyWith(borders: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaShadowTokensCopyWith<$Res> get shadows {
  
  return $UtopiaShadowTokensCopyWith<$Res>(_self.shadows, (value) {
    return _then(_self.copyWith(shadows: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaFontWeightTokensCopyWith<$Res> get fontWeights {
  
  return $UtopiaFontWeightTokensCopyWith<$Res>(_self.fontWeights, (value) {
    return _then(_self.copyWith(fontWeights: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaDurationTokensCopyWith<$Res> get durations {
  
  return $UtopiaDurationTokensCopyWith<$Res>(_self.durations, (value) {
    return _then(_self.copyWith(durations: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaBreakpointTokensCopyWith<$Res> get breakpoints {
  
  return $UtopiaBreakpointTokensCopyWith<$Res>(_self.breakpoints, (value) {
    return _then(_self.copyWith(breakpoints: value));
  });
}
}


/// Adds pattern-matching-related methods to [UtopiaTokens].
extension UtopiaTokensPatterns on UtopiaTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double x,  UtopiaSpacingTokens spacing,  UtopiaRadiusTokens radius,  UtopiaBorderTokens borders,  UtopiaShadowTokens shadows,  UtopiaFontWeightTokens fontWeights,  UtopiaDurationTokens durations,  UtopiaBreakpointTokens breakpoints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaTokens() when $default != null:
return $default(_that.x,_that.spacing,_that.radius,_that.borders,_that.shadows,_that.fontWeights,_that.durations,_that.breakpoints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double x,  UtopiaSpacingTokens spacing,  UtopiaRadiusTokens radius,  UtopiaBorderTokens borders,  UtopiaShadowTokens shadows,  UtopiaFontWeightTokens fontWeights,  UtopiaDurationTokens durations,  UtopiaBreakpointTokens breakpoints)  $default,) {final _that = this;
switch (_that) {
case _UtopiaTokens():
return $default(_that.x,_that.spacing,_that.radius,_that.borders,_that.shadows,_that.fontWeights,_that.durations,_that.breakpoints);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double x,  UtopiaSpacingTokens spacing,  UtopiaRadiusTokens radius,  UtopiaBorderTokens borders,  UtopiaShadowTokens shadows,  UtopiaFontWeightTokens fontWeights,  UtopiaDurationTokens durations,  UtopiaBreakpointTokens breakpoints)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaTokens() when $default != null:
return $default(_that.x,_that.spacing,_that.radius,_that.borders,_that.shadows,_that.fontWeights,_that.durations,_that.breakpoints);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaTokens extends UtopiaTokens {
  const _UtopiaTokens({this.x = _x, this.spacing = const UtopiaSpacingTokens(), this.radius = const UtopiaRadiusTokens(), this.borders = const UtopiaBorderTokens(), this.shadows = const UtopiaShadowTokens(), this.fontWeights = const UtopiaFontWeightTokens(), this.durations = const UtopiaDurationTokens(), this.breakpoints = const UtopiaBreakpointTokens()}): super._();
  

/// The base unit of the design system. Every spacing and radius token is
/// a multiple of this value. For a one-off multiple outside the named
/// scale, derive it explicitly (`tokens.x * 5`) so it rescales with the
/// system.
@override@JsonKey() final  double x;
/// Spacing scale - gaps, margins and padding.
@override@JsonKey() final  UtopiaSpacingTokens spacing;
/// Corner-radius scale.
@override@JsonKey() final  UtopiaRadiusTokens radius;
/// Stroke-width scale for borders and dividers.
@override@JsonKey() final  UtopiaBorderTokens borders;
/// Elevation (box-shadow) presets.
@override@JsonKey() final  UtopiaShadowTokens shadows;
/// Font-weight steps.
@override@JsonKey() final  UtopiaFontWeightTokens fontWeights;
/// Motion-timing scale.
@override@JsonKey() final  UtopiaDurationTokens durations;
/// Responsive layout thresholds.
@override@JsonKey() final  UtopiaBreakpointTokens breakpoints;

/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaTokensCopyWith<_UtopiaTokens> get copyWith => __$UtopiaTokensCopyWithImpl<_UtopiaTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaTokens&&(identical(other.x, x) || other.x == x)&&(identical(other.spacing, spacing) || other.spacing == spacing)&&(identical(other.radius, radius) || other.radius == radius)&&(identical(other.borders, borders) || other.borders == borders)&&(identical(other.shadows, shadows) || other.shadows == shadows)&&(identical(other.fontWeights, fontWeights) || other.fontWeights == fontWeights)&&(identical(other.durations, durations) || other.durations == durations)&&(identical(other.breakpoints, breakpoints) || other.breakpoints == breakpoints));
}


@override
int get hashCode => Object.hash(runtimeType,x,spacing,radius,borders,shadows,fontWeights,durations,breakpoints);

@override
String toString() {
  return 'UtopiaTokens(x: $x, spacing: $spacing, radius: $radius, borders: $borders, shadows: $shadows, fontWeights: $fontWeights, durations: $durations, breakpoints: $breakpoints)';
}


}

/// @nodoc
abstract mixin class _$UtopiaTokensCopyWith<$Res> implements $UtopiaTokensCopyWith<$Res> {
  factory _$UtopiaTokensCopyWith(_UtopiaTokens value, $Res Function(_UtopiaTokens) _then) = __$UtopiaTokensCopyWithImpl;
@override @useResult
$Res call({
 double x, UtopiaSpacingTokens spacing, UtopiaRadiusTokens radius, UtopiaBorderTokens borders, UtopiaShadowTokens shadows, UtopiaFontWeightTokens fontWeights, UtopiaDurationTokens durations, UtopiaBreakpointTokens breakpoints
});


@override $UtopiaSpacingTokensCopyWith<$Res> get spacing;@override $UtopiaRadiusTokensCopyWith<$Res> get radius;@override $UtopiaBorderTokensCopyWith<$Res> get borders;@override $UtopiaShadowTokensCopyWith<$Res> get shadows;@override $UtopiaFontWeightTokensCopyWith<$Res> get fontWeights;@override $UtopiaDurationTokensCopyWith<$Res> get durations;@override $UtopiaBreakpointTokensCopyWith<$Res> get breakpoints;

}
/// @nodoc
class __$UtopiaTokensCopyWithImpl<$Res>
    implements _$UtopiaTokensCopyWith<$Res> {
  __$UtopiaTokensCopyWithImpl(this._self, this._then);

  final _UtopiaTokens _self;
  final $Res Function(_UtopiaTokens) _then;

/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? x = null,Object? spacing = null,Object? radius = null,Object? borders = null,Object? shadows = null,Object? fontWeights = null,Object? durations = null,Object? breakpoints = null,}) {
  return _then(_UtopiaTokens(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,spacing: null == spacing ? _self.spacing : spacing // ignore: cast_nullable_to_non_nullable
as UtopiaSpacingTokens,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as UtopiaRadiusTokens,borders: null == borders ? _self.borders : borders // ignore: cast_nullable_to_non_nullable
as UtopiaBorderTokens,shadows: null == shadows ? _self.shadows : shadows // ignore: cast_nullable_to_non_nullable
as UtopiaShadowTokens,fontWeights: null == fontWeights ? _self.fontWeights : fontWeights // ignore: cast_nullable_to_non_nullable
as UtopiaFontWeightTokens,durations: null == durations ? _self.durations : durations // ignore: cast_nullable_to_non_nullable
as UtopiaDurationTokens,breakpoints: null == breakpoints ? _self.breakpoints : breakpoints // ignore: cast_nullable_to_non_nullable
as UtopiaBreakpointTokens,
  ));
}

/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaSpacingTokensCopyWith<$Res> get spacing {
  
  return $UtopiaSpacingTokensCopyWith<$Res>(_self.spacing, (value) {
    return _then(_self.copyWith(spacing: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaRadiusTokensCopyWith<$Res> get radius {
  
  return $UtopiaRadiusTokensCopyWith<$Res>(_self.radius, (value) {
    return _then(_self.copyWith(radius: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaBorderTokensCopyWith<$Res> get borders {
  
  return $UtopiaBorderTokensCopyWith<$Res>(_self.borders, (value) {
    return _then(_self.copyWith(borders: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaShadowTokensCopyWith<$Res> get shadows {
  
  return $UtopiaShadowTokensCopyWith<$Res>(_self.shadows, (value) {
    return _then(_self.copyWith(shadows: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaFontWeightTokensCopyWith<$Res> get fontWeights {
  
  return $UtopiaFontWeightTokensCopyWith<$Res>(_self.fontWeights, (value) {
    return _then(_self.copyWith(fontWeights: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaDurationTokensCopyWith<$Res> get durations {
  
  return $UtopiaDurationTokensCopyWith<$Res>(_self.durations, (value) {
    return _then(_self.copyWith(durations: value));
  });
}/// Create a copy of UtopiaTokens
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UtopiaBreakpointTokensCopyWith<$Res> get breakpoints {
  
  return $UtopiaBreakpointTokensCopyWith<$Res>(_self.breakpoints, (value) {
    return _then(_self.copyWith(breakpoints: value));
  });
}
}

/// @nodoc
mixin _$UtopiaSpacingTokens {

/// 0.5x = 2. Hairline gaps, icon-to-text nudges.
 double get xxs;/// 1x = 4. Tight gaps inside compact controls.
 double get xs;/// 2x = 8. Default gap between related elements.
 double get sm;/// 3x = 12. Gap between loosely related elements.
 double get md;/// 4x = 16. Standard content padding.
 double get lg;/// 6x = 24. Section padding, dialog insets.
 double get xl;/// 8x = 32. Gap between distinct content blocks.
 double get xxl;/// 12x = 48. Page-level padding.
 double get xxxl;
/// Create a copy of UtopiaSpacingTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaSpacingTokensCopyWith<UtopiaSpacingTokens> get copyWith => _$UtopiaSpacingTokensCopyWithImpl<UtopiaSpacingTokens>(this as UtopiaSpacingTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaSpacingTokens&&(identical(other.xxs, xxs) || other.xxs == xxs)&&(identical(other.xs, xs) || other.xs == xs)&&(identical(other.sm, sm) || other.sm == sm)&&(identical(other.md, md) || other.md == md)&&(identical(other.lg, lg) || other.lg == lg)&&(identical(other.xl, xl) || other.xl == xl)&&(identical(other.xxl, xxl) || other.xxl == xxl)&&(identical(other.xxxl, xxxl) || other.xxxl == xxxl));
}


@override
int get hashCode => Object.hash(runtimeType,xxs,xs,sm,md,lg,xl,xxl,xxxl);

@override
String toString() {
  return 'UtopiaSpacingTokens(xxs: $xxs, xs: $xs, sm: $sm, md: $md, lg: $lg, xl: $xl, xxl: $xxl, xxxl: $xxxl)';
}


}

/// @nodoc
abstract mixin class $UtopiaSpacingTokensCopyWith<$Res>  {
  factory $UtopiaSpacingTokensCopyWith(UtopiaSpacingTokens value, $Res Function(UtopiaSpacingTokens) _then) = _$UtopiaSpacingTokensCopyWithImpl;
@useResult
$Res call({
 double xxs, double xs, double sm, double md, double lg, double xl, double xxl, double xxxl
});




}
/// @nodoc
class _$UtopiaSpacingTokensCopyWithImpl<$Res>
    implements $UtopiaSpacingTokensCopyWith<$Res> {
  _$UtopiaSpacingTokensCopyWithImpl(this._self, this._then);

  final UtopiaSpacingTokens _self;
  final $Res Function(UtopiaSpacingTokens) _then;

/// Create a copy of UtopiaSpacingTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xxs = null,Object? xs = null,Object? sm = null,Object? md = null,Object? lg = null,Object? xl = null,Object? xxl = null,Object? xxxl = null,}) {
  return _then(_self.copyWith(
xxs: null == xxs ? _self.xxs : xxs // ignore: cast_nullable_to_non_nullable
as double,xs: null == xs ? _self.xs : xs // ignore: cast_nullable_to_non_nullable
as double,sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as double,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as double,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as double,xl: null == xl ? _self.xl : xl // ignore: cast_nullable_to_non_nullable
as double,xxl: null == xxl ? _self.xxl : xxl // ignore: cast_nullable_to_non_nullable
as double,xxxl: null == xxxl ? _self.xxxl : xxxl // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaSpacingTokens].
extension UtopiaSpacingTokensPatterns on UtopiaSpacingTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaSpacingTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaSpacingTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaSpacingTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaSpacingTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaSpacingTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaSpacingTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double xxs,  double xs,  double sm,  double md,  double lg,  double xl,  double xxl,  double xxxl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaSpacingTokens() when $default != null:
return $default(_that.xxs,_that.xs,_that.sm,_that.md,_that.lg,_that.xl,_that.xxl,_that.xxxl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double xxs,  double xs,  double sm,  double md,  double lg,  double xl,  double xxl,  double xxxl)  $default,) {final _that = this;
switch (_that) {
case _UtopiaSpacingTokens():
return $default(_that.xxs,_that.xs,_that.sm,_that.md,_that.lg,_that.xl,_that.xxl,_that.xxxl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double xxs,  double xs,  double sm,  double md,  double lg,  double xl,  double xxl,  double xxxl)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaSpacingTokens() when $default != null:
return $default(_that.xxs,_that.xs,_that.sm,_that.md,_that.lg,_that.xl,_that.xxl,_that.xxxl);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaSpacingTokens implements UtopiaSpacingTokens {
  const _UtopiaSpacingTokens({this.xxs = _x * 0.5, this.xs = _x, this.sm = _x * 2, this.md = _x * 3, this.lg = _x * 4, this.xl = _x * 6, this.xxl = _x * 8, this.xxxl = _x * 12});
  

/// 0.5x = 2. Hairline gaps, icon-to-text nudges.
@override@JsonKey() final  double xxs;
/// 1x = 4. Tight gaps inside compact controls.
@override@JsonKey() final  double xs;
/// 2x = 8. Default gap between related elements.
@override@JsonKey() final  double sm;
/// 3x = 12. Gap between loosely related elements.
@override@JsonKey() final  double md;
/// 4x = 16. Standard content padding.
@override@JsonKey() final  double lg;
/// 6x = 24. Section padding, dialog insets.
@override@JsonKey() final  double xl;
/// 8x = 32. Gap between distinct content blocks.
@override@JsonKey() final  double xxl;
/// 12x = 48. Page-level padding.
@override@JsonKey() final  double xxxl;

/// Create a copy of UtopiaSpacingTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaSpacingTokensCopyWith<_UtopiaSpacingTokens> get copyWith => __$UtopiaSpacingTokensCopyWithImpl<_UtopiaSpacingTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaSpacingTokens&&(identical(other.xxs, xxs) || other.xxs == xxs)&&(identical(other.xs, xs) || other.xs == xs)&&(identical(other.sm, sm) || other.sm == sm)&&(identical(other.md, md) || other.md == md)&&(identical(other.lg, lg) || other.lg == lg)&&(identical(other.xl, xl) || other.xl == xl)&&(identical(other.xxl, xxl) || other.xxl == xxl)&&(identical(other.xxxl, xxxl) || other.xxxl == xxxl));
}


@override
int get hashCode => Object.hash(runtimeType,xxs,xs,sm,md,lg,xl,xxl,xxxl);

@override
String toString() {
  return 'UtopiaSpacingTokens(xxs: $xxs, xs: $xs, sm: $sm, md: $md, lg: $lg, xl: $xl, xxl: $xxl, xxxl: $xxxl)';
}


}

/// @nodoc
abstract mixin class _$UtopiaSpacingTokensCopyWith<$Res> implements $UtopiaSpacingTokensCopyWith<$Res> {
  factory _$UtopiaSpacingTokensCopyWith(_UtopiaSpacingTokens value, $Res Function(_UtopiaSpacingTokens) _then) = __$UtopiaSpacingTokensCopyWithImpl;
@override @useResult
$Res call({
 double xxs, double xs, double sm, double md, double lg, double xl, double xxl, double xxxl
});




}
/// @nodoc
class __$UtopiaSpacingTokensCopyWithImpl<$Res>
    implements _$UtopiaSpacingTokensCopyWith<$Res> {
  __$UtopiaSpacingTokensCopyWithImpl(this._self, this._then);

  final _UtopiaSpacingTokens _self;
  final $Res Function(_UtopiaSpacingTokens) _then;

/// Create a copy of UtopiaSpacingTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xxs = null,Object? xs = null,Object? sm = null,Object? md = null,Object? lg = null,Object? xl = null,Object? xxl = null,Object? xxxl = null,}) {
  return _then(_UtopiaSpacingTokens(
xxs: null == xxs ? _self.xxs : xxs // ignore: cast_nullable_to_non_nullable
as double,xs: null == xs ? _self.xs : xs // ignore: cast_nullable_to_non_nullable
as double,sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as double,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as double,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as double,xl: null == xl ? _self.xl : xl // ignore: cast_nullable_to_non_nullable
as double,xxl: null == xxl ? _self.xxl : xxl // ignore: cast_nullable_to_non_nullable
as double,xxxl: null == xxxl ? _self.xxxl : xxxl // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$UtopiaRadiusTokens {

/// 1x = 4. Smallest rounding - tags, thumbnails.
 double get xs;/// 1.5x = 6. Badges and chips - the tier below controls.
 double get sm;/// 2x = 8. Interactive controls: fields, buttons, sidebar tiles.
 double get md;/// 3x = 12. Menus, popovers.
 double get lg;/// 4x = 16. Cards and other large surfaces.
 double get xl;/// Effectively-infinite radius for pill / circular shapes.
 double get full;
/// Create a copy of UtopiaRadiusTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaRadiusTokensCopyWith<UtopiaRadiusTokens> get copyWith => _$UtopiaRadiusTokensCopyWithImpl<UtopiaRadiusTokens>(this as UtopiaRadiusTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaRadiusTokens&&(identical(other.xs, xs) || other.xs == xs)&&(identical(other.sm, sm) || other.sm == sm)&&(identical(other.md, md) || other.md == md)&&(identical(other.lg, lg) || other.lg == lg)&&(identical(other.xl, xl) || other.xl == xl)&&(identical(other.full, full) || other.full == full));
}


@override
int get hashCode => Object.hash(runtimeType,xs,sm,md,lg,xl,full);

@override
String toString() {
  return 'UtopiaRadiusTokens(xs: $xs, sm: $sm, md: $md, lg: $lg, xl: $xl, full: $full)';
}


}

/// @nodoc
abstract mixin class $UtopiaRadiusTokensCopyWith<$Res>  {
  factory $UtopiaRadiusTokensCopyWith(UtopiaRadiusTokens value, $Res Function(UtopiaRadiusTokens) _then) = _$UtopiaRadiusTokensCopyWithImpl;
@useResult
$Res call({
 double xs, double sm, double md, double lg, double xl, double full
});




}
/// @nodoc
class _$UtopiaRadiusTokensCopyWithImpl<$Res>
    implements $UtopiaRadiusTokensCopyWith<$Res> {
  _$UtopiaRadiusTokensCopyWithImpl(this._self, this._then);

  final UtopiaRadiusTokens _self;
  final $Res Function(UtopiaRadiusTokens) _then;

/// Create a copy of UtopiaRadiusTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xs = null,Object? sm = null,Object? md = null,Object? lg = null,Object? xl = null,Object? full = null,}) {
  return _then(_self.copyWith(
xs: null == xs ? _self.xs : xs // ignore: cast_nullable_to_non_nullable
as double,sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as double,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as double,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as double,xl: null == xl ? _self.xl : xl // ignore: cast_nullable_to_non_nullable
as double,full: null == full ? _self.full : full // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaRadiusTokens].
extension UtopiaRadiusTokensPatterns on UtopiaRadiusTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaRadiusTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaRadiusTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaRadiusTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaRadiusTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaRadiusTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaRadiusTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double xs,  double sm,  double md,  double lg,  double xl,  double full)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaRadiusTokens() when $default != null:
return $default(_that.xs,_that.sm,_that.md,_that.lg,_that.xl,_that.full);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double xs,  double sm,  double md,  double lg,  double xl,  double full)  $default,) {final _that = this;
switch (_that) {
case _UtopiaRadiusTokens():
return $default(_that.xs,_that.sm,_that.md,_that.lg,_that.xl,_that.full);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double xs,  double sm,  double md,  double lg,  double xl,  double full)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaRadiusTokens() when $default != null:
return $default(_that.xs,_that.sm,_that.md,_that.lg,_that.xl,_that.full);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaRadiusTokens extends UtopiaRadiusTokens {
  const _UtopiaRadiusTokens({this.xs = _x, this.sm = _x * 1.5, this.md = _x * 2, this.lg = _x * 3, this.xl = _x * 4, this.full = 9999.0}): super._();
  

/// 1x = 4. Smallest rounding - tags, thumbnails.
@override@JsonKey() final  double xs;
/// 1.5x = 6. Badges and chips - the tier below controls.
@override@JsonKey() final  double sm;
/// 2x = 8. Interactive controls: fields, buttons, sidebar tiles.
@override@JsonKey() final  double md;
/// 3x = 12. Menus, popovers.
@override@JsonKey() final  double lg;
/// 4x = 16. Cards and other large surfaces.
@override@JsonKey() final  double xl;
/// Effectively-infinite radius for pill / circular shapes.
@override@JsonKey() final  double full;

/// Create a copy of UtopiaRadiusTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaRadiusTokensCopyWith<_UtopiaRadiusTokens> get copyWith => __$UtopiaRadiusTokensCopyWithImpl<_UtopiaRadiusTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaRadiusTokens&&(identical(other.xs, xs) || other.xs == xs)&&(identical(other.sm, sm) || other.sm == sm)&&(identical(other.md, md) || other.md == md)&&(identical(other.lg, lg) || other.lg == lg)&&(identical(other.xl, xl) || other.xl == xl)&&(identical(other.full, full) || other.full == full));
}


@override
int get hashCode => Object.hash(runtimeType,xs,sm,md,lg,xl,full);

@override
String toString() {
  return 'UtopiaRadiusTokens(xs: $xs, sm: $sm, md: $md, lg: $lg, xl: $xl, full: $full)';
}


}

/// @nodoc
abstract mixin class _$UtopiaRadiusTokensCopyWith<$Res> implements $UtopiaRadiusTokensCopyWith<$Res> {
  factory _$UtopiaRadiusTokensCopyWith(_UtopiaRadiusTokens value, $Res Function(_UtopiaRadiusTokens) _then) = __$UtopiaRadiusTokensCopyWithImpl;
@override @useResult
$Res call({
 double xs, double sm, double md, double lg, double xl, double full
});




}
/// @nodoc
class __$UtopiaRadiusTokensCopyWithImpl<$Res>
    implements _$UtopiaRadiusTokensCopyWith<$Res> {
  __$UtopiaRadiusTokensCopyWithImpl(this._self, this._then);

  final _UtopiaRadiusTokens _self;
  final $Res Function(_UtopiaRadiusTokens) _then;

/// Create a copy of UtopiaRadiusTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xs = null,Object? sm = null,Object? md = null,Object? lg = null,Object? xl = null,Object? full = null,}) {
  return _then(_UtopiaRadiusTokens(
xs: null == xs ? _self.xs : xs // ignore: cast_nullable_to_non_nullable
as double,sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as double,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as double,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as double,xl: null == xl ? _self.xl : xl // ignore: cast_nullable_to_non_nullable
as double,full: null == full ? _self.full : full // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$UtopiaBorderTokens {

/// 1.0. Row / header dividers, subtle separators.
 double get hairline;/// 1.5. Card and field outlines.
 double get thin;/// 2.0. Emphasised / focus outlines.
 double get thick;
/// Create a copy of UtopiaBorderTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaBorderTokensCopyWith<UtopiaBorderTokens> get copyWith => _$UtopiaBorderTokensCopyWithImpl<UtopiaBorderTokens>(this as UtopiaBorderTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaBorderTokens&&(identical(other.hairline, hairline) || other.hairline == hairline)&&(identical(other.thin, thin) || other.thin == thin)&&(identical(other.thick, thick) || other.thick == thick));
}


@override
int get hashCode => Object.hash(runtimeType,hairline,thin,thick);

@override
String toString() {
  return 'UtopiaBorderTokens(hairline: $hairline, thin: $thin, thick: $thick)';
}


}

/// @nodoc
abstract mixin class $UtopiaBorderTokensCopyWith<$Res>  {
  factory $UtopiaBorderTokensCopyWith(UtopiaBorderTokens value, $Res Function(UtopiaBorderTokens) _then) = _$UtopiaBorderTokensCopyWithImpl;
@useResult
$Res call({
 double hairline, double thin, double thick
});




}
/// @nodoc
class _$UtopiaBorderTokensCopyWithImpl<$Res>
    implements $UtopiaBorderTokensCopyWith<$Res> {
  _$UtopiaBorderTokensCopyWithImpl(this._self, this._then);

  final UtopiaBorderTokens _self;
  final $Res Function(UtopiaBorderTokens) _then;

/// Create a copy of UtopiaBorderTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hairline = null,Object? thin = null,Object? thick = null,}) {
  return _then(_self.copyWith(
hairline: null == hairline ? _self.hairline : hairline // ignore: cast_nullable_to_non_nullable
as double,thin: null == thin ? _self.thin : thin // ignore: cast_nullable_to_non_nullable
as double,thick: null == thick ? _self.thick : thick // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaBorderTokens].
extension UtopiaBorderTokensPatterns on UtopiaBorderTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaBorderTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaBorderTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaBorderTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaBorderTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaBorderTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaBorderTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double hairline,  double thin,  double thick)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaBorderTokens() when $default != null:
return $default(_that.hairline,_that.thin,_that.thick);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double hairline,  double thin,  double thick)  $default,) {final _that = this;
switch (_that) {
case _UtopiaBorderTokens():
return $default(_that.hairline,_that.thin,_that.thick);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double hairline,  double thin,  double thick)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaBorderTokens() when $default != null:
return $default(_that.hairline,_that.thin,_that.thick);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaBorderTokens implements UtopiaBorderTokens {
  const _UtopiaBorderTokens({this.hairline = 1.0, this.thin = 1.5, this.thick = 2.0});
  

/// 1.0. Row / header dividers, subtle separators.
@override@JsonKey() final  double hairline;
/// 1.5. Card and field outlines.
@override@JsonKey() final  double thin;
/// 2.0. Emphasised / focus outlines.
@override@JsonKey() final  double thick;

/// Create a copy of UtopiaBorderTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaBorderTokensCopyWith<_UtopiaBorderTokens> get copyWith => __$UtopiaBorderTokensCopyWithImpl<_UtopiaBorderTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaBorderTokens&&(identical(other.hairline, hairline) || other.hairline == hairline)&&(identical(other.thin, thin) || other.thin == thin)&&(identical(other.thick, thick) || other.thick == thick));
}


@override
int get hashCode => Object.hash(runtimeType,hairline,thin,thick);

@override
String toString() {
  return 'UtopiaBorderTokens(hairline: $hairline, thin: $thin, thick: $thick)';
}


}

/// @nodoc
abstract mixin class _$UtopiaBorderTokensCopyWith<$Res> implements $UtopiaBorderTokensCopyWith<$Res> {
  factory _$UtopiaBorderTokensCopyWith(_UtopiaBorderTokens value, $Res Function(_UtopiaBorderTokens) _then) = __$UtopiaBorderTokensCopyWithImpl;
@override @useResult
$Res call({
 double hairline, double thin, double thick
});




}
/// @nodoc
class __$UtopiaBorderTokensCopyWithImpl<$Res>
    implements _$UtopiaBorderTokensCopyWith<$Res> {
  __$UtopiaBorderTokensCopyWithImpl(this._self, this._then);

  final _UtopiaBorderTokens _self;
  final $Res Function(_UtopiaBorderTokens) _then;

/// Create a copy of UtopiaBorderTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hairline = null,Object? thin = null,Object? thick = null,}) {
  return _then(_UtopiaBorderTokens(
hairline: null == hairline ? _self.hairline : hairline // ignore: cast_nullable_to_non_nullable
as double,thin: null == thin ? _self.thin : thin // ignore: cast_nullable_to_non_nullable
as double,thick: null == thick ? _self.thick : thick // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$UtopiaShadowTokens {

/// Subtle lift for resting surfaces (cards).
 List<BoxShadow> get sm;/// Intermediate lift for hovering / dragged elements.
 List<BoxShadow> get md;/// Strong lift for floating overlays (menus, popovers).
 List<BoxShadow> get lg;
/// Create a copy of UtopiaShadowTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaShadowTokensCopyWith<UtopiaShadowTokens> get copyWith => _$UtopiaShadowTokensCopyWithImpl<UtopiaShadowTokens>(this as UtopiaShadowTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaShadowTokens&&const DeepCollectionEquality().equals(other.sm, sm)&&const DeepCollectionEquality().equals(other.md, md)&&const DeepCollectionEquality().equals(other.lg, lg));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(sm),const DeepCollectionEquality().hash(md),const DeepCollectionEquality().hash(lg));

@override
String toString() {
  return 'UtopiaShadowTokens(sm: $sm, md: $md, lg: $lg)';
}


}

/// @nodoc
abstract mixin class $UtopiaShadowTokensCopyWith<$Res>  {
  factory $UtopiaShadowTokensCopyWith(UtopiaShadowTokens value, $Res Function(UtopiaShadowTokens) _then) = _$UtopiaShadowTokensCopyWithImpl;
@useResult
$Res call({
 List<BoxShadow> sm, List<BoxShadow> md, List<BoxShadow> lg
});




}
/// @nodoc
class _$UtopiaShadowTokensCopyWithImpl<$Res>
    implements $UtopiaShadowTokensCopyWith<$Res> {
  _$UtopiaShadowTokensCopyWithImpl(this._self, this._then);

  final UtopiaShadowTokens _self;
  final $Res Function(UtopiaShadowTokens) _then;

/// Create a copy of UtopiaShadowTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sm = null,Object? md = null,Object? lg = null,}) {
  return _then(_self.copyWith(
sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as List<BoxShadow>,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as List<BoxShadow>,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as List<BoxShadow>,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaShadowTokens].
extension UtopiaShadowTokensPatterns on UtopiaShadowTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaShadowTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaShadowTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaShadowTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaShadowTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaShadowTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaShadowTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BoxShadow> sm,  List<BoxShadow> md,  List<BoxShadow> lg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaShadowTokens() when $default != null:
return $default(_that.sm,_that.md,_that.lg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BoxShadow> sm,  List<BoxShadow> md,  List<BoxShadow> lg)  $default,) {final _that = this;
switch (_that) {
case _UtopiaShadowTokens():
return $default(_that.sm,_that.md,_that.lg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BoxShadow> sm,  List<BoxShadow> md,  List<BoxShadow> lg)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaShadowTokens() when $default != null:
return $default(_that.sm,_that.md,_that.lg);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaShadowTokens implements UtopiaShadowTokens {
  const _UtopiaShadowTokens({final  List<BoxShadow> sm = const <BoxShadow>[BoxShadow(color: Color(0x0F101828), offset: Offset(0, 1), blurRadius: 2), BoxShadow(color: Color(0x0D101828), offset: Offset(0, 4), blurRadius: 10, spreadRadius: -2)], final  List<BoxShadow> md = const <BoxShadow>[BoxShadow(color: Color(0x0F101828), spreadRadius: 1), BoxShadow(color: Color(0x12101828), offset: Offset(0, 2), blurRadius: 4, spreadRadius: -1), BoxShadow(color: Color(0x14101828), offset: Offset(0, 8), blurRadius: 16, spreadRadius: -4)], final  List<BoxShadow> lg = const <BoxShadow>[BoxShadow(color: Color(0x0F101828), spreadRadius: 1), BoxShadow(color: Color(0x0F101828), offset: Offset(0, 4), blurRadius: 8, spreadRadius: -2), BoxShadow(color: Color(0x24101828), offset: Offset(0, 16), blurRadius: 32, spreadRadius: -8)]}): _sm = sm,_md = md,_lg = lg;
  

/// Subtle lift for resting surfaces (cards).
 final  List<BoxShadow> _sm;
/// Subtle lift for resting surfaces (cards).
@override@JsonKey() List<BoxShadow> get sm {
  if (_sm is EqualUnmodifiableListView) return _sm;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sm);
}

/// Intermediate lift for hovering / dragged elements.
 final  List<BoxShadow> _md;
/// Intermediate lift for hovering / dragged elements.
@override@JsonKey() List<BoxShadow> get md {
  if (_md is EqualUnmodifiableListView) return _md;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_md);
}

/// Strong lift for floating overlays (menus, popovers).
 final  List<BoxShadow> _lg;
/// Strong lift for floating overlays (menus, popovers).
@override@JsonKey() List<BoxShadow> get lg {
  if (_lg is EqualUnmodifiableListView) return _lg;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lg);
}


/// Create a copy of UtopiaShadowTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaShadowTokensCopyWith<_UtopiaShadowTokens> get copyWith => __$UtopiaShadowTokensCopyWithImpl<_UtopiaShadowTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaShadowTokens&&const DeepCollectionEquality().equals(other._sm, _sm)&&const DeepCollectionEquality().equals(other._md, _md)&&const DeepCollectionEquality().equals(other._lg, _lg));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_sm),const DeepCollectionEquality().hash(_md),const DeepCollectionEquality().hash(_lg));

@override
String toString() {
  return 'UtopiaShadowTokens(sm: $sm, md: $md, lg: $lg)';
}


}

/// @nodoc
abstract mixin class _$UtopiaShadowTokensCopyWith<$Res> implements $UtopiaShadowTokensCopyWith<$Res> {
  factory _$UtopiaShadowTokensCopyWith(_UtopiaShadowTokens value, $Res Function(_UtopiaShadowTokens) _then) = __$UtopiaShadowTokensCopyWithImpl;
@override @useResult
$Res call({
 List<BoxShadow> sm, List<BoxShadow> md, List<BoxShadow> lg
});




}
/// @nodoc
class __$UtopiaShadowTokensCopyWithImpl<$Res>
    implements _$UtopiaShadowTokensCopyWith<$Res> {
  __$UtopiaShadowTokensCopyWithImpl(this._self, this._then);

  final _UtopiaShadowTokens _self;
  final $Res Function(_UtopiaShadowTokens) _then;

/// Create a copy of UtopiaShadowTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sm = null,Object? md = null,Object? lg = null,}) {
  return _then(_UtopiaShadowTokens(
sm: null == sm ? _self._sm : sm // ignore: cast_nullable_to_non_nullable
as List<BoxShadow>,md: null == md ? _self._md : md // ignore: cast_nullable_to_non_nullable
as List<BoxShadow>,lg: null == lg ? _self._lg : lg // ignore: cast_nullable_to_non_nullable
as List<BoxShadow>,
  ));
}


}

/// @nodoc
mixin _$UtopiaFontWeightTokens {

/// Body copy.
 FontWeight get regular;/// Slight emphasis - secondary labels.
 FontWeight get medium;/// Primary emphasis - the system's default display weight.
 FontWeight get semiBold;/// Strong emphasis.
 FontWeight get bold;
/// Create a copy of UtopiaFontWeightTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaFontWeightTokensCopyWith<UtopiaFontWeightTokens> get copyWith => _$UtopiaFontWeightTokensCopyWithImpl<UtopiaFontWeightTokens>(this as UtopiaFontWeightTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaFontWeightTokens&&(identical(other.regular, regular) || other.regular == regular)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.semiBold, semiBold) || other.semiBold == semiBold)&&(identical(other.bold, bold) || other.bold == bold));
}


@override
int get hashCode => Object.hash(runtimeType,regular,medium,semiBold,bold);

@override
String toString() {
  return 'UtopiaFontWeightTokens(regular: $regular, medium: $medium, semiBold: $semiBold, bold: $bold)';
}


}

/// @nodoc
abstract mixin class $UtopiaFontWeightTokensCopyWith<$Res>  {
  factory $UtopiaFontWeightTokensCopyWith(UtopiaFontWeightTokens value, $Res Function(UtopiaFontWeightTokens) _then) = _$UtopiaFontWeightTokensCopyWithImpl;
@useResult
$Res call({
 FontWeight regular, FontWeight medium, FontWeight semiBold, FontWeight bold
});




}
/// @nodoc
class _$UtopiaFontWeightTokensCopyWithImpl<$Res>
    implements $UtopiaFontWeightTokensCopyWith<$Res> {
  _$UtopiaFontWeightTokensCopyWithImpl(this._self, this._then);

  final UtopiaFontWeightTokens _self;
  final $Res Function(UtopiaFontWeightTokens) _then;

/// Create a copy of UtopiaFontWeightTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? regular = null,Object? medium = null,Object? semiBold = null,Object? bold = null,}) {
  return _then(_self.copyWith(
regular: null == regular ? _self.regular : regular // ignore: cast_nullable_to_non_nullable
as FontWeight,medium: null == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as FontWeight,semiBold: null == semiBold ? _self.semiBold : semiBold // ignore: cast_nullable_to_non_nullable
as FontWeight,bold: null == bold ? _self.bold : bold // ignore: cast_nullable_to_non_nullable
as FontWeight,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaFontWeightTokens].
extension UtopiaFontWeightTokensPatterns on UtopiaFontWeightTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaFontWeightTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaFontWeightTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaFontWeightTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaFontWeightTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaFontWeightTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaFontWeightTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FontWeight regular,  FontWeight medium,  FontWeight semiBold,  FontWeight bold)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaFontWeightTokens() when $default != null:
return $default(_that.regular,_that.medium,_that.semiBold,_that.bold);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FontWeight regular,  FontWeight medium,  FontWeight semiBold,  FontWeight bold)  $default,) {final _that = this;
switch (_that) {
case _UtopiaFontWeightTokens():
return $default(_that.regular,_that.medium,_that.semiBold,_that.bold);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FontWeight regular,  FontWeight medium,  FontWeight semiBold,  FontWeight bold)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaFontWeightTokens() when $default != null:
return $default(_that.regular,_that.medium,_that.semiBold,_that.bold);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaFontWeightTokens implements UtopiaFontWeightTokens {
  const _UtopiaFontWeightTokens({this.regular = FontWeight.w400, this.medium = FontWeight.w500, this.semiBold = FontWeight.w600, this.bold = FontWeight.w700});
  

/// Body copy.
@override@JsonKey() final  FontWeight regular;
/// Slight emphasis - secondary labels.
@override@JsonKey() final  FontWeight medium;
/// Primary emphasis - the system's default display weight.
@override@JsonKey() final  FontWeight semiBold;
/// Strong emphasis.
@override@JsonKey() final  FontWeight bold;

/// Create a copy of UtopiaFontWeightTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaFontWeightTokensCopyWith<_UtopiaFontWeightTokens> get copyWith => __$UtopiaFontWeightTokensCopyWithImpl<_UtopiaFontWeightTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaFontWeightTokens&&(identical(other.regular, regular) || other.regular == regular)&&(identical(other.medium, medium) || other.medium == medium)&&(identical(other.semiBold, semiBold) || other.semiBold == semiBold)&&(identical(other.bold, bold) || other.bold == bold));
}


@override
int get hashCode => Object.hash(runtimeType,regular,medium,semiBold,bold);

@override
String toString() {
  return 'UtopiaFontWeightTokens(regular: $regular, medium: $medium, semiBold: $semiBold, bold: $bold)';
}


}

/// @nodoc
abstract mixin class _$UtopiaFontWeightTokensCopyWith<$Res> implements $UtopiaFontWeightTokensCopyWith<$Res> {
  factory _$UtopiaFontWeightTokensCopyWith(_UtopiaFontWeightTokens value, $Res Function(_UtopiaFontWeightTokens) _then) = __$UtopiaFontWeightTokensCopyWithImpl;
@override @useResult
$Res call({
 FontWeight regular, FontWeight medium, FontWeight semiBold, FontWeight bold
});




}
/// @nodoc
class __$UtopiaFontWeightTokensCopyWithImpl<$Res>
    implements _$UtopiaFontWeightTokensCopyWith<$Res> {
  __$UtopiaFontWeightTokensCopyWithImpl(this._self, this._then);

  final _UtopiaFontWeightTokens _self;
  final $Res Function(_UtopiaFontWeightTokens) _then;

/// Create a copy of UtopiaFontWeightTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? regular = null,Object? medium = null,Object? semiBold = null,Object? bold = null,}) {
  return _then(_UtopiaFontWeightTokens(
regular: null == regular ? _self.regular : regular // ignore: cast_nullable_to_non_nullable
as FontWeight,medium: null == medium ? _self.medium : medium // ignore: cast_nullable_to_non_nullable
as FontWeight,semiBold: null == semiBold ? _self.semiBold : semiBold // ignore: cast_nullable_to_non_nullable
as FontWeight,bold: null == bold ? _self.bold : bold // ignore: cast_nullable_to_non_nullable
as FontWeight,
  ));
}


}

/// @nodoc
mixin _$UtopiaDurationTokens {

/// 100ms. Instant feedback - hovers, presses.
 Duration get xs;/// 150ms. Small state changes - toggles, checkmarks.
 Duration get sm;/// 200ms. Standard transitions - fades, colour shifts.
 Duration get md;/// 300ms. Structural motion - expand / collapse, reflow.
 Duration get lg;/// 400ms. Large movements - panels, drawers.
 Duration get xl;
/// Create a copy of UtopiaDurationTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaDurationTokensCopyWith<UtopiaDurationTokens> get copyWith => _$UtopiaDurationTokensCopyWithImpl<UtopiaDurationTokens>(this as UtopiaDurationTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaDurationTokens&&(identical(other.xs, xs) || other.xs == xs)&&(identical(other.sm, sm) || other.sm == sm)&&(identical(other.md, md) || other.md == md)&&(identical(other.lg, lg) || other.lg == lg)&&(identical(other.xl, xl) || other.xl == xl));
}


@override
int get hashCode => Object.hash(runtimeType,xs,sm,md,lg,xl);

@override
String toString() {
  return 'UtopiaDurationTokens(xs: $xs, sm: $sm, md: $md, lg: $lg, xl: $xl)';
}


}

/// @nodoc
abstract mixin class $UtopiaDurationTokensCopyWith<$Res>  {
  factory $UtopiaDurationTokensCopyWith(UtopiaDurationTokens value, $Res Function(UtopiaDurationTokens) _then) = _$UtopiaDurationTokensCopyWithImpl;
@useResult
$Res call({
 Duration xs, Duration sm, Duration md, Duration lg, Duration xl
});




}
/// @nodoc
class _$UtopiaDurationTokensCopyWithImpl<$Res>
    implements $UtopiaDurationTokensCopyWith<$Res> {
  _$UtopiaDurationTokensCopyWithImpl(this._self, this._then);

  final UtopiaDurationTokens _self;
  final $Res Function(UtopiaDurationTokens) _then;

/// Create a copy of UtopiaDurationTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xs = null,Object? sm = null,Object? md = null,Object? lg = null,Object? xl = null,}) {
  return _then(_self.copyWith(
xs: null == xs ? _self.xs : xs // ignore: cast_nullable_to_non_nullable
as Duration,sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as Duration,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as Duration,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as Duration,xl: null == xl ? _self.xl : xl // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaDurationTokens].
extension UtopiaDurationTokensPatterns on UtopiaDurationTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaDurationTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaDurationTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaDurationTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaDurationTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaDurationTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaDurationTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration xs,  Duration sm,  Duration md,  Duration lg,  Duration xl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaDurationTokens() when $default != null:
return $default(_that.xs,_that.sm,_that.md,_that.lg,_that.xl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration xs,  Duration sm,  Duration md,  Duration lg,  Duration xl)  $default,) {final _that = this;
switch (_that) {
case _UtopiaDurationTokens():
return $default(_that.xs,_that.sm,_that.md,_that.lg,_that.xl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration xs,  Duration sm,  Duration md,  Duration lg,  Duration xl)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaDurationTokens() when $default != null:
return $default(_that.xs,_that.sm,_that.md,_that.lg,_that.xl);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaDurationTokens implements UtopiaDurationTokens {
  const _UtopiaDurationTokens({this.xs = const Duration(milliseconds: 100), this.sm = const Duration(milliseconds: 150), this.md = const Duration(milliseconds: 200), this.lg = const Duration(milliseconds: 300), this.xl = const Duration(milliseconds: 400)});
  

/// 100ms. Instant feedback - hovers, presses.
@override@JsonKey() final  Duration xs;
/// 150ms. Small state changes - toggles, checkmarks.
@override@JsonKey() final  Duration sm;
/// 200ms. Standard transitions - fades, colour shifts.
@override@JsonKey() final  Duration md;
/// 300ms. Structural motion - expand / collapse, reflow.
@override@JsonKey() final  Duration lg;
/// 400ms. Large movements - panels, drawers.
@override@JsonKey() final  Duration xl;

/// Create a copy of UtopiaDurationTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaDurationTokensCopyWith<_UtopiaDurationTokens> get copyWith => __$UtopiaDurationTokensCopyWithImpl<_UtopiaDurationTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaDurationTokens&&(identical(other.xs, xs) || other.xs == xs)&&(identical(other.sm, sm) || other.sm == sm)&&(identical(other.md, md) || other.md == md)&&(identical(other.lg, lg) || other.lg == lg)&&(identical(other.xl, xl) || other.xl == xl));
}


@override
int get hashCode => Object.hash(runtimeType,xs,sm,md,lg,xl);

@override
String toString() {
  return 'UtopiaDurationTokens(xs: $xs, sm: $sm, md: $md, lg: $lg, xl: $xl)';
}


}

/// @nodoc
abstract mixin class _$UtopiaDurationTokensCopyWith<$Res> implements $UtopiaDurationTokensCopyWith<$Res> {
  factory _$UtopiaDurationTokensCopyWith(_UtopiaDurationTokens value, $Res Function(_UtopiaDurationTokens) _then) = __$UtopiaDurationTokensCopyWithImpl;
@override @useResult
$Res call({
 Duration xs, Duration sm, Duration md, Duration lg, Duration xl
});




}
/// @nodoc
class __$UtopiaDurationTokensCopyWithImpl<$Res>
    implements _$UtopiaDurationTokensCopyWith<$Res> {
  __$UtopiaDurationTokensCopyWithImpl(this._self, this._then);

  final _UtopiaDurationTokens _self;
  final $Res Function(_UtopiaDurationTokens) _then;

/// Create a copy of UtopiaDurationTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xs = null,Object? sm = null,Object? md = null,Object? lg = null,Object? xl = null,}) {
  return _then(_UtopiaDurationTokens(
xs: null == xs ? _self.xs : xs // ignore: cast_nullable_to_non_nullable
as Duration,sm: null == sm ? _self.sm : sm // ignore: cast_nullable_to_non_nullable
as Duration,md: null == md ? _self.md : md // ignore: cast_nullable_to_non_nullable
as Duration,lg: null == lg ? _self.lg : lg // ignore: cast_nullable_to_non_nullable
as Duration,xl: null == xl ? _self.xl : xl // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$UtopiaBreakpointTokens {

/// At or above this *content* width the layout is at least tablet-class.
 double get tabletMin;/// At or above this *content* width the layout is web-class.
 double get webMin;/// At or above this *window* width the shell shows the sidebar as a rail;
/// below it the sidebar hides behind a drawer.
 double get sidebarMin;
/// Create a copy of UtopiaBreakpointTokens
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaBreakpointTokensCopyWith<UtopiaBreakpointTokens> get copyWith => _$UtopiaBreakpointTokensCopyWithImpl<UtopiaBreakpointTokens>(this as UtopiaBreakpointTokens, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaBreakpointTokens&&(identical(other.tabletMin, tabletMin) || other.tabletMin == tabletMin)&&(identical(other.webMin, webMin) || other.webMin == webMin)&&(identical(other.sidebarMin, sidebarMin) || other.sidebarMin == sidebarMin));
}


@override
int get hashCode => Object.hash(runtimeType,tabletMin,webMin,sidebarMin);

@override
String toString() {
  return 'UtopiaBreakpointTokens(tabletMin: $tabletMin, webMin: $webMin, sidebarMin: $sidebarMin)';
}


}

/// @nodoc
abstract mixin class $UtopiaBreakpointTokensCopyWith<$Res>  {
  factory $UtopiaBreakpointTokensCopyWith(UtopiaBreakpointTokens value, $Res Function(UtopiaBreakpointTokens) _then) = _$UtopiaBreakpointTokensCopyWithImpl;
@useResult
$Res call({
 double tabletMin, double webMin, double sidebarMin
});




}
/// @nodoc
class _$UtopiaBreakpointTokensCopyWithImpl<$Res>
    implements $UtopiaBreakpointTokensCopyWith<$Res> {
  _$UtopiaBreakpointTokensCopyWithImpl(this._self, this._then);

  final UtopiaBreakpointTokens _self;
  final $Res Function(UtopiaBreakpointTokens) _then;

/// Create a copy of UtopiaBreakpointTokens
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tabletMin = null,Object? webMin = null,Object? sidebarMin = null,}) {
  return _then(_self.copyWith(
tabletMin: null == tabletMin ? _self.tabletMin : tabletMin // ignore: cast_nullable_to_non_nullable
as double,webMin: null == webMin ? _self.webMin : webMin // ignore: cast_nullable_to_non_nullable
as double,sidebarMin: null == sidebarMin ? _self.sidebarMin : sidebarMin // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaBreakpointTokens].
extension UtopiaBreakpointTokensPatterns on UtopiaBreakpointTokens {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaBreakpointTokens value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaBreakpointTokens() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaBreakpointTokens value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaBreakpointTokens():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaBreakpointTokens value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaBreakpointTokens() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double tabletMin,  double webMin,  double sidebarMin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaBreakpointTokens() when $default != null:
return $default(_that.tabletMin,_that.webMin,_that.sidebarMin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double tabletMin,  double webMin,  double sidebarMin)  $default,) {final _that = this;
switch (_that) {
case _UtopiaBreakpointTokens():
return $default(_that.tabletMin,_that.webMin,_that.sidebarMin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double tabletMin,  double webMin,  double sidebarMin)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaBreakpointTokens() when $default != null:
return $default(_that.tabletMin,_that.webMin,_that.sidebarMin);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaBreakpointTokens implements UtopiaBreakpointTokens {
  const _UtopiaBreakpointTokens({this.tabletMin = 600.0, this.webMin = 900.0, this.sidebarMin = 1000.0});
  

/// At or above this *content* width the layout is at least tablet-class.
@override@JsonKey() final  double tabletMin;
/// At or above this *content* width the layout is web-class.
@override@JsonKey() final  double webMin;
/// At or above this *window* width the shell shows the sidebar as a rail;
/// below it the sidebar hides behind a drawer.
@override@JsonKey() final  double sidebarMin;

/// Create a copy of UtopiaBreakpointTokens
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaBreakpointTokensCopyWith<_UtopiaBreakpointTokens> get copyWith => __$UtopiaBreakpointTokensCopyWithImpl<_UtopiaBreakpointTokens>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaBreakpointTokens&&(identical(other.tabletMin, tabletMin) || other.tabletMin == tabletMin)&&(identical(other.webMin, webMin) || other.webMin == webMin)&&(identical(other.sidebarMin, sidebarMin) || other.sidebarMin == sidebarMin));
}


@override
int get hashCode => Object.hash(runtimeType,tabletMin,webMin,sidebarMin);

@override
String toString() {
  return 'UtopiaBreakpointTokens(tabletMin: $tabletMin, webMin: $webMin, sidebarMin: $sidebarMin)';
}


}

/// @nodoc
abstract mixin class _$UtopiaBreakpointTokensCopyWith<$Res> implements $UtopiaBreakpointTokensCopyWith<$Res> {
  factory _$UtopiaBreakpointTokensCopyWith(_UtopiaBreakpointTokens value, $Res Function(_UtopiaBreakpointTokens) _then) = __$UtopiaBreakpointTokensCopyWithImpl;
@override @useResult
$Res call({
 double tabletMin, double webMin, double sidebarMin
});




}
/// @nodoc
class __$UtopiaBreakpointTokensCopyWithImpl<$Res>
    implements _$UtopiaBreakpointTokensCopyWith<$Res> {
  __$UtopiaBreakpointTokensCopyWithImpl(this._self, this._then);

  final _UtopiaBreakpointTokens _self;
  final $Res Function(_UtopiaBreakpointTokens) _then;

/// Create a copy of UtopiaBreakpointTokens
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tabletMin = null,Object? webMin = null,Object? sidebarMin = null,}) {
  return _then(_UtopiaBreakpointTokens(
tabletMin: null == tabletMin ? _self.tabletMin : tabletMin // ignore: cast_nullable_to_non_nullable
as double,webMin: null == webMin ? _self.webMin : webMin // ignore: cast_nullable_to_non_nullable
as double,sidebarMin: null == sidebarMin ? _self.sidebarMin : sidebarMin // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
