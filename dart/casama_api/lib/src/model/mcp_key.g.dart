// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpKeyCWProxy {
  McpKey id(String id);

  McpKey name(String name);

  McpKey hint(String hint);

  McpKey lastUsedAt(DateTime? lastUsedAt);

  McpKey createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpKey(...).copyWith(id: 12, name: "My name")
  /// ```
  McpKey call({
    String id,
    String name,
    String hint,
    DateTime? lastUsedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpKey.copyWith(...)` or call `instanceOfMcpKey.copyWith.fieldName(value)` for a single field.
class _$McpKeyCWProxyImpl implements _$McpKeyCWProxy {
  const _$McpKeyCWProxyImpl(this._value);

  final McpKey _value;

  @override
  McpKey id(String id) => call(id: id);

  @override
  McpKey name(String name) => call(name: name);

  @override
  McpKey hint(String hint) => call(hint: hint);

  @override
  McpKey lastUsedAt(DateTime? lastUsedAt) => call(lastUsedAt: lastUsedAt);

  @override
  McpKey createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpKey call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? hint = const $CopyWithPlaceholder(),
    Object? lastUsedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return McpKey(
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
    );
  }
}

extension $McpKeyCopyWith on McpKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpKey.copyWith(...)` or `instanceOfMcpKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpKeyCWProxy get copyWith => _$McpKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpKey _$McpKeyFromJson(Map<String, dynamic> json) => $checkedCreate(
  'McpKey',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['id', 'name', 'hint', 'last_used_at', 'created_at'],
    );
    final val = McpKey(
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
    );
    return val;
  },
  fieldKeyMap: const {'lastUsedAt': 'last_used_at', 'createdAt': 'created_at'},
);

Map<String, dynamic> _$McpKeyToJson(McpKey instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'hint': instance.hint,
  'last_used_at': instance.lastUsedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
};
