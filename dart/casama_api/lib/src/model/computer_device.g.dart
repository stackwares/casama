// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_device.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerDeviceCWProxy {
  ComputerDevice platform(ComputerDevicePlatformEnum platform);

  ComputerDevice online(bool online);

  ComputerDevice lastSeenAt(DateTime? lastSeenAt);

  ComputerDevice capabilities(LocalCapabilities capabilities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerDevice call({
    ComputerDevicePlatformEnum platform,
    bool online,
    DateTime? lastSeenAt,
    LocalCapabilities capabilities,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerDevice.copyWith(...)` or call `instanceOfComputerDevice.copyWith.fieldName(value)` for a single field.
class _$ComputerDeviceCWProxyImpl implements _$ComputerDeviceCWProxy {
  const _$ComputerDeviceCWProxyImpl(this._value);

  final ComputerDevice _value;

  @override
  ComputerDevice platform(ComputerDevicePlatformEnum platform) =>
      call(platform: platform);

  @override
  ComputerDevice online(bool online) => call(online: online);

  @override
  ComputerDevice lastSeenAt(DateTime? lastSeenAt) =>
      call(lastSeenAt: lastSeenAt);

  @override
  ComputerDevice capabilities(LocalCapabilities capabilities) =>
      call(capabilities: capabilities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerDevice call({
    Object? platform = const $CopyWithPlaceholder(),
    Object? online = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? capabilities = const $CopyWithPlaceholder(),
  }) {
    return ComputerDevice(
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as ComputerDevicePlatformEnum,
      online: online == const $CopyWithPlaceholder() || online == null
          ? _value.online
          // ignore: cast_nullable_to_non_nullable
          : online as bool,
      lastSeenAt: lastSeenAt == const $CopyWithPlaceholder()
          ? _value.lastSeenAt
          // ignore: cast_nullable_to_non_nullable
          : lastSeenAt as DateTime?,
      capabilities:
          capabilities == const $CopyWithPlaceholder() || capabilities == null
          ? _value.capabilities
          // ignore: cast_nullable_to_non_nullable
          : capabilities as LocalCapabilities,
    );
  }
}

extension $ComputerDeviceCopyWith on ComputerDevice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerDevice.copyWith(...)` or `instanceOfComputerDevice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerDeviceCWProxy get copyWith => _$ComputerDeviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerDevice _$ComputerDeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerDevice', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'platform',
          'online',
          'last_seen_at',
          'capabilities',
        ],
      );
      final val = ComputerDevice(
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecode(_$ComputerDevicePlatformEnumEnumMap, v),
        ),
        online: $checkedConvert('online', (v) => v as bool),
        lastSeenAt: $checkedConvert(
          'last_seen_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        capabilities: $checkedConvert(
          'capabilities',
          (v) => LocalCapabilities.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'lastSeenAt': 'last_seen_at'});

Map<String, dynamic> _$ComputerDeviceToJson(ComputerDevice instance) =>
    <String, dynamic>{
      'platform': _$ComputerDevicePlatformEnumEnumMap[instance.platform]!,
      'online': instance.online,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'capabilities': instance.capabilities.toJson(),
    };

const _$ComputerDevicePlatformEnumEnumMap = {
  ComputerDevicePlatformEnum.macos: 'macos',
  ComputerDevicePlatformEnum.windows: 'windows',
  ComputerDevicePlatformEnum.linux: 'linux',
};
