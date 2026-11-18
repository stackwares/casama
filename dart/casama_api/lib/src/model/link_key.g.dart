// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LinkKeyCWProxy {
  LinkKey id(String id);

  LinkKey instanceName(String instanceName);

  LinkKey keyHint(String keyHint);

  LinkKey scopes(List<String> scopes);

  LinkKey lastUsedAt(DateTime? lastUsedAt);

  LinkKey createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkKey(...).copyWith(id: 12, name: "My name")
  /// ```
  LinkKey call({
    String id,
    String instanceName,
    String keyHint,
    List<String> scopes,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLinkKey.copyWith(...)` or call `instanceOfLinkKey.copyWith.fieldName(value)` for a single field.
class _$LinkKeyCWProxyImpl implements _$LinkKeyCWProxy {
  const _$LinkKeyCWProxyImpl(this._value);

  final LinkKey _value;

  @override
  LinkKey id(String id) => call(id: id);

  @override
  LinkKey instanceName(String instanceName) => call(instanceName: instanceName);

  @override
  LinkKey keyHint(String keyHint) => call(keyHint: keyHint);

  @override
  LinkKey scopes(List<String> scopes) => call(scopes: scopes);

  @override
  LinkKey lastUsedAt(DateTime? lastUsedAt) => call(lastUsedAt: lastUsedAt);

  @override
  LinkKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LinkKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LinkKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LinkKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? keyHint = const $CopyWithPlaceholder(),
    Object? scopes = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return LinkKey(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      instanceName:
          instanceName == const $CopyWithPlaceholder() || instanceName == null
          ? _value.instanceName
          // ignore: cast_nullable_to_non_nullable
          : instanceName as String,
      keyHint: keyHint == const $CopyWithPlaceholder() || keyHint == null
          ? _value.keyHint
          // ignore: cast_nullable_to_non_nullable
          : keyHint as String,
      scopes: scopes == const $CopyWithPlaceholder() || scopes == null
          ? _value.scopes
          // ignore: cast_nullable_to_non_nullable
          : scopes as List<String>,
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

extension $LinkKeyCopyWith on LinkKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLinkKey.copyWith(...)` or `instanceOfLinkKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LinkKeyCWProxy get copyWith => _$LinkKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LinkKey _$LinkKeyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'LinkKey',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'instance_name',
        'key_hint',
        'scopes',
        'last_used_at',
        'created_at',
      ],
    );
    final val = LinkKey(
      id: $checkedConvert('id', (v) => v as String),
      instanceName: $checkedConvert('instance_name', (v) => v as String),
      keyHint: $checkedConvert('key_hint', (v) => v as String),
      scopes: $checkedConvert(
        'scopes',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
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
    'instanceName': 'instance_name',
    'keyHint': 'key_hint',
    'lastUsedAt': 'last_used_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$LinkKeyToJson(LinkKey instance) => <String, dynamic>{
  'id': instance.id,
  'instance_name': instance.instanceName,
  'key_hint': instance.keyHint,
  'scopes': instance.scopes,
  'last_used_at': instance.lastUsedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
