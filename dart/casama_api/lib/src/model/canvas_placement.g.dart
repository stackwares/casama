// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_placement.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasPlacementCWProxy {
  CanvasPlacement platform(CanvasPlacementPlatformEnum platform);

  CanvasPlacement label(String? label);

  CanvasPlacement sizes(List<String> sizes);

  CanvasPlacement seenAt(DateTime seenAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasPlacement(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasPlacement(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasPlacement call({
    CanvasPlacementPlatformEnum platform,
    String? label,
    List<String> sizes,
    DateTime seenAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasPlacement.copyWith(...)` or call `instanceOfCanvasPlacement.copyWith.fieldName(value)` for a single field.
class _$CanvasPlacementCWProxyImpl implements _$CanvasPlacementCWProxy {
  const _$CanvasPlacementCWProxyImpl(this._value);

  final CanvasPlacement _value;

  @override
  CanvasPlacement platform(CanvasPlacementPlatformEnum platform) =>
      call(platform: platform);

  @override
  CanvasPlacement label(String? label) => call(label: label);

  @override
  CanvasPlacement sizes(List<String> sizes) => call(sizes: sizes);

  @override
  CanvasPlacement seenAt(DateTime seenAt) => call(seenAt: seenAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasPlacement(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasPlacement(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasPlacement call({
    Object? platform = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? sizes = const $CopyWithPlaceholder(),
    Object? seenAt = const $CopyWithPlaceholder(),
  }) {
    return CanvasPlacement(
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as CanvasPlacementPlatformEnum,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String?,
      sizes: sizes == const $CopyWithPlaceholder() || sizes == null
          ? _value.sizes
          // ignore: cast_nullable_to_non_nullable
          : sizes as List<String>,
      seenAt: seenAt == const $CopyWithPlaceholder() || seenAt == null
          ? _value.seenAt
          // ignore: cast_nullable_to_non_nullable
          : seenAt as DateTime,
    );
  }
}

extension $CanvasPlacementCopyWith on CanvasPlacement {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasPlacement.copyWith(...)` or `instanceOfCanvasPlacement.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasPlacementCWProxy get copyWith => _$CanvasPlacementCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasPlacement _$CanvasPlacementFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasPlacement', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['platform', 'label', 'sizes', 'seen_at'],
      );
      final val = CanvasPlacement(
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$CanvasPlacementPlatformEnumEnumMap, v),
        ),
        label: $checkedConvert('label', (v) => v as String?),
        sizes: $checkedConvert(
          'sizes',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        seenAt: $checkedConvert('seen_at', (v) => DateTime.parse(v as String)),
      );
      return val;
    }, fieldKeyMap: const {'seenAt': 'seen_at'});

Map<String, dynamic> _$CanvasPlacementToJson(CanvasPlacement instance) =>
    <String, dynamic>{
      'platform': _$CanvasPlacementPlatformEnumEnumMap[instance.platform]!,
      'label': instance.label,
      'sizes': instance.sizes,
      'seen_at': instance.seenAt.toIso8601String(),
    };

const _$CanvasPlacementPlatformEnumEnumMap = {
  CanvasPlacementPlatformEnum.ios: 'ios',
  CanvasPlacementPlatformEnum.android: 'android',
  CanvasPlacementPlatformEnum.macos: 'macos',
};
