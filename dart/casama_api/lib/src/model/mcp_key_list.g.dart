// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_key_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpKeyListCWProxy {
  McpKeyList items(List<McpKey> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  McpKeyList call({List<McpKey> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpKeyList.copyWith(...)` or call `instanceOfMcpKeyList.copyWith.fieldName(value)` for a single field.
class _$McpKeyListCWProxyImpl implements _$McpKeyListCWProxy {
  const _$McpKeyListCWProxyImpl(this._value);

  final McpKeyList _value;

  @override
  McpKeyList items(List<McpKey> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpKeyList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpKeyList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpKeyList call({Object? items = const $CopyWithPlaceholder()}) {
    return McpKeyList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<McpKey>,
    );
  }
}

extension $McpKeyListCopyWith on McpKeyList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpKeyList.copyWith(...)` or `instanceOfMcpKeyList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpKeyListCWProxy get copyWith => _$McpKeyListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpKeyList _$McpKeyListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('McpKeyList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = McpKeyList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => McpKey.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$McpKeyListToJson(McpKeyList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
