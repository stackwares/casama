// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerListCWProxy {
  ComputerList items(List<Computer> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerList(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerList call({List<Computer> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComputerList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComputerList.copyWith.fieldName(...)`
class _$ComputerListCWProxyImpl implements _$ComputerListCWProxy {
  const _$ComputerListCWProxyImpl(this._value);

  final ComputerList _value;

  @override
  ComputerList items(List<Computer> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerList(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerList call({Object? items = const $CopyWithPlaceholder()}) {
    return ComputerList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Computer>,
    );
  }
}

extension $ComputerListCopyWith on ComputerList {
  /// Returns a callable class that can be used as follows: `instanceOfComputerList.copyWith(...)` or like so:`instanceOfComputerList.copyWith.fieldName(...)`.
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
