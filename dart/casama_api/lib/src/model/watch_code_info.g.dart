// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_code_info.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchCodeInfoCWProxy {
  WatchCodeInfo platform(WatchPlatform platform);

  WatchCodeInfo name(String name);

  WatchCodeInfo model(String? model);

  WatchCodeInfo expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCodeInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCodeInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchCodeInfo call({
    WatchPlatform platform,
    String name,
    String? model,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchCodeInfo.copyWith(...)` or call `instanceOfWatchCodeInfo.copyWith.fieldName(value)` for a single field.
class _$WatchCodeInfoCWProxyImpl implements _$WatchCodeInfoCWProxy {
  const _$WatchCodeInfoCWProxyImpl(this._value);

  final WatchCodeInfo _value;

  @override
  WatchCodeInfo platform(WatchPlatform platform) => call(platform: platform);

  @override
  WatchCodeInfo name(String name) => call(name: name);

  @override
  WatchCodeInfo model(String? model) => call(model: model);

  @override
  WatchCodeInfo expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCodeInfo(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCodeInfo(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchCodeInfo call({
    Object? platform = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return WatchCodeInfo(
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as WatchPlatform,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String?,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $WatchCodeInfoCopyWith on WatchCodeInfo {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchCodeInfo.copyWith(...)` or `instanceOfWatchCodeInfo.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchCodeInfoCWProxy get copyWith => _$WatchCodeInfoCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchCodeInfo _$WatchCodeInfoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchCodeInfo', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['platform', 'name', 'model', 'expires_at'],
      );
      final val = WatchCodeInfo(
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$WatchPlatformEnumMap, v),
        ),
        name: $checkedConvert('name', (v) => v as String),
        model: $checkedConvert('model', (v) => v as String?),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$WatchCodeInfoToJson(WatchCodeInfo instance) =>
    <String, dynamic>{
      'platform': _$WatchPlatformEnumMap[instance.platform]!,
      'name': instance.name,
      'model': instance.model,
      'expires_at': instance.expiresAt.toIso8601String(),
    };

const _$WatchPlatformEnumMap = {
  WatchPlatform.watchos: 'watchos',
  WatchPlatform.wearos: 'wearos',
};
