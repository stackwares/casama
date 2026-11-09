// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoutineListCWProxy {
  RoutineList items(List<Routine> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoutineList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoutineList(...).copyWith(id: 12, name: "My name")
  /// ```
  RoutineList call({List<Routine> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRoutineList.copyWith(...)` or call `instanceOfRoutineList.copyWith.fieldName(value)` for a single field.
class _$RoutineListCWProxyImpl implements _$RoutineListCWProxy {
  const _$RoutineListCWProxyImpl(this._value);

  final RoutineList _value;

  @override
  RoutineList items(List<Routine> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RoutineList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RoutineList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RoutineList call({Object? items = const $CopyWithPlaceholder()}) {
    return RoutineList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Routine>,
    );
  }
}

extension $RoutineListCopyWith on RoutineList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRoutineList.copyWith(...)` or `instanceOfRoutineList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoutineListCWProxy get copyWith => _$RoutineListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoutineList _$RoutineListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RoutineList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = RoutineList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Routine.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RoutineListToJson(RoutineList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
