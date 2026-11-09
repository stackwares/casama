// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoutineListCWProxy {
  RoutineList items(List<Routine> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RoutineList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RoutineList(...).copyWith(id: 12, name: "My name")
  /// ````
  RoutineList call({List<Routine> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRoutineList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRoutineList.copyWith.fieldName(...)`
class _$RoutineListCWProxyImpl implements _$RoutineListCWProxy {
  const _$RoutineListCWProxyImpl(this._value);

  final RoutineList _value;

  @override
  RoutineList items(List<Routine> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RoutineList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RoutineList(...).copyWith(id: 12, name: "My name")
  /// ````
  RoutineList call({Object? items = const $CopyWithPlaceholder()}) {
    return RoutineList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Routine>,
    );
  }
}

extension $RoutineListCopyWith on RoutineList {
  /// Returns a callable class that can be used as follows: `instanceOfRoutineList.copyWith(...)` or like so:`instanceOfRoutineList.copyWith.fieldName(...)`.
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
