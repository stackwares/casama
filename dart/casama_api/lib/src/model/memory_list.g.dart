// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryListCWProxy {
  MemoryList items(List<Memory> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryList(...).copyWith(id: 12, name: "My name")
  /// ```
  MemoryList call({List<Memory> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemoryList.copyWith(...)` or call `instanceOfMemoryList.copyWith.fieldName(value)` for a single field.
class _$MemoryListCWProxyImpl implements _$MemoryListCWProxy {
  const _$MemoryListCWProxyImpl(this._value);

  final MemoryList _value;

  @override
  MemoryList items(List<Memory> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MemoryList call({Object? items = const $CopyWithPlaceholder()}) {
    return MemoryList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Memory>,
    );
  }
}

extension $MemoryListCopyWith on MemoryList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemoryList.copyWith(...)` or `instanceOfMemoryList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemoryListCWProxy get copyWith => _$MemoryListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryList _$MemoryListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemoryList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = MemoryList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Memory.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MemoryListToJson(MemoryList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
