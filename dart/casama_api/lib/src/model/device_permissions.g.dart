// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_permissions.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DevicePermissionsCWProxy {
  DevicePermissions deviceRef(String deviceRef);

  DevicePermissions type(DevicePermissionType type);

  DevicePermissions id(String id);

  DevicePermissions name(String name);

  DevicePermissions platform(String platform);

  DevicePermissions permissions(Map<String, OsPermissionState> permissions);

  DevicePermissions reportedAt(DateTime? reportedAt);

  DevicePermissions online(bool online);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DevicePermissions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePermissions(...).copyWith(id: 12, name: "My name")
  /// ```
  DevicePermissions call({
    String deviceRef,
    DevicePermissionType type,
    String id,
    String name,
    String platform,
    Map<String, OsPermissionState> permissions,
    DateTime? reportedAt,
    bool online,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDevicePermissions.copyWith(...)` or call `instanceOfDevicePermissions.copyWith.fieldName(value)` for a single field.
class _$DevicePermissionsCWProxyImpl implements _$DevicePermissionsCWProxy {
  const _$DevicePermissionsCWProxyImpl(this._value);

  final DevicePermissions _value;

  @override
  DevicePermissions deviceRef(String deviceRef) => call(deviceRef: deviceRef);

  @override
  DevicePermissions type(DevicePermissionType type) => call(type: type);

  @override
  DevicePermissions id(String id) => call(id: id);

  @override
  DevicePermissions name(String name) => call(name: name);

  @override
  DevicePermissions platform(String platform) => call(platform: platform);

  @override
  DevicePermissions permissions(Map<String, OsPermissionState> permissions) =>
      call(permissions: permissions);

  @override
  DevicePermissions reportedAt(DateTime? reportedAt) =>
      call(reportedAt: reportedAt);

  @override
  DevicePermissions online(bool online) => call(online: online);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DevicePermissions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DevicePermissions(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DevicePermissions call({
    Object? deviceRef = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? permissions = const $CopyWithPlaceholder(),
    Object? reportedAt = const $CopyWithPlaceholder(),
    Object? online = const $CopyWithPlaceholder(),
  }) {
    return DevicePermissions(
      deviceRef: deviceRef == const $CopyWithPlaceholder() || deviceRef == null
          ? _value.deviceRef
          // ignore: cast_nullable_to_non_nullable
          : deviceRef as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as DevicePermissionType,
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as String,
      permissions:
          permissions == const $CopyWithPlaceholder() || permissions == null
          ? _value.permissions
          // ignore: cast_nullable_to_non_nullable
          : permissions as Map<String, OsPermissionState>,
      reportedAt: reportedAt == const $CopyWithPlaceholder()
          ? _value.reportedAt
          // ignore: cast_nullable_to_non_nullable
          : reportedAt as DateTime?,
      online: online == const $CopyWithPlaceholder() || online == null
          ? _value.online
          // ignore: cast_nullable_to_non_nullable
          : online as bool,
    );
  }
}

extension $DevicePermissionsCopyWith on DevicePermissions {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDevicePermissions.copyWith(...)` or `instanceOfDevicePermissions.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DevicePermissionsCWProxy get copyWith =>
      _$DevicePermissionsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DevicePermissions _$DevicePermissionsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DevicePermissions', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'device_ref',
      'type',
      'id',
      'name',
      'platform',
      'permissions',
      'reported_at',
      'online',
    ],
  );
  final val = DevicePermissions(
    deviceRef: $checkedConvert('device_ref', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$DevicePermissionTypeEnumMap, v),
    ),
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    platform: $checkedConvert('platform', (v) => v as String),
    permissions: $checkedConvert(
      'permissions',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, $enumDecode(_$OsPermissionStateEnumMap, e)),
      ),
    ),
    reportedAt: $checkedConvert(
      'reported_at',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    online: $checkedConvert('online', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'deviceRef': 'device_ref', 'reportedAt': 'reported_at'});

Map<String, dynamic> _$DevicePermissionsToJson(DevicePermissions instance) =>
    <String, dynamic>{
      'device_ref': instance.deviceRef,
      'type': _$DevicePermissionTypeEnumMap[instance.type]!,
      'id': instance.id,
      'name': instance.name,
      'platform': instance.platform,
      'permissions': instance.permissions.map(
        (k, e) => MapEntry(k, _$OsPermissionStateEnumMap[e]!),
      ),
      'reported_at': instance.reportedAt?.toIso8601String(),
      'online': instance.online,
    };

const _$DevicePermissionTypeEnumMap = {
  DevicePermissionType.computer: 'computer',
  DevicePermissionType.source_: 'source',
};

const _$OsPermissionStateEnumMap = {
  OsPermissionState.granted: 'granted',
  OsPermissionState.limited: 'limited',
  OsPermissionState.denied: 'denied',
  OsPermissionState.notAsked: 'not_asked',
  OsPermissionState.restricted: 'restricted',
  OsPermissionState.unknown: 'unknown',
  OsPermissionState.unavailable: 'unavailable',
};
