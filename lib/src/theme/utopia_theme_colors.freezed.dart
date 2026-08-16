// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'utopia_theme_colors.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UtopiaThemeColors {

 Color get primary; Color get accent;/// Content (text / icon) colour of anything painted on the
/// [primary] -> [accent] sweep - the filled button label above all.
/// Must clear 4.5:1 against *both* ends of that sweep, since a gradient
/// gives the label no single background to be checked against.
 Color get onPrimary; Color get field; Color get canvas; Color get error; Color get disabled;/// The heading tone: the strongest foreground in the system, carried by
/// the `header` and `title` type styles.
 Color get text;/// The body tone - one step quieter than [text], carried by the `text`,
/// `label` and `caption` type styles. Sits between [text] and [hint] so
/// running copy recedes from headings without dropping to the muted tier.
 Color get textBody;/// Background of the table card and other raised surfaces.
 Color get surface;/// Hairline colour for the card border and the table header's bottom rule.
/// Sits one step darker than [divider] so a surface's outer edge always
/// reads stronger than the lines drawn inside it.
 Color get border;/// Colour of `UtopiaDivider` hairlines. `null` derives a contrast-safe
/// colour from [text] over [surface] at paint time, so dividers stay
/// visible in a hand-built theme (dark included) without being set
/// explicitly. The default light theme sets it explicitly, one step
/// lighter than [border].
 Color? get divider;/// Tint of alternating (odd) table rows.
 Color get rowAlt;/// Row background while hovered.
 Color get hover;/// Fill of a `UtopiaChip`.
 Color get chipBackground;/// Content (text / icon) colour of a `UtopiaChip`.
 Color get chipForeground;/// Muted colour for hints, placeholders and secondary text.
 Color get hint;/// Tint of every elevation shadow. `UtopiaShadowTokens` owns the geometry
/// of each preset (offset, blur, spread and per-layer alpha); this supplies
/// the hue, and its own alpha scales the whole stack (opaque = the preset's
/// alphas verbatim, half = half as heavy).
///
/// Light themes use the system's blue-black rather than pure black so
/// elevation stays in the neutrals' hue family. Dark themes should not try
/// to compensate by darkening further - a shadow cannot out-darken a dark
/// ground. There, separation is [border]'s job plus the
/// [canvas]/[surface]/[rowAlt]/[hover] ramp, and the shadow only adds a
/// faint halo.
 Color get shadow;/// Content (text / icon) colour used by components rendered on an
/// opt-in coloured / gradient background (e.g. `UtopiaSidebar`'s
/// `backgroundColors` mode).
 Color get onColoredContent;/// Selected-state overlay colour used by components rendered on an
/// opt-in coloured / gradient background (e.g. `UtopiaSidebar`'s
/// `backgroundColors` mode).
 Color get onColoredSelected;/// Hover-state overlay colour used by components rendered on an opt-in
/// coloured / gradient background (e.g. `UtopiaSidebar`'s
/// `backgroundColors` mode).
 Color get onColoredHover;
/// Create a copy of UtopiaThemeColors
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaThemeColorsCopyWith<UtopiaThemeColors> get copyWith => _$UtopiaThemeColorsCopyWithImpl<UtopiaThemeColors>(this as UtopiaThemeColors, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaThemeColors&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.onPrimary, onPrimary) || other.onPrimary == onPrimary)&&(identical(other.field, field) || other.field == field)&&(identical(other.canvas, canvas) || other.canvas == canvas)&&(identical(other.error, error) || other.error == error)&&(identical(other.disabled, disabled) || other.disabled == disabled)&&(identical(other.text, text) || other.text == text)&&(identical(other.textBody, textBody) || other.textBody == textBody)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.border, border) || other.border == border)&&(identical(other.divider, divider) || other.divider == divider)&&(identical(other.rowAlt, rowAlt) || other.rowAlt == rowAlt)&&(identical(other.hover, hover) || other.hover == hover)&&(identical(other.chipBackground, chipBackground) || other.chipBackground == chipBackground)&&(identical(other.chipForeground, chipForeground) || other.chipForeground == chipForeground)&&(identical(other.hint, hint) || other.hint == hint)&&(identical(other.shadow, shadow) || other.shadow == shadow)&&(identical(other.onColoredContent, onColoredContent) || other.onColoredContent == onColoredContent)&&(identical(other.onColoredSelected, onColoredSelected) || other.onColoredSelected == onColoredSelected)&&(identical(other.onColoredHover, onColoredHover) || other.onColoredHover == onColoredHover));
}


