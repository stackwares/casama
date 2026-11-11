// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_mcp_integration_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalMcpIntegrationListCWProxy {
  LocalMcpIntegrationList items(List<Integration> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpIntegrationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpIntegrationList(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalMcpIntegrationList call({List<Integration> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalMcpIntegrationList.copyWith(...)` or call `instanceOfLocalMcpIntegrationList.copyWith.fieldName(value)` for a single field.
class _$LocalMcpIntegrationListCWProxyImpl
    implements _$LocalMcpIntegrationListCWProxy {
  const _$LocalMcpIntegrationListCWProxyImpl(this._value);

  final LocalMcpIntegrationList _value;

  @override
  LocalMcpIntegrationList items(List<Integration> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpIntegrationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpIntegrationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalMcpIntegrationList call({Object? items = const $CopyWithPlaceholder()}) {
    return LocalMcpIntegrationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Integration>,
    );
  }
}

extension $LocalMcpIntegrationListCopyWith on LocalMcpIntegrationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalMcpIntegrationList.copyWith(...)` or `instanceOfLocalMcpIntegrationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalMcpIntegrationListCWProxy get copyWith =>
      _$LocalMcpIntegrationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalMcpIntegrationList _$LocalMcpIntegrationListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LocalMcpIntegrationList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = LocalMcpIntegrationList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => Integration.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$LocalMcpIntegrationListToJson(
  LocalMcpIntegrationList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
