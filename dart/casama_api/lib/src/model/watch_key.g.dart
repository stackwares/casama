// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchKeyCWProxy {
  WatchKey id(String id);

  WatchKey orgId(String orgId);

  WatchKey platform(WatchPlatform platform);

  WatchKey name(String name);

  WatchKey model(String? model);

  WatchKey appVersion(String? appVersion);

  WatchKey osVersion(String? osVersion);

  WatchKey pairedBy(WatchKeyPairedByEnum pairedBy);

  WatchKey hasPush(bool hasPush);

  WatchKey lastUsedAt(DateTime? lastUsedAt);

  WatchKey createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchKey(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchKey call({
    String id,
    String orgId,
    WatchPlatform platform,
    String name,
    String? model,
    String? appVersion,
    String? osVersion,
    WatchKeyPairedByEnum pairedBy,
    bool hasPush,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchKey.copyWith(...)` or call `instanceOfWatchKey.copyWith.fieldName(value)` for a single field.
class _$WatchKeyCWProxyImpl implements _$WatchKeyCWProxy {
  const _$WatchKeyCWProxyImpl(this._value);

  final WatchKey _value;

  @override
  WatchKey id(String id) => call(id: id);

  @override
  WatchKey orgId(String orgId) => call(orgId: orgId);

  @override
  WatchKey platform(WatchPlatform platform) => call(platform: platform);

  @override
  WatchKey name(String name) => call(name: name);

  @override
  WatchKey model(String? model) => call(model: model);

  @override
  WatchKey appVersion(String? appVersion) => call(appVersion: appVersion);

  @override
  WatchKey osVersion(String? osVersion) => call(osVersion: osVersion);

  @override
  WatchKey pairedBy(WatchKeyPairedByEnum pairedBy) => call(pairedBy: pairedBy);

  @override
  WatchKey hasPush(bool hasPush) => call(hasPush: hasPush);

  @override
  WatchKey lastUsedAt(DateTime? lastUsedAt) => call(lastUsedAt: lastUsedAt);

  @override
  WatchKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? osVersion = const $CopyWithPlaceholder(),
    Object? pairedBy = const $CopyWithPlaceholder(),
    Object? hasPush = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return WatchKey(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
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
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String?,
      osVersion: osVersion == const $CopyWithPlaceholder()
          ? _value.osVersion
          // ignore: cast_nullable_to_non_nullable
          : osVersion as String?,
      pairedBy: pairedBy == const $CopyWithPlaceholder() || pairedBy == null
          ? _value.pairedBy
          // ignore: cast_nullable_to_non_nullable
          : pairedBy as WatchKeyPairedByEnum,
      hasPush: hasPush == const $CopyWithPlaceholder() || hasPush == null
          ? _value.hasPush
          // ignore: cast_nullable_to_non_nullable
          : hasPush as bool,
      lastUsedAt: lastUsedAt == const $CopyWithPlaceholder()
          ? _value.lastUsedAt
          // ignore: cast_nullable_to_non_nullable
          : lastUsedAt as DateTime?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $WatchKeyCopyWith on WatchKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchKey.copyWith(...)` or `instanceOfWatchKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchKeyCWProxy get copyWith => _$WatchKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchKey _$WatchKeyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'WatchKey',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'platform',
        'name',
        'model',
        'app_version',
        'os_version',
        'paired_by',
        'has_push',
        'last_used_at',
        'created_at',
      ],
    );
    final val = WatchKey(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      platform: $checkedConvert(
        'platform',
        (v) => $enumDecode(_$WatchPlatformEnumMap, v),
      ),
      name: $checkedConvert('name', (v) => v as String),
      model: $checkedConvert('model', (v) => v as String?),
      appVersion: $checkedConvert('app_version', (v) => v as String?),
      osVersion: $checkedConvert('os_version', (v) => v as String?),
      pairedBy: $checkedConvert(
        'paired_by',
        (v) => $enumDecode(_$WatchKeyPairedByEnumEnumMap, v),
      ),
      hasPush: $checkedConvert('has_push', (v) => v as bool),
      lastUsedAt: $checkedConvert(
        'last_used_at',
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
    'appVersion': 'app_version',
    'osVersion': 'os_version',
    'pairedBy': 'paired_by',
    'hasPush': 'has_push',
    'lastUsedAt': 'last_used_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$WatchKeyToJson(WatchKey instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'platform': _$WatchPlatformEnumMap[instance.platform]!,
  'name': instance.name,
  'model': instance.model,
  'app_version': instance.appVersion,
  'os_version': instance.osVersion,
  'paired_by': _$WatchKeyPairedByEnumEnumMap[instance.pairedBy]!,
  'has_push': instance.hasPush,
  'last_used_at': instance.lastUsedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};

const _$WatchPlatformEnumMap = {
  WatchPlatform.watchos: 'watchos',
  WatchPlatform.wearos: 'wearos',
};

const _$WatchKeyPairedByEnumEnumMap = {
  WatchKeyPairedByEnum.phone: 'phone',
  WatchKeyPairedByEnum.code: 'code',
};