@override
int get hashCode => Object.hashAll([runtimeType,primary,accent,onPrimary,field,canvas,error,disabled,text,textBody,surface,border,divider,rowAlt,hover,chipBackground,chipForeground,hint,shadow,onColoredContent,onColoredSelected,onColoredHover]);

@override
String toString() {
  return 'UtopiaThemeColors(primary: $primary, accent: $accent, onPrimary: $onPrimary, field: $field, canvas: $canvas, error: $error, disabled: $disabled, text: $text, textBody: $textBody, surface: $surface, border: $border, divider: $divider, rowAlt: $rowAlt, hover: $hover, chipBackground: $chipBackground, chipForeground: $chipForeground, hint: $hint, shadow: $shadow, onColoredContent: $onColoredContent, onColoredSelected: $onColoredSelected, onColoredHover: $onColoredHover)';
}


}

/// @nodoc
abstract mixin class $UtopiaThemeColorsCopyWith<$Res>  {
  factory $UtopiaThemeColorsCopyWith(UtopiaThemeColors value, $Res Function(UtopiaThemeColors) _then) = _$UtopiaThemeColorsCopyWithImpl;
@useResult
$Res call({
 Color primary, Color accent, Color onPrimary, Color field, Color canvas, Color error, Color disabled, Color text, Color textBody, Color surface, Color border, Color? divider, Color rowAlt, Color hover, Color chipBackground, Color chipForeground, Color hint, Color shadow, Color onColoredContent, Color onColoredSelected, Color onColoredHover
});




}
/// @nodoc
class _$UtopiaThemeColorsCopyWithImpl<$Res>
    implements $UtopiaThemeColorsCopyWith<$Res> {
  _$UtopiaThemeColorsCopyWithImpl(this._self, this._then);

  final UtopiaThemeColors _self;
  final $Res Function(UtopiaThemeColors) _then;

/// Create a copy of UtopiaThemeColors
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? primary = null,Object? accent = null,Object? onPrimary = null,Object? field = null,Object? canvas = null,Object? error = null,Object? disabled = null,Object? text = null,Object? textBody = null,Object? surface = null,Object? border = null,Object? divider = freezed,Object? rowAlt = null,Object? hover = null,Object? chipBackground = null,Object? chipForeground = null,Object? hint = null,Object? shadow = null,Object? onColoredContent = null,Object? onColoredSelected = null,Object? onColoredHover = null,}) {
  return _then(_self.copyWith(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as Color,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as Color,onPrimary: null == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as Color,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as Color,canvas: null == canvas ? _self.canvas : canvas // ignore: cast_nullable_to_non_nullable
as Color,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Color,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as Color,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as Color,textBody: null == textBody ? _self.textBody : textBody // ignore: cast_nullable_to_non_nullable
as Color,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as Color,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as Color,divider: freezed == divider ? _self.divider : divider // ignore: cast_nullable_to_non_nullable
as Color?,rowAlt: null == rowAlt ? _self.rowAlt : rowAlt // ignore: cast_nullable_to_non_nullable
as Color,hover: null == hover ? _self.hover : hover // ignore: cast_nullable_to_non_nullable
as Color,chipBackground: null == chipBackground ? _self.chipBackground : chipBackground // ignore: cast_nullable_to_non_nullable
as Color,chipForeground: null == chipForeground ? _self.chipForeground : chipForeground // ignore: cast_nullable_to_non_nullable
as Color,hint: null == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as Color,shadow: null == shadow ? _self.shadow : shadow // ignore: cast_nullable_to_non_nullable
as Color,onColoredContent: null == onColoredContent ? _self.onColoredContent : onColoredContent // ignore: cast_nullable_to_non_nullable
as Color,onColoredSelected: null == onColoredSelected ? _self.onColoredSelected : onColoredSelected // ignore: cast_nullable_to_non_nullable
as Color,onColoredHover: null == onColoredHover ? _self.onColoredHover : onColoredHover // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaThemeColors].
extension UtopiaThemeColorsPatterns on UtopiaThemeColors {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaThemeColors value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaThemeColors() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaThemeColors value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaThemeColors():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaThemeColors value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaThemeColors() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Color primary,  Color accent,  Color onPrimary,  Color field,  Color canvas,  Color error,  Color disabled,  Color text,  Color textBody,  Color surface,  Color border,  Color? divider,  Color rowAlt,  Color hover,  Color chipBackground,  Color chipForeground,  Color hint,  Color shadow,  Color onColoredContent,  Color onColoredSelected,  Color onColoredHover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaThemeColors() when $default != null:
return $default(_that.primary,_that.accent,_that.onPrimary,_that.field,_that.canvas,_that.error,_that.disabled,_that.text,_that.textBody,_that.surface,_that.border,_that.divider,_that.rowAlt,_that.hover,_that.chipBackground,_that.chipForeground,_that.hint,_that.shadow,_that.onColoredContent,_that.onColoredSelected,_that.onColoredHover);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Color primary,  Color accent,  Color onPrimary,  Color field,  Color canvas,  Color error,  Color disabled,  Color text,  Color textBody,  Color surface,  Color border,  Color? divider,  Color rowAlt,  Color hover,  Color chipBackground,  Color chipForeground,  Color hint,  Color shadow,  Color onColoredContent,  Color onColoredSelected,  Color onColoredHover)  $default,) {final _that = this;
switch (_that) {
case _UtopiaThemeColors():
return $default(_that.primary,_that.accent,_that.onPrimary,_that.field,_that.canvas,_that.error,_that.disabled,_that.text,_that.textBody,_that.surface,_that.border,_that.divider,_that.rowAlt,_that.hover,_that.chipBackground,_that.chipForeground,_that.hint,_that.shadow,_that.onColoredContent,_that.onColoredSelected,_that.onColoredHover);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Color primary,  Color accent,  Color onPrimary,  Color field,  Color canvas,  Color error,  Color disabled,  Color text,  Color textBody,  Color surface,  Color border,  Color? divider,  Color rowAlt,  Color hover,  Color chipBackground,  Color chipForeground,  Color hint,  Color shadow,  Color onColoredContent,  Color onColoredSelected,  Color onColoredHover)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaThemeColors() when $default != null:
return $default(_that.primary,_that.accent,_that.onPrimary,_that.field,_that.canvas,_that.error,_that.disabled,_that.text,_that.textBody,_that.surface,_that.border,_that.divider,_that.rowAlt,_that.hover,_that.chipBackground,_that.chipForeground,_that.hint,_that.shadow,_that.onColoredContent,_that.onColoredSelected,_that.onColoredHover);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaThemeColors extends UtopiaThemeColors {
   _UtopiaThemeColors({required this.primary, required this.accent, this.onPrimary = const Color(0xFFFFFFFF), required this.field, required this.canvas, required this.error, required this.disabled, required this.text, this.textBody = const Color(0xFF5B6076), this.surface = const Color(0xFFFFFFFF), this.border = const Color(0xFFD8DCEB), this.divider, this.rowAlt = const Color(0xFFF6F7FC), this.hover = const Color(0xFFEDF0FA), this.chipBackground = const Color(0xFFE9EDFD), this.chipForeground = const Color(0xFF3A4BCC), this.hint = const Color(0xFF6E748B), this.shadow = const Color(0xFF101828), required this.onColoredContent, required this.onColoredSelected, required this.onColoredHover}): super._();
  

@override final  Color primary;
@override final  Color accent;
/// Content (text / icon) colour of anything painted on the
/// [primary] -> [accent] sweep - the filled button label above all.
/// Must clear 4.5:1 against *both* ends of that sweep, since a gradient
/// gives the label no single background to be checked against.
@override@JsonKey() final  Color onPrimary;
@override final  Color field;
@override final  Color canvas;
@override final  Color error;
@override final  Color disabled;
/// The heading tone: the strongest foreground in the system, carried by
/// the `header` and `title` type styles.
@override final  Color text;
/// The body tone - one step quieter than [text], carried by the `text`,
/// `label` and `caption` type styles. Sits between [text] and [hint] so
/// running copy recedes from headings without dropping to the muted tier.
@override@JsonKey() final  Color textBody;
/// Background of the table card and other raised surfaces.
@override@JsonKey() final  Color surface;
/// Hairline colour for the card border and the table header's bottom rule.
/// Sits one step darker than [divider] so a surface's outer edge always
/// reads stronger than the lines drawn inside it.
@override@JsonKey() final  Color border;
/// Colour of `UtopiaDivider` hairlines. `null` derives a contrast-safe
/// colour from [text] over [surface] at paint time, so dividers stay
/// visible in a hand-built theme (dark included) without being set
/// explicitly. The default light theme sets it explicitly, one step
/// lighter than [border].
@override final  Color? divider;
/// Tint of alternating (odd) table rows.
@override@JsonKey() final  Color rowAlt;
/// Row background while hovered.
@override@JsonKey() final  Color hover;
/// Fill of a `UtopiaChip`.
@override@JsonKey() final  Color chipBackground;
/// Content (text / icon) colour of a `UtopiaChip`.
@override@JsonKey() final  Color chipForeground;
/// Muted colour for hints, placeholders and secondary text.
@override@JsonKey() final  Color hint;
/// Tint of every elevation shadow. `UtopiaShadowTokens` owns the geometry
/// of each preset (offset, blur, spread and per-layer alpha); this supplies
/// the hue, and its own alpha scales the whole stack (opaque = the preset's
/// alphas verbatim, half = half as heavy).
///
/// Light themes use the system's blue-black rather than pure black so
/// elevation stays in the neutrals' hue family. Dark themes should not try
/// to compensate by darkening further - a shadow cannot out-darken a dark
/// ground. There, separation is [border]'s job plus the
/// [canvas]/[surface]/[rowAlt]/[hover] ramp, and the shadow only adds a
/// faint halo.
@override@JsonKey() final  Color shadow;
/// Content (text / icon) colour used by components rendered on an
/// opt-in coloured / gradient background (e.g. `UtopiaSidebar`'s
/// `backgroundColors` mode).
@override final  Color onColoredContent;
/// Selected-state overlay colour used by components rendered on an
/// opt-in coloured / gradient background (e.g. `UtopiaSidebar`'s
/// `backgroundColors` mode).
@override final  Color onColoredSelected;
/// Hover-state overlay colour used by components rendered on an opt-in
/// coloured / gradient background (e.g. `UtopiaSidebar`'s
/// `backgroundColors` mode).
@override final  Color onColoredHover;

/// Create a copy of UtopiaThemeColors
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaThemeColorsCopyWith<_UtopiaThemeColors> get copyWith => __$UtopiaThemeColorsCopyWithImpl<_UtopiaThemeColors>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaThemeColors&&(identical(other.primary, primary) || other.primary == primary)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.onPrimary, onPrimary) || other.onPrimary == onPrimary)&&(identical(other.field, field) || other.field == field)&&(identical(other.canvas, canvas) || other.canvas == canvas)&&(identical(other.error, error) || other.error == error)&&(identical(other.disabled, disabled) || other.disabled == disabled)&&(identical(other.text, text) || other.text == text)&&(identical(other.textBody, textBody) || other.textBody == textBody)&&(identical(other.surface, surface) || other.surface == surface)&&(identical(other.border, border) || other.border == border)&&(identical(other.divider, divider) || other.divider == divider)&&(identical(other.rowAlt, rowAlt) || other.rowAlt == rowAlt)&&(identical(other.hover, hover) || other.hover == hover)&&(identical(other.chipBackground, chipBackground) || other.chipBackground == chipBackground)&&(identical(other.chipForeground, chipForeground) || other.chipForeground == chipForeground)&&(identical(other.hint, hint) || other.hint == hint)&&(identical(other.shadow, shadow) || other.shadow == shadow)&&(identical(other.onColoredContent, onColoredContent) || other.onColoredContent == onColoredContent)&&(identical(other.onColoredSelected, onColoredSelected) || other.onColoredSelected == onColoredSelected)&&(identical(other.onColoredHover, onColoredHover) || other.onColoredHover == onColoredHover));
}


