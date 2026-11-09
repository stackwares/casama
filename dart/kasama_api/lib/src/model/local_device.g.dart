// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_device.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalDeviceCWProxy {
  LocalDevice id(String id);

  LocalDevice orgId(String orgId);

  LocalDevice userId(String userId);

  LocalDevice computerId(String? computerId);

  LocalDevice name(String name);

  LocalDevice platform(LocalDevicePlatformEnum platform);

  LocalDevice capabilities(LocalCapabilities capabilities);

  LocalDevice allowedRoots(List<String> allowedRoots);

  LocalDevice allowedBotIds(List<String> allowedBotIds);

  LocalDevice enabled(bool enabled);

  LocalDevice online(bool online);

  LocalDevice lastSeenAt(DateTime? lastSeenAt);

  LocalDevice createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalDevice call({
    String id,
    String orgId,
    String userId,
    String? computerId,
    String name,
    LocalDevicePlatformEnum platform,
    LocalCapabilities capabilities,
    List<String> allowedRoots,
    List<String> allowedBotIds,
    bool enabled,
    bool online,
    DateTime? lastSeenAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalDevice.copyWith(...)` or call `instanceOfLocalDevice.copyWith.fieldName(value)` for a single field.
class _$LocalDeviceCWProxyImpl implements _$LocalDeviceCWProxy {
  const _$LocalDeviceCWProxyImpl(this._value);

  final LocalDevice _value;

  @override
  LocalDevice id(String id) => call(id: id);

  @override
  LocalDevice orgId(String orgId) => call(orgId: orgId);

  @override
  LocalDevice userId(String userId) => call(userId: userId);

  @override
  LocalDevice computerId(String? computerId) => call(computerId: computerId);

  @override
  LocalDevice name(String name) => call(name: name);

  @override
  LocalDevice platform(LocalDevicePlatformEnum platform) =>
      call(platform: platform);

  @override
  LocalDevice capabilities(LocalCapabilities capabilities) =>
      call(capabilities: capabilities);

  @override
  LocalDevice allowedRoots(List<String> allowedRoots) =>
      call(allowedRoots: allowedRoots);

  @override
  LocalDevice allowedBotIds(List<String> allowedBotIds) =>
      call(allowedBotIds: allowedBotIds);

  @override
  LocalDevice enabled(bool enabled) => call(enabled: enabled);

  @override
  LocalDevice online(bool online) => call(online: online);

  @override
  LocalDevice lastSeenAt(DateTime? lastSeenAt) => call(lastSeenAt: lastSeenAt);

  @override
  LocalDevice createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalDevice call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? userId = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? capabilities = const $CopyWithPlaceholder(),
    Object? allowedRoots = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? online = const $CopyWithPlaceholder(),
    Object? lastSeenAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return LocalDevice(
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
          : platform as LocalDevicePlatformEnum,
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
    );
  }
}

extension $LocalDeviceCopyWith on LocalDevice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalDevice.copyWith(...)` or `instanceOfLocalDevice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalDeviceCWProxy get copyWith => _$LocalDeviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalDevice _$LocalDeviceFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LocalDevice',
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
      ],
    );
    final val = LocalDevice(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      userId: $checkedConvert('user_id', (v) => v as String),
      computerId: $checkedConvert('computer_id', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String),
      platform: $checkedConvert(
        'platform',
        (v) => $enumDecode(_$LocalDevicePlatformEnumEnumMap, v),
      ),
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
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'userId': 'user_id',
    'computerId': 'computer_id',
    'allowedRoots': 'allowed_roots',
    'allowedBotIds': 'allowed_bot_ids',
    'lastSeenAt': 'last_seen_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$LocalDeviceToJson(LocalDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'user_id': instance.userId,
      'computer_id': instance.computerId,
      'name': instance.name,
      'platform': _$LocalDevicePlatformEnumEnumMap[instance.platform]!,
      'capabilities': instance.capabilities.toJson(),
      'allowed_roots': instance.allowedRoots,
      'allowed_bot_ids': instance.allowedBotIds,
      'enabled': instance.enabled,
      'online': instance.online,
      'last_seen_at': instance.lastSeenAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$LocalDevicePlatformEnumEnumMap = {
  LocalDevicePlatformEnum.macos: 'macos',
  LocalDevicePlatformEnum.windows: 'windows',
  LocalDevicePlatformEnum.linux: 'linux',
};
