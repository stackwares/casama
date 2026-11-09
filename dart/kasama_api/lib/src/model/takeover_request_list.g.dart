// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_request_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverRequestListCWProxy {
  TakeoverRequestList items(List<TakeoverRequest> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverRequestList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverRequestList(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverRequestList call({List<TakeoverRequest> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTakeoverRequestList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTakeoverRequestList.copyWith.fieldName(...)`
class _$TakeoverRequestListCWProxyImpl implements _$TakeoverRequestListCWProxy {
  const _$TakeoverRequestListCWProxyImpl(this._value);

  final TakeoverRequestList _value;

  @override
  TakeoverRequestList items(List<TakeoverRequest> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverRequestList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverRequestList(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverRequestList call({Object? items = const $CopyWithPlaceholder()}) {
    return TakeoverRequestList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TakeoverRequest>,
    );
  }
}

extension $TakeoverRequestListCopyWith on TakeoverRequestList {
  /// Returns a callable class that can be used as follows: `instanceOfTakeoverRequestList.copyWith(...)` or like so:`instanceOfTakeoverRequestList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverRequestListCWProxy get copyWith =>
      _$TakeoverRequestListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverRequestList _$TakeoverRequestListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TakeoverRequestList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = TakeoverRequestList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => TakeoverRequest.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TakeoverRequestListToJson(
  TakeoverRequestList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
