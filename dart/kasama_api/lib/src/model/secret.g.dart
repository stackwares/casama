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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Secret(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Secret(...).copyWith(id: 12, name: "My name")
  /// ```
  Secret call({
    String id,
    String orgId,
    String name,
    List<String> allowedHosts,
    List<String>? allowedBotIds,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecret.copyWith(...)` or call `instanceOfSecret.copyWith.fieldName(value)` for a single field.
class _$SecretCWProxyImpl implements _$SecretCWProxy {
  const _$SecretCWProxyImpl(this._value);

  final Secret _value;

  @override
  Secret id(String id) => call(id: id);

  @override
  Secret orgId(String orgId) => call(orgId: orgId);

  @override
  Secret name(String name) => call(name: name);

  @override
  Secret allowedHosts(List<String> allowedHosts) =>
      call(allowedHosts: allowedHosts);

  @override
  Secret allowedBotIds(List<String>? allowedBotIds) =>
      call(allowedBotIds: allowedBotIds);

  @override
  Secret createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Secret(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Secret(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Secret call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? allowedHosts = const $CopyWithPlaceholder(),
    Object? allowedBotIds = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Secret(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      allowedHosts:
          allowedHosts == const $CopyWithPlaceholder() || allowedHosts == null
          ? _value.allowedHosts
          // ignore: cast_nullable_to_non_nullable
          : allowedHosts as List<String>,
      allowedBotIds: allowedBotIds == const $CopyWithPlaceholder()
          ? _value.allowedBotIds
          // ignore: cast_nullable_to_non_nullable
          : allowedBotIds as List<String>?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $SecretCopyWith on Secret {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecret.copyWith(...)` or `instanceOfSecret.copyWith.fieldName(...)`.
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
