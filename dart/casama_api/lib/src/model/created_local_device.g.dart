// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_local_device.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedLocalDeviceCWProxy {
  CreatedLocalDevice id(String id);

  CreatedLocalDevice orgId(String orgId);

  CreatedLocalDevice userId(String userId);

  CreatedLocalDevice computerId(String? computerId);

  CreatedLocalDevice name(String name);

  CreatedLocalDevice platform(CreatedLocalDevicePlatformEnum platform);

  CreatedLocalDevice osVersion(String? osVersion);

  CreatedLocalDevice capabilities(LocalCapabilities capabilities);

  CreatedLocalDevice allowedRoots(List<String> allowedRoots);

  CreatedLocalDevice allowedBotIds(List<String> allowedBotIds);

  CreatedLocalDevice enabled(bool enabled);

  CreatedLocalDevice online(bool online);

  CreatedLocalDevice lastSeenAt(DateTime? lastSeenAt);

  CreatedLocalDevice createdAt(DateTime createdAt);

  CreatedLocalDevice token(String token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedLocalDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedLocalDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedLocalDevice call({
    String id,
    String orgId,
    String userId,
    String? computerId,
    String name,
    CreatedLocalDevicePlatformEnum platform,
    String? osVersion,
    LocalCapabilities capabilities,
    List<String> allowedRoots,
    List<String> allowedBotIds,
    bool enabled,
    bool online,
    DateTime? lastSeenAt,
    DateTime createdAt,
    String token,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedLocalDevice.copyWith(...)` or call `instanceOfCreatedLocalDevice.copyWith.fieldName(value)` for a single field.
class _$CreatedLocalDeviceCWProxyImpl implements _$CreatedLocalDeviceCWProxy {
  const _$CreatedLocalDeviceCWProxyImpl(this._value);

  final CreatedLocalDevice _value;

  @override
  CreatedLocalDevice id(String id) => call(id: id);

  @override
  CreatedLocalDevice orgId(String orgId) => call(orgId: orgId);

  @override
  CreatedLocalDevice userId(String userId) => call(userId: userId);

  @override
  CreatedLocalDevice computerId(String? computerId) =>
      call(computerId: computerId);

  @override
  CreatedLocalDevice name(String name) => call(name: name);

  @override
  CreatedLocalDevice platform(CreatedLocalDevicePlatformEnum platform) =>
      call(platform: platform);

  @override
  CreatedLocalDevice osVersion(String? osVersion) => call(osVersion: osVersion);

  @override
  CreatedLocalDevice capabilities(LocalCapabilities capabilities) =>
      call(capabilities: capabilities);

  @override
  CreatedLocalDevice allowedRoots(List<String> allowedRoots) =>
      call(allowedRoots: allowedRoots);

  @override
  CreatedLocalDevice allowedBotIds(List<String> allowedBotIds) =>
      call(allowedBotIds: allowedBotIds);

  @override
  CreatedLocalDevice enabled(bool enabled) => call(enabled: enabled);

  @override
  CreatedLocalDevice online(bool online) => call(online: online);

  @override
  CreatedLocalDevice lastSeenAt(DateTime? lastSeenAt) =>
      call(lastSeenAt: lastSeenAt);

  @override
  CreatedLocalDevice createdAt(DateTime createdAt) =>
      call(createdAt: createdAt);

  @override
  CreatedLocalDevice token(String token) => call(token: token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedLocalDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedLocalDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedLocalDevice call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? osVersion = const $CopyWithPlaceholder(),
    Object? capabilities = const $CopyWithPlaceholder(),
    Object? allowedRoots = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? online = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
  }) {
    return CreatedLocalDevice(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      userId: userId == const $CopyWithPlaceholder() || userId == null
          ? _value.userId
          // ignore: cast_nullable_to_non_nullable
          : userId as String,
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as CreatedLocalDevicePlatformEnum,
      osVersion: osVersion == const $CopyWithPlaceholder()
          ? _value.osVersion
          // ignore: cast_nullable_to_non_nullable
          : osVersion as String?,
      capabilities:
          capabilities == const $CopyWithPlaceholder() || capabilities == null
          ? _value.capabilities
          // ignore: cast_nullable_to_non_nullable
          : capabilities as LocalCapabilities,
      allowedRoots:
          allowedRoots == const $CopyWithPlaceholder() || allowedRoots == null
          ? _value.allowedRoots
          // ignore: cast_nullable_to_non_nullable
          : allowedRoots as List<String>,
      allowedBotIds:
          allowedBotIds == const $CopyWithPlaceholder() || allowedBotIds == null
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      online: online == const $CopyWithPlaceholder() || online == null
          ? _value.online
          // ignore: cast_nullable_to_non_nullable
          : online as bool,
      lastSeenAt: lastSeenAt == const $CopyWithPlaceholder()
          ? _value.lastSeenAt
          // ignore: cast_nullable_to_non_nullable
          : lastSeenAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
    );
  }
}

extension $CreatedLocalDeviceCopyWith on CreatedLocalDevice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedLocalDevice.copyWith(...)` or `instanceOfCreatedLocalDevice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedLocalDeviceCWProxy get copyWith =>
      _$CreatedLocalDeviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedLocalDevice _$CreatedLocalDeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedLocalDevice',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'org_id',
            'user_id',
            'computer_id',
            'name',
            'platform',
            'capabilities',
            'allowed_roots',
            'allowed_bot_ids',
            'enabled',
            'online',
            'last_seen_at',
            'created_at',
            'token',
          ],
        );
        final val = CreatedLocalDevice(
          id: $checkedConvert('id', (v) => v as String),
          orgId: $checkedConvert('org_id', (v) => v as String),
          userId: $checkedConvert('user_id', (v) => v as String),
          computerId: $checkedConvert('computer_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String),
          platform: $checkedConvert(
            'platform',
            (v) => $enumDecode(_$CreatedLocalDevicePlatformEnumEnumMap, v),
          ),
          osVersion: $checkedConvert('os_version', (v) => v as String?),
          capabilities: $checkedConvert(
            'capabilities',
            (v) => LocalCapabilities.fromJson(v as Map<String, dynamic>),
          ),
          allowedRoots: $checkedConvert(
            'allowed_roots',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          allowedBotIds: $checkedConvert(
            'allowed_bot_ids',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          online: $checkedConvert('online', (v) => v as bool),
          lastSeenAt: $checkedConvert(
            'last_seen_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          token: $checkedConvert('token', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'userId': 'user_id',
        'computerId': 'computer_id',
        'osVersion': 'os_version',
        'allowedRoots': 'allowed_roots',
        'allowedBotIds': 'allowed_bot_ids',
        'lastSeenAt': 'last_seen_at',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$CreatedLocalDeviceToJson(CreatedLocalDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'user_id': instance.userId,
      'computer_id': instance.computerId,
      'name': instance.name,
      'platform': _$CreatedLocalDevicePlatformEnumEnumMap[instance.platform]!,
      'os_version': ?instance.osVersion,
      'capabilities': instance.capabilities.toJson(),
      'allowed_roots': instance.allowedRoots,
      'allowed_bot_ids': instance.allowedBotIds,
      'enabled': instance.enabled,
      'online': instance.online,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'token': instance.token,
    };

const _$CreatedLocalDevicePlatformEnumEnumMap = {
  CreatedLocalDevicePlatformEnum.macos: 'macos',
  CreatedLocalDevicePlatformEnum.windows: 'windows',
  CreatedLocalDevicePlatformEnum.linux: 'linux',
};
