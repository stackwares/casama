// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_command_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageCommandListCWProxy {
  PageCommandList items(List<PageCommand> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageCommandList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageCommandList(...).copyWith(id: 12, name: "My name")
  /// ```
  PageCommandList call({List<PageCommand> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageCommandList.copyWith(...)` or call `instanceOfPageCommandList.copyWith.fieldName(value)` for a single field.
class _$PageCommandListCWProxyImpl implements _$PageCommandListCWProxy {
  const _$PageCommandListCWProxyImpl(this._value);

  final PageCommandList _value;

  @override
  PageCommandList items(List<PageCommand> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageCommandList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageCommandList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageCommandList call({Object? items = const $CopyWithPlaceholder()}) {
    return PageCommandList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PageCommand>,
    );
  }
}

extension $PageCommandListCopyWith on PageCommandList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageCommandList.copyWith(...)` or `instanceOfPageCommandList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageCommandListCWProxy get copyWith => _$PageCommandListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageCommandList _$PageCommandListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PageCommandList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PageCommandList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PageCommand.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PageCommandListToJson(PageCommandList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
