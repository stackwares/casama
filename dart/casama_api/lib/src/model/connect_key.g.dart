// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ConnectKeyCWProxy {
  ConnectKey id(String id);

  ConnectKey instanceName(String instanceName);

  ConnectKey keyHint(String keyHint);

  ConnectKey scopes(List<String> scopes);

  ConnectKey lastUsedAt(DateTime? lastUsedAt);

  ConnectKey createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectKey(...).copyWith(id: 12, name: "My name")
  /// ```
  ConnectKey call({
    String id,
    String instanceName,
    String keyHint,
    List<String> scopes,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfConnectKey.copyWith(...)` or call `instanceOfConnectKey.copyWith.fieldName(value)` for a single field.
class _$ConnectKeyCWProxyImpl implements _$ConnectKeyCWProxy {
  const _$ConnectKeyCWProxyImpl(this._value);

  final ConnectKey _value;

  @override
  ConnectKey id(String id) => call(id: id);

  @override
  ConnectKey instanceName(String instanceName) =>
      call(instanceName: instanceName);

  @override
  ConnectKey keyHint(String keyHint) => call(keyHint: keyHint);

  @override
  ConnectKey scopes(List<String> scopes) => call(scopes: scopes);

  @override
  ConnectKey lastUsedAt(DateTime? lastUsedAt) => call(lastUsedAt: lastUsedAt);

  @override
  ConnectKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ConnectKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ConnectKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ConnectKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? instanceName = const $CopyWithPlaceholder(),
    Object? keyHint = const $CopyWithPlaceholder(),
    Object? scopes = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ConnectKey(
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

extension $ConnectKeyCopyWith on ConnectKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfConnectKey.copyWith(...)` or `instanceOfConnectKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ConnectKeyCWProxy get copyWith => _$ConnectKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConnectKey _$ConnectKeyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ConnectKey',
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
    final val = ConnectKey(
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

Map<String, dynamic> _$ConnectKeyToJson(ConnectKey instance) =>
    <String, dynamic>{
      'id': instance.id,
      'instance_name': instance.instanceName,
      'key_hint': instance.keyHint,
      'scopes': instance.scopes,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
