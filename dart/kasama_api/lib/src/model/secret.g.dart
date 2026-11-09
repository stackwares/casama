// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretCWProxy {
  Secret id(String id);

  Secret orgId(String orgId);

  Secret name(String name);

  Secret allowedHosts(List<String> allowedHosts);

  Secret allowedBotIds(List<String>? allowedBotIds);

  Secret createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Secret(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Secret(...).copyWith(id: 12, name: "My name")
  /// ````
  Secret call({
    String id,
    String orgId,
    String name,
    List<String> allowedHosts,
    List<String>? allowedBotIds,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSecret.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSecret.copyWith.fieldName(...)`
class _$SecretCWProxyImpl implements _$SecretCWProxy {
  const _$SecretCWProxyImpl(this._value);

  final Secret _value;

  @override
  Secret id(String id) => this(id: id);

  @override
  Secret orgId(String orgId) => this(orgId: orgId);

  @override
  Secret name(String name) => this(name: name);

  @override
  Secret allowedHosts(List<String> allowedHosts) =>
      this(allowedHosts: allowedHosts);

  @override
  Secret allowedBotIds(List<String>? allowedBotIds) =>
      this(allowedBotIds: allowedBotIds);

  @override
  Secret createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Secret(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Secret(...).copyWith(id: 12, name: "My name")
  /// ````
  Secret call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? allowedHosts = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Secret(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      allowedHosts: allowedHosts == const $CopyWithPlaceholder()
          ? _value.allowedHosts
          // ignore: cast_nullable_to_non_nullable
          : allowedHosts as List<String>,
      allowedBotIds: allowedBotIds == const $CopyWithPlaceholder()
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SecretCopyWith on Secret {
  /// Returns a callable class that can be used as follows: `instanceOfSecret.copyWith(...)` or like so:`instanceOfSecret.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretCWProxy get copyWith => _$SecretCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Secret _$SecretFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Secret',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'name',
        'allowed_hosts',
        'allowed_bot_ids',
        'created_at',
      ],
    );
    final val = Secret(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      allowedHosts: $checkedConvert(
        'allowed_hosts',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      allowedBotIds: $checkedConvert(
        'allowed_bot_ids',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
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
    'allowedHosts': 'allowed_hosts',
    'allowedBotIds': 'allowed_bot_ids',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$SecretToJson(Secret instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'name': instance.name,
  'allowed_hosts': instance.allowedHosts,
  'allowed_bot_ids': instance.allowedBotIds,
  'created_at': instance.createdAt.toIso8601String(),
};
