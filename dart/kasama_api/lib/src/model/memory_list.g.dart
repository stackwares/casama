// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryListCWProxy {
  MemoryList items(List<Memory> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemoryList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemoryList(...).copyWith(id: 12, name: "My name")
  /// ````
  MemoryList call({List<Memory> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMemoryList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMemoryList.copyWith.fieldName(...)`
class _$MemoryListCWProxyImpl implements _$MemoryListCWProxy {
  const _$MemoryListCWProxyImpl(this._value);

  final MemoryList _value;

  @override
  MemoryList items(List<Memory> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemoryList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemoryList(...).copyWith(id: 12, name: "My name")
  /// ````
  MemoryList call({Object? items = const $CopyWithPlaceholder()}) {
    return MemoryList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Memory>,
    );
  }
}

extension $MemoryListCopyWith on MemoryList {
  /// Returns a callable class that can be used as follows: `instanceOfMemoryList.copyWith(...)` or like so:`instanceOfMemoryList.copyWith.fieldName(...)`.
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
