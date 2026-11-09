// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_connect_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedConnectKeyCWProxy {
  CreatedConnectKey id(String id);

  CreatedConnectKey instanceName(String instanceName);

  CreatedConnectKey keyHint(String keyHint);

  CreatedConnectKey scopes(List<String> scopes);

  CreatedConnectKey lastUsedAt(DateTime? lastUsedAt);

  CreatedConnectKey createdAt(DateTime createdAt);

  CreatedConnectKey key(String key);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedConnectKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedConnectKey(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedConnectKey call({
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
/// Use as `instanceOfCreatedConnectKey.copyWith(...)` or call `instanceOfCreatedConnectKey.copyWith.fieldName(value)` for a single field.
class _$CreatedConnectKeyCWProxyImpl implements _$CreatedConnectKeyCWProxy {
  const _$CreatedConnectKeyCWProxyImpl(this._value);

  final CreatedConnectKey _value;

  @override
  CreatedConnectKey id(String id) => call(id: id);

  @override
  CreatedConnectKey instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  CreatedConnectKey keyHint(String keyHint) => call(keyHint: keyHint);

  @override
  CreatedConnectKey scopes(List<String> scopes) => call(scopes: scopes);

  @override
  CreatedConnectKey lastUsedAt(DateTime? lastUsedAt) =>
      call(lastUsedAt: lastUsedAt);

  @override
  CreatedConnectKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedConnectKey key(String key) => call(key: key);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedConnectKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedConnectKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedConnectKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? keyHint = const $CopyWithPlaceholder(),
    Object? scopes = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
  }) {
    return CreatedConnectKey(
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

extension $CreatedConnectKeyCopyWith on CreatedConnectKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedConnectKey.copyWith(...)` or `instanceOfCreatedConnectKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedConnectKeyCWProxy get copyWith =>
      _$CreatedConnectKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedConnectKey _$CreatedConnectKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedConnectKey',
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
        final val = CreatedConnectKey(
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

Map<String, dynamic> _$CreatedConnectKeyToJson(CreatedConnectKey instance) =>
    <String, dynamic>{
      'id': instance.id,
      'instance_name': instance.instanceName,
      'key_hint': instance.keyHint,
      'scopes': instance.scopes,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'key': instance.key,
    };
