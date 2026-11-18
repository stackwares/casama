// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_process_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerProcessListCWProxy {
  ComputerProcessList items(List<ComputerProcess> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerProcessList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerProcessList(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerProcessList call({List<ComputerProcess> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerProcessList.copyWith(...)` or call `instanceOfComputerProcessList.copyWith.fieldName(value)` for a single field.
class _$ComputerProcessListCWProxyImpl implements _$ComputerProcessListCWProxy {
  const _$ComputerProcessListCWProxyImpl(this._value);

  final ComputerProcessList _value;

  @override
  ComputerProcessList items(List<ComputerProcess> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerProcessList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerProcessList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerProcessList call({Object? items = const $CopyWithPlaceholder()}) {
    return ComputerProcessList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ComputerProcess>,
    );
  }
}

extension $ComputerProcessListCopyWith on ComputerProcessList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerProcessList.copyWith(...)` or `instanceOfComputerProcessList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerProcessListCWProxy get copyWith =>
      _$ComputerProcessListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerProcessList _$ComputerProcessListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerProcessList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ComputerProcessList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ComputerProcess.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComputerProcessListToJson(
  ComputerProcessList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
