// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerListCWProxy {
  ComputerList items(List<Computer> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerList(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerList call({List<Computer> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerList.copyWith(...)` or call `instanceOfComputerList.copyWith.fieldName(value)` for a single field.
class _$ComputerListCWProxyImpl implements _$ComputerListCWProxy {
  const _$ComputerListCWProxyImpl(this._value);

  final ComputerList _value;

  @override
  ComputerList items(List<Computer> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerList call({Object? items = const $CopyWithPlaceholder()}) {
    return ComputerList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Computer>,
    );
  }
}

extension $ComputerListCopyWith on ComputerList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerList.copyWith(...)` or `instanceOfComputerList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerListCWProxy get copyWith => _$ComputerListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerList _$ComputerListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ComputerList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Computer.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComputerListToJson(ComputerList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
