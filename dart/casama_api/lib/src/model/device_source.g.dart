// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceSourceCWProxy {
  DeviceSource id(String id);

  DeviceSource deviceKey(String deviceKey);

  DeviceSource name(String name);

  DeviceSource platform(DeviceSourcePlatformEnum platform);

  DeviceSource kinds(Map<String, DeviceKindSettings> kinds);

  DeviceSource lastSeenAt(DateTime lastSeenAt);

  DeviceSource createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceSource(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceSource call({
    String id,
    String deviceKey,
    String name,
    DeviceSourcePlatformEnum platform,
    Map<String, DeviceKindSettings> kinds,
    DateTime lastSeenAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceSource.copyWith(...)` or call `instanceOfDeviceSource.copyWith.fieldName(value)` for a single field.
class _$DeviceSourceCWProxyImpl implements _$DeviceSourceCWProxy {
  const _$DeviceSourceCWProxyImpl(this._value);

  final DeviceSource _value;

  @override
  DeviceSource id(String id) => call(id: id);

  @override
  DeviceSource deviceKey(String deviceKey) => call(deviceKey: deviceKey);

  @override
  DeviceSource name(String name) => call(name: name);

  @override
  DeviceSource platform(DeviceSourcePlatformEnum platform) =>
      call(platform: platform);

  @override
  DeviceSource kinds(Map<String, DeviceKindSettings> kinds) =>
      call(kinds: kinds);

  @override
  DeviceSource lastSeenAt(DateTime lastSeenAt) => call(lastSeenAt: lastSeenAt);

  @override
  DeviceSource createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceSource(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceSource call({
    Object? id = const $CopyWithPlaceholder(),
    Object? deviceKey = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? kinds = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return DeviceSource(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      deviceKey: deviceKey == const $CopyWithPlaceholder() || deviceKey == null
          ? _value.deviceKey
          // ignore: cast_nullable_to_non_nullable
          : deviceKey as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as DeviceSourcePlatformEnum,
      kinds: kinds == const $CopyWithPlaceholder() || kinds == null
          ? _value.kinds
          // ignore: cast_nullable_to_non_nullable
          : kinds as Map<String, DeviceKindSettings>,
      lastSeenAt:
          lastSeenAt == const $CopyWithPlaceholder() || lastSeenAt == null
          ? _value.lastSeenAt
          // ignore: cast_nullable_to_non_nullable
          : lastSeenAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $DeviceSourceCopyWith on DeviceSource {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceSource.copyWith(...)` or `instanceOfDeviceSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceSourceCWProxy get copyWith => _$DeviceSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceSource _$DeviceSourceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'DeviceSource',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'device_key',
            'name',
            'platform',
            'kinds',
            'last_seen_at',
            'created_at',
          ],
        );
        final val = DeviceSource(
          id: $checkedConvert('id', (v) => v as String),
          deviceKey: $checkedConvert('device_key', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          platform: $checkedConvert(
            'platform',
            (v) => $enumDecode(_$DeviceSourcePlatformEnumEnumMap, v),
          ),
          kinds: $checkedConvert(
            'kinds',
            (v) => (v as Map<String, dynamic>).map(
              (k, e) => MapEntry(
                k,
                DeviceKindSettings.fromJson(e as Map<String, dynamic>),
              ),
            ),
          ),
          lastSeenAt: $checkedConvert(
            'last_seen_at',
            (v) => DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceKey': 'device_key',
        'lastSeenAt': 'last_seen_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$DeviceSourceToJson(DeviceSource instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_key': instance.deviceKey,
      'name': instance.name,
      'platform': _$DeviceSourcePlatformEnumEnumMap[instance.platform]!,
      'kinds': instance.kinds.map((k, e) => MapEntry(k, e.toJson())),
      'last_seen_at': instance.lastSeenAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$DeviceSourcePlatformEnumEnumMap = {
  DeviceSourcePlatformEnum.ios: 'ios',
  DeviceSourcePlatformEnum.android: 'android',
  DeviceSourcePlatformEnum.macos: 'macos',
  DeviceSourcePlatformEnum.windows: 'windows',
  DeviceSourcePlatformEnum.linux: 'linux',
  DeviceSourcePlatformEnum.web: 'web',
};
