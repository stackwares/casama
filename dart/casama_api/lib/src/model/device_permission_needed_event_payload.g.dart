// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_permission_needed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DevicePermissionNeededEventPayloadCWProxy {
  DevicePermissionNeededEventPayload deviceRef(String deviceRef);

  DevicePermissionNeededEventPayload deviceName(String deviceName);

  DevicePermissionNeededEventPayload platform(String platform);

  DevicePermissionNeededEventPayload permissions(List<String> permissions);

  DevicePermissionNeededEventPayload reason(String reason);

  DevicePermissionNeededEventPayload botId(String botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DevicePermissionNeededEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePermissionNeededEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  DevicePermissionNeededEventPayload call({
    String deviceRef,
    String deviceName,
    String platform,
    List<String> permissions,
    String reason,
    String botId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDevicePermissionNeededEventPayload.copyWith(...)` or call `instanceOfDevicePermissionNeededEventPayload.copyWith.fieldName(value)` for a single field.
class _$DevicePermissionNeededEventPayloadCWProxyImpl
    implements _$DevicePermissionNeededEventPayloadCWProxy {
  const _$DevicePermissionNeededEventPayloadCWProxyImpl(this._value);

  final DevicePermissionNeededEventPayload _value;

  @override
  DevicePermissionNeededEventPayload deviceRef(String deviceRef) =>
      call(deviceRef: deviceRef);

  @override
  DevicePermissionNeededEventPayload deviceName(String deviceName) =>
      call(deviceName: deviceName);

  @override
  DevicePermissionNeededEventPayload platform(String platform) =>
      call(platform: platform);

  @override
  DevicePermissionNeededEventPayload permissions(List<String> permissions) =>
      call(permissions: permissions);

  @override
  DevicePermissionNeededEventPayload reason(String reason) =>
      call(reason: reason);

  @override
  DevicePermissionNeededEventPayload botId(String botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DevicePermissionNeededEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePermissionNeededEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DevicePermissionNeededEventPayload call({
    Object? deviceRef = const $CopyWithPlaceholder(),
    Object? deviceName = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? permissions = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return DevicePermissionNeededEventPayload(
      deviceRef: deviceRef == const $CopyWithPlaceholder() || deviceRef == null
          ? _value.deviceRef
          // ignore: cast_nullable_to_non_nullable
          : deviceRef as String,
      deviceName:
          deviceName == const $CopyWithPlaceholder() || deviceName == null
          ? _value.deviceName
          // ignore: cast_nullable_to_non_nullable
          : deviceName as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String,
      permissions:
          permissions == const $CopyWithPlaceholder() || permissions == null
          ? _value.permissions
          // ignore: cast_nullable_to_non_nullable
          : permissions as List<String>,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
    );
  }
}

extension $DevicePermissionNeededEventPayloadCopyWith
    on DevicePermissionNeededEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDevicePermissionNeededEventPayload.copyWith(...)` or `instanceOfDevicePermissionNeededEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DevicePermissionNeededEventPayloadCWProxy get copyWith =>
      _$DevicePermissionNeededEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePermissionNeededEventPayload _$DevicePermissionNeededEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'DevicePermissionNeededEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'device_ref',
        'device_name',
        'platform',
        'permissions',
        'reason',
        'bot_id',
      ],
    );
    final val = DevicePermissionNeededEventPayload(
      deviceRef: $checkedConvert('device_ref', (v) => v as String),
      deviceName: $checkedConvert('device_name', (v) => v as String),
      platform: $checkedConvert('platform', (v) => v as String),
      permissions: $checkedConvert(
        'permissions',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      reason: $checkedConvert('reason', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'deviceRef': 'device_ref',
    'deviceName': 'device_name',
    'botId': 'bot_id',
  },
);

Map<String, dynamic> _$DevicePermissionNeededEventPayloadToJson(
  DevicePermissionNeededEventPayload instance,
) => <String, dynamic>{
  'device_ref': instance.deviceRef,
  'device_name': instance.deviceName,
  'platform': instance.platform,
  'permissions': instance.permissions,
  'reason': instance.reason,
  'bot_id': instance.botId,
};
