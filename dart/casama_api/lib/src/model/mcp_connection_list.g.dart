// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_connection_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpConnectionListCWProxy {
  McpConnectionList items(List<McpConnection> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConnectionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConnectionList(...).copyWith(id: 12, name: "My name")
  /// ```
  McpConnectionList call({List<McpConnection> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpConnectionList.copyWith(...)` or call `instanceOfMcpConnectionList.copyWith.fieldName(value)` for a single field.
class _$McpConnectionListCWProxyImpl implements _$McpConnectionListCWProxy {
  const _$McpConnectionListCWProxyImpl(this._value);

  final McpConnectionList _value;

  @override
  McpConnectionList items(List<McpConnection> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpConnectionList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpConnectionList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpConnectionList call({Object? items = const $CopyWithPlaceholder()}) {
    return McpConnectionList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<McpConnection>,
    );
  }
}

extension $McpConnectionListCopyWith on McpConnectionList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpConnectionList.copyWith(...)` or `instanceOfMcpConnectionList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpConnectionListCWProxy get copyWith =>
      _$McpConnectionListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpConnectionList _$McpConnectionListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('McpConnectionList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = McpConnectionList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => McpConnection.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$McpConnectionListToJson(McpConnectionList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
