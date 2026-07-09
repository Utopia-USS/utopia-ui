// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'utopia_theme_text_styles.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UtopiaThemeTextStyles {

 TextStyle get header; TextStyle get label; TextStyle get text; TextStyle get title; TextStyle get caption; TextStyle get button;
/// Create a copy of UtopiaThemeTextStyles
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UtopiaThemeTextStylesCopyWith<UtopiaThemeTextStyles> get copyWith => _$UtopiaThemeTextStylesCopyWithImpl<UtopiaThemeTextStyles>(this as UtopiaThemeTextStyles, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UtopiaThemeTextStyles&&(identical(other.header, header) || other.header == header)&&(identical(other.label, label) || other.label == label)&&(identical(other.text, text) || other.text == text)&&(identical(other.title, title) || other.title == title)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.button, button) || other.button == button));
}


@override
int get hashCode => Object.hash(runtimeType,header,label,text,title,caption,button);

@override
String toString() {
  return 'UtopiaThemeTextStyles(header: $header, label: $label, text: $text, title: $title, caption: $caption, button: $button)';
}


}

/// @nodoc
abstract mixin class $UtopiaThemeTextStylesCopyWith<$Res>  {
  factory $UtopiaThemeTextStylesCopyWith(UtopiaThemeTextStyles value, $Res Function(UtopiaThemeTextStyles) _then) = _$UtopiaThemeTextStylesCopyWithImpl;
@useResult
$Res call({
 TextStyle header, TextStyle label, TextStyle text, TextStyle title, TextStyle caption, TextStyle button
});




}
/// @nodoc
class _$UtopiaThemeTextStylesCopyWithImpl<$Res>
    implements $UtopiaThemeTextStylesCopyWith<$Res> {
  _$UtopiaThemeTextStylesCopyWithImpl(this._self, this._then);

  final UtopiaThemeTextStyles _self;
  final $Res Function(UtopiaThemeTextStyles) _then;

/// Create a copy of UtopiaThemeTextStyles
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? header = null,Object? label = null,Object? text = null,Object? title = null,Object? caption = null,Object? button = null,}) {
  return _then(_self.copyWith(
header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as TextStyle,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TextStyle,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as TextStyle,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TextStyle,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as TextStyle,button: null == button ? _self.button : button // ignore: cast_nullable_to_non_nullable
as TextStyle,
  ));
}

}


/// Adds pattern-matching-related methods to [UtopiaThemeTextStyles].
extension UtopiaThemeTextStylesPatterns on UtopiaThemeTextStyles {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UtopiaThemeTextStyles value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UtopiaThemeTextStyles() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UtopiaThemeTextStyles value)  $default,){
final _that = this;
switch (_that) {
case _UtopiaThemeTextStyles():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UtopiaThemeTextStyles value)?  $default,){
final _that = this;
switch (_that) {
case _UtopiaThemeTextStyles() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TextStyle header,  TextStyle label,  TextStyle text,  TextStyle title,  TextStyle caption,  TextStyle button)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UtopiaThemeTextStyles() when $default != null:
return $default(_that.header,_that.label,_that.text,_that.title,_that.caption,_that.button);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TextStyle header,  TextStyle label,  TextStyle text,  TextStyle title,  TextStyle caption,  TextStyle button)  $default,) {final _that = this;
switch (_that) {
case _UtopiaThemeTextStyles():
return $default(_that.header,_that.label,_that.text,_that.title,_that.caption,_that.button);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TextStyle header,  TextStyle label,  TextStyle text,  TextStyle title,  TextStyle caption,  TextStyle button)?  $default,) {final _that = this;
switch (_that) {
case _UtopiaThemeTextStyles() when $default != null:
return $default(_that.header,_that.label,_that.text,_that.title,_that.caption,_that.button);case _:
  return null;

}
}

}

/// @nodoc


class _UtopiaThemeTextStyles extends UtopiaThemeTextStyles {
  const _UtopiaThemeTextStyles({required this.header, required this.label, required this.text, required this.title, required this.caption, required this.button}): super._();
  

@override final  TextStyle header;
@override final  TextStyle label;
@override final  TextStyle text;
@override final  TextStyle title;
@override final  TextStyle caption;
@override final  TextStyle button;

/// Create a copy of UtopiaThemeTextStyles
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UtopiaThemeTextStylesCopyWith<_UtopiaThemeTextStyles> get copyWith => __$UtopiaThemeTextStylesCopyWithImpl<_UtopiaThemeTextStyles>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UtopiaThemeTextStyles&&(identical(other.header, header) || other.header == header)&&(identical(other.label, label) || other.label == label)&&(identical(other.text, text) || other.text == text)&&(identical(other.title, title) || other.title == title)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.button, button) || other.button == button));
}


@override
int get hashCode => Object.hash(runtimeType,header,label,text,title,caption,button);

@override
String toString() {
  return 'UtopiaThemeTextStyles(header: $header, label: $label, text: $text, title: $title, caption: $caption, button: $button)';
}


}

/// @nodoc
abstract mixin class _$UtopiaThemeTextStylesCopyWith<$Res> implements $UtopiaThemeTextStylesCopyWith<$Res> {
  factory _$UtopiaThemeTextStylesCopyWith(_UtopiaThemeTextStyles value, $Res Function(_UtopiaThemeTextStyles) _then) = __$UtopiaThemeTextStylesCopyWithImpl;
@override @useResult
$Res call({
 TextStyle header, TextStyle label, TextStyle text, TextStyle title, TextStyle caption, TextStyle button
});




}
/// @nodoc
class __$UtopiaThemeTextStylesCopyWithImpl<$Res>
    implements _$UtopiaThemeTextStylesCopyWith<$Res> {
  __$UtopiaThemeTextStylesCopyWithImpl(this._self, this._then);

  final _UtopiaThemeTextStyles _self;
  final $Res Function(_UtopiaThemeTextStyles) _then;

/// Create a copy of UtopiaThemeTextStyles
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? header = null,Object? label = null,Object? text = null,Object? title = null,Object? caption = null,Object? button = null,}) {
  return _then(_UtopiaThemeTextStyles(
header: null == header ? _self.header : header // ignore: cast_nullable_to_non_nullable
as TextStyle,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as TextStyle,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as TextStyle,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as TextStyle,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as TextStyle,button: null == button ? _self.button : button // ignore: cast_nullable_to_non_nullable
as TextStyle,
  ));
}


}

// dart format on