@override
int get hashCode => Object.hashAll([runtimeType,primary,accent,onPrimary,field,canvas,error,disabled,text,textBody,surface,border,divider,rowAlt,hover,chipBackground,chipForeground,hint,shadow,onColoredContent,onColoredSelected,onColoredHover]);

@override
String toString() {
  return 'UtopiaThemeColors(primary: $primary, accent: $accent, onPrimary: $onPrimary, field: $field, canvas: $canvas, error: $error, disabled: $disabled, text: $text, textBody: $textBody, surface: $surface, border: $border, divider: $divider, rowAlt: $rowAlt, hover: $hover, chipBackground: $chipBackground, chipForeground: $chipForeground, hint: $hint, shadow: $shadow, onColoredContent: $onColoredContent, onColoredSelected: $onColoredSelected, onColoredHover: $onColoredHover)';
}


}

/// @nodoc
abstract mixin class _$UtopiaThemeColorsCopyWith<$Res> implements $UtopiaThemeColorsCopyWith<$Res> {
  factory _$UtopiaThemeColorsCopyWith(_UtopiaThemeColors value, $Res Function(_UtopiaThemeColors) _then) = __$UtopiaThemeColorsCopyWithImpl;
@override @useResult
$Res call({
 Color primary, Color accent, Color onPrimary, Color field, Color canvas, Color error, Color disabled, Color text, Color textBody, Color surface, Color border, Color? divider, Color rowAlt, Color hover, Color chipBackground, Color chipForeground, Color hint, Color shadow, Color onColoredContent, Color onColoredSelected, Color onColoredHover
});




}
/// @nodoc
class __$UtopiaThemeColorsCopyWithImpl<$Res>
    implements _$UtopiaThemeColorsCopyWith<$Res> {
  __$UtopiaThemeColorsCopyWithImpl(this._self, this._then);

  final _UtopiaThemeColors _self;
  final $Res Function(_UtopiaThemeColors) _then;

/// Create a copy of UtopiaThemeColors
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? primary = null,Object? accent = null,Object? onPrimary = null,Object? field = null,Object? canvas = null,Object? error = null,Object? disabled = null,Object? text = null,Object? textBody = null,Object? surface = null,Object? border = null,Object? divider = freezed,Object? rowAlt = null,Object? hover = null,Object? chipBackground = null,Object? chipForeground = null,Object? hint = null,Object? shadow = null,Object? onColoredContent = null,Object? onColoredSelected = null,Object? onColoredHover = null,}) {
  return _then(_UtopiaThemeColors(
primary: null == primary ? _self.primary : primary // ignore: cast_nullable_to_non_nullable
as Color,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as Color,onPrimary: null == onPrimary ? _self.onPrimary : onPrimary // ignore: cast_nullable_to_non_nullable
as Color,field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as Color,canvas: null == canvas ? _self.canvas : canvas // ignore: cast_nullable_to_non_nullable
as Color,error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Color,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as Color,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as Color,textBody: null == textBody ? _self.textBody : textBody // ignore: cast_nullable_to_non_nullable
as Color,surface: null == surface ? _self.surface : surface // ignore: cast_nullable_to_non_nullable
as Color,border: null == border ? _self.border : border // ignore: cast_nullable_to_non_nullable
as Color,divider: freezed == divider ? _self.divider : divider // ignore: cast_nullable_to_non_nullable
as Color?,rowAlt: null == rowAlt ? _self.rowAlt : rowAlt // ignore: cast_nullable_to_non_nullable
as Color,hover: null == hover ? _self.hover : hover // ignore: cast_nullable_to_non_nullable
as Color,chipBackground: null == chipBackground ? _self.chipBackground : chipBackground // ignore: cast_nullable_to_non_nullable
as Color,chipForeground: null == chipForeground ? _self.chipForeground : chipForeground // ignore: cast_nullable_to_non_nullable
as Color,hint: null == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as Color,shadow: null == shadow ? _self.shadow : shadow // ignore: cast_nullable_to_non_nullable
as Color,onColoredContent: null == onColoredContent ? _self.onColoredContent : onColoredContent // ignore: cast_nullable_to_non_nullable
as Color,onColoredSelected: null == onColoredSelected ? _self.onColoredSelected : onColoredSelected // ignore: cast_nullable_to_non_nullable
as Color,onColoredHover: null == onColoredHover ? _self.onColoredHover : onColoredHover // ignore: cast_nullable_to_non_nullable
as Color,
  ));
}


}

// dart format on
