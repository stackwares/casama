// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_picture_crop.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotPictureCropCWProxy {
  BotPictureCrop x(num x);

  BotPictureCrop y(num y);

  BotPictureCrop scale(num scale);

  BotPictureCrop rotation(int rotation);

  BotPictureCrop mirror(bool mirror);

  BotPictureCrop background(BotPictureCropBackgroundEnum background);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPictureCrop(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPictureCrop(...).copyWith(id: 12, name: "My name")
  /// ```
  BotPictureCrop call({
    num x,
    num y,
    num scale,
    int rotation,
    bool mirror,
    BotPictureCropBackgroundEnum background,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotPictureCrop.copyWith(...)` or call `instanceOfBotPictureCrop.copyWith.fieldName(value)` for a single field.
class _$BotPictureCropCWProxyImpl implements _$BotPictureCropCWProxy {
  const _$BotPictureCropCWProxyImpl(this._value);

  final BotPictureCrop _value;

  @override
  BotPictureCrop x(num x) => call(x: x);

  @override
  BotPictureCrop y(num y) => call(y: y);

  @override
  BotPictureCrop scale(num scale) => call(scale: scale);

  @override
  BotPictureCrop rotation(int rotation) => call(rotation: rotation);

  @override
  BotPictureCrop mirror(bool mirror) => call(mirror: mirror);

  @override
  BotPictureCrop background(BotPictureCropBackgroundEnum background) =>
      call(background: background);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotPictureCrop(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotPictureCrop(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotPictureCrop call({
    Object? x = const $CopyWithPlaceholder(),
    Object? y = const $CopyWithPlaceholder(),
    Object? scale = const $CopyWithPlaceholder(),
    Object? rotation = const $CopyWithPlaceholder(),
    Object? mirror = const $CopyWithPlaceholder(),
    Object? background = const $CopyWithPlaceholder(),
  }) {
    return BotPictureCrop(
      x: x == const $CopyWithPlaceholder() || x == null
          ? _value.x
          // ignore: cast_nullable_to_non_nullable
          : x as num,
      y: y == const $CopyWithPlaceholder() || y == null
          ? _value.y
          // ignore: cast_nullable_to_non_nullable
          : y as num,
      scale: scale == const $CopyWithPlaceholder() || scale == null
          ? _value.scale
          // ignore: cast_nullable_to_non_nullable
          : scale as num,
      rotation: rotation == const $CopyWithPlaceholder() || rotation == null
          ? _value.rotation
          // ignore: cast_nullable_to_non_nullable
          : rotation as int,
      mirror: mirror == const $CopyWithPlaceholder() || mirror == null
          ? _value.mirror
          // ignore: cast_nullable_to_non_nullable
          : mirror as bool,
      background:
          background == const $CopyWithPlaceholder() || background == null
          ? _value.background
          // ignore: cast_nullable_to_non_nullable
          : background as BotPictureCropBackgroundEnum,
    );
  }
}

extension $BotPictureCropCopyWith on BotPictureCrop {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotPictureCrop.copyWith(...)` or `instanceOfBotPictureCrop.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotPictureCropCWProxy get copyWith => _$BotPictureCropCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotPictureCrop _$BotPictureCropFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotPictureCrop', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'x',
          'y',
          'scale',
          'rotation',
          'mirror',
          'background',
        ],
      );
      final val = BotPictureCrop(
        x: $checkedConvert('x', (v) => v as num),
        y: $checkedConvert('y', (v) => v as num),
        scale: $checkedConvert('scale', (v) => v as num),
        rotation: $checkedConvert('rotation', (v) => (v as num).toInt()),
        mirror: $checkedConvert('mirror', (v) => v as bool),
        background: $checkedConvert(
          'background',
          (v) => $enumDecode(_$BotPictureCropBackgroundEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BotPictureCropToJson(BotPictureCrop instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'scale': instance.scale,
      'rotation': instance.rotation,
      'mirror': instance.mirror,
      'background': _$BotPictureCropBackgroundEnumEnumMap[instance.background]!,
    };

const _$BotPictureCropBackgroundEnumEnumMap = {
  BotPictureCropBackgroundEnum.none: 'none',
  BotPictureCropBackgroundEnum.bot: 'bot',
  BotPictureCropBackgroundEnum.white: 'white',
  BotPictureCropBackgroundEnum.black: 'black',
};
