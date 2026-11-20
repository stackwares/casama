// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_look.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasLookCWProxy {
  CanvasLook background(CanvasBackground background);

  CanvasLook font(CanvasLookFontEnum font);

  CanvasLook align(CanvasLookAlignEnum align);

  CanvasLook icon(String? icon);

  CanvasLook accent(String? accent);

  CanvasLook ink(CanvasLookInkEnum ink);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasLook(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasLook(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasLook call({
    CanvasBackground background,
    CanvasLookFontEnum font,
    CanvasLookAlignEnum align,
    String? icon,
    String? accent,
    CanvasLookInkEnum ink,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasLook.copyWith(...)` or call `instanceOfCanvasLook.copyWith.fieldName(value)` for a single field.
class _$CanvasLookCWProxyImpl implements _$CanvasLookCWProxy {
  const _$CanvasLookCWProxyImpl(this._value);

  final CanvasLook _value;

  @override
  CanvasLook background(CanvasBackground background) =>
      call(background: background);

  @override
  CanvasLook font(CanvasLookFontEnum font) => call(font: font);

  @override
  CanvasLook align(CanvasLookAlignEnum align) => call(align: align);

  @override
  CanvasLook icon(String? icon) => call(icon: icon);

  @override
  CanvasLook accent(String? accent) => call(accent: accent);

  @override
  CanvasLook ink(CanvasLookInkEnum ink) => call(ink: ink);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasLook(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasLook(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasLook call({
    Object? background = const $CopyWithPlaceholder(),
    Object? font = const $CopyWithPlaceholder(),
    Object? align = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? accent = const $CopyWithPlaceholder(),
    Object? ink = const $CopyWithPlaceholder(),
  }) {
    return CanvasLook(
      background:
          background == const $CopyWithPlaceholder() || background == null
          ? _value.background
          // ignore: cast_nullable_to_non_nullable
          : background as CanvasBackground,
      font: font == const $CopyWithPlaceholder() || font == null
          ? _value.font
          // ignore: cast_nullable_to_non_nullable
          : font as CanvasLookFontEnum,
      align: align == const $CopyWithPlaceholder() || align == null
          ? _value.align
          // ignore: cast_nullable_to_non_nullable
          : align as CanvasLookAlignEnum,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      accent: accent == const $CopyWithPlaceholder()
          ? _value.accent
          // ignore: cast_nullable_to_non_nullable
          : accent as String?,
      ink: ink == const $CopyWithPlaceholder() || ink == null
          ? _value.ink
          // ignore: cast_nullable_to_non_nullable
          : ink as CanvasLookInkEnum,
    );
  }
}

extension $CanvasLookCopyWith on CanvasLook {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasLook.copyWith(...)` or `instanceOfCanvasLook.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasLookCWProxy get copyWith => _$CanvasLookCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasLook _$CanvasLookFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasLook', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'background',
          'font',
          'align',
          'icon',
          'accent',
          'ink',
        ],
      );
      final val = CanvasLook(
        background: $checkedConvert(
          'background',
          (v) => CanvasBackground.fromJson(v as Map<String, dynamic>),
        ),
        font: $checkedConvert(
          'font',
          (v) => $enumDecode(_$CanvasLookFontEnumEnumMap, v),
        ),
        align: $checkedConvert(
          'align',
          (v) => $enumDecode(_$CanvasLookAlignEnumEnumMap, v),
        ),
        icon: $checkedConvert('icon', (v) => v as String?),
        accent: $checkedConvert('accent', (v) => v as String?),
        ink: $checkedConvert(
          'ink',
          (v) => $enumDecode(_$CanvasLookInkEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CanvasLookToJson(CanvasLook instance) =>
    <String, dynamic>{
      'background': instance.background.toJson(),
      'font': _$CanvasLookFontEnumEnumMap[instance.font]!,
      'align': _$CanvasLookAlignEnumEnumMap[instance.align]!,
      'icon': instance.icon,
      'accent': instance.accent,
      'ink': _$CanvasLookInkEnumEnumMap[instance.ink]!,
    };

const _$CanvasLookFontEnumEnumMap = {
  CanvasLookFontEnum.plain: 'plain',
  CanvasLookFontEnum.serif: 'serif',
  CanvasLookFontEnum.rounded: 'rounded',
  CanvasLookFontEnum.mono: 'mono',
};

const _$CanvasLookAlignEnumEnumMap = {
  CanvasLookAlignEnum.start: 'start',
  CanvasLookAlignEnum.center: 'center',
};

const _$CanvasLookInkEnumEnumMap = {
  CanvasLookInkEnum.light: 'light',
  CanvasLookInkEnum.dark: 'dark',
  CanvasLookInkEnum.auto: 'auto',
};
