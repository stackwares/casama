// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_mcp_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedMcpKeyCWProxy {
  CreatedMcpKey id(String id);

  CreatedMcpKey name(String name);

  CreatedMcpKey hint(String hint);

  CreatedMcpKey lastUsedAt(DateTime? lastUsedAt);

  CreatedMcpKey createdAt(DateTime createdAt);

  CreatedMcpKey key(String key);

  CreatedMcpKey mcpUrl(String mcpUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedMcpKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedMcpKey(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedMcpKey call({
    String id,
    String name,
    String hint,
    DateTime? lastUsedAt,
    DateTime createdAt,
    String key,
    String mcpUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedMcpKey.copyWith(...)` or call `instanceOfCreatedMcpKey.copyWith.fieldName(value)` for a single field.
class _$CreatedMcpKeyCWProxyImpl implements _$CreatedMcpKeyCWProxy {
  const _$CreatedMcpKeyCWProxyImpl(this._value);

  final CreatedMcpKey _value;

  @override
  CreatedMcpKey id(String id) => call(id: id);

  @override
  CreatedMcpKey name(String name) => call(name: name);

  @override
  CreatedMcpKey hint(String hint) => call(hint: hint);

  @override
  CreatedMcpKey lastUsedAt(DateTime? lastUsedAt) =>
      call(lastUsedAt: lastUsedAt);

  @override
  CreatedMcpKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedMcpKey key(String key) => call(key: key);

  @override
  CreatedMcpKey mcpUrl(String mcpUrl) => call(mcpUrl: mcpUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedMcpKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedMcpKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedMcpKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? hint = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? key = const $CopyWithPlaceholder(),
    Object? mcpUrl = const $CopyWithPlaceholder(),
  }) {
    return CreatedMcpKey(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      hint: hint == const $CopyWithPlaceholder() || hint == null
          ? _value.hint
          // ignore: cast_nullable_to_non_nullable
          : hint as String,
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
      mcpUrl: mcpUrl == const $CopyWithPlaceholder() || mcpUrl == null
          ? _value.mcpUrl
          // ignore: cast_nullable_to_non_nullable
          : mcpUrl as String,
    );
  }
}

extension $CreatedMcpKeyCopyWith on CreatedMcpKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedMcpKey.copyWith(...)` or `instanceOfCreatedMcpKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedMcpKeyCWProxy get copyWith => _$CreatedMcpKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedMcpKey _$CreatedMcpKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CreatedMcpKey',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'name',
            'hint',
            'last_used_at',
            'created_at',
            'key',
            'mcp_url',
          ],
        );
        final val = CreatedMcpKey(
          id: $checkedConvert('id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          hint: $checkedConvert('hint', (v) => v as String),
          lastUsedAt: $checkedConvert(
            'last_used_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
          key: $checkedConvert('key', (v) => v as String),
          mcpUrl: $checkedConvert('mcp_url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'lastUsedAt': 'last_used_at',
        'createdAt': 'created_at',
        'mcpUrl': 'mcp_url',
      },
    );

Map<String, dynamic> _$CreatedMcpKeyToJson(CreatedMcpKey instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'hint': instance.hint,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'key': instance.key,
      'mcp_url': instance.mcpUrl,
    };
