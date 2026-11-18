// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_link_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedLinkKeyCWProxy {
  CreatedLinkKey id(String id);

  CreatedLinkKey instanceName(String instanceName);

  CreatedLinkKey keyHint(String keyHint);

  CreatedLinkKey scopes(List<String> scopes);

  CreatedLinkKey lastUsedAt(DateTime? lastUsedAt);

  CreatedLinkKey createdAt(DateTime createdAt);

  CreatedLinkKey key(String key);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedLinkKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedLinkKey(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedLinkKey call({
    String id,
    String instanceName,
    String keyHint,
    List<String> scopes,
    DateTime? lastUsedAt,
    DateTime createdAt,
    String key,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedLinkKey.copyWith(...)` or call `instanceOfCreatedLinkKey.copyWith.fieldName(value)` for a single field.
class _$CreatedLinkKeyCWProxyImpl implements _$CreatedLinkKeyCWProxy {
  const _$CreatedLinkKeyCWProxyImpl(this._value);

  final CreatedLinkKey _value;

  @override
  CreatedLinkKey id(String id) => call(id: id);

  @override
  CreatedLinkKey instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  CreatedLinkKey keyHint(String keyHint) => call(keyHint: keyHint);

  @override
  CreatedLinkKey scopes(List<String> scopes) => call(scopes: scopes);

  @override
  CreatedLinkKey lastUsedAt(DateTime? lastUsedAt) =>
      call(lastUsedAt: lastUsedAt);

  @override
  CreatedLinkKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedLinkKey key(String key) => call(key: key);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedLinkKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedLinkKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedLinkKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? keyHint = const $CopyWithPlaceholder(),
    Object? scopes = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
  }) {
    return CreatedLinkKey(
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
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
    );
  }
}

extension $CreatedLinkKeyCopyWith on CreatedLinkKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedLinkKey.copyWith(...)` or `instanceOfCreatedLinkKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedLinkKeyCWProxy get copyWith => _$CreatedLinkKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedLinkKey _$CreatedLinkKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedLinkKey',
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
            'key',
          ],
        );
        final val = CreatedLinkKey(
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
          key: $checkedConvert('key', (v) => v as String),
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

Map<String, dynamic> _$CreatedLinkKeyToJson(CreatedLinkKey instance) =>
    <String, dynamic>{
      'id': instance.id,
      'instance_name': instance.instanceName,
      'key_hint': instance.keyHint,
      'scopes': instance.scopes,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'key': instance.key,
    };
