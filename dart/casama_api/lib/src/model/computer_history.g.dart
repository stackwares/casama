// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_history.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerHistoryCWProxy {
  ComputerHistory items(List<ComputerHistoryEntry> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerHistory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerHistory(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerHistory call({List<ComputerHistoryEntry> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerHistory.copyWith(...)` or call `instanceOfComputerHistory.copyWith.fieldName(value)` for a single field.
class _$ComputerHistoryCWProxyImpl implements _$ComputerHistoryCWProxy {
  const _$ComputerHistoryCWProxyImpl(this._value);

  final ComputerHistory _value;

  @override
  ComputerHistory items(List<ComputerHistoryEntry> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerHistory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerHistory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerHistory call({Object? items = const $CopyWithPlaceholder()}) {
    return ComputerHistory(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ComputerHistoryEntry>,
    );
  }
}

extension $ComputerHistoryCopyWith on ComputerHistory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerHistory.copyWith(...)` or `instanceOfComputerHistory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerHistoryCWProxy get copyWith => _$ComputerHistoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerHistory _$ComputerHistoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerHistory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ComputerHistory(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => ComputerHistoryEntry.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ComputerHistoryToJson(ComputerHistory instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
