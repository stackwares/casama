// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_request_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverRequestListCWProxy {
  TakeoverRequestList items(List<TakeoverRequest> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  TakeoverRequestList call({List<TakeoverRequest> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeoverRequestList.copyWith(...)` or call `instanceOfTakeoverRequestList.copyWith.fieldName(value)` for a single field.
class _$TakeoverRequestListCWProxyImpl implements _$TakeoverRequestListCWProxy {
  const _$TakeoverRequestListCWProxyImpl(this._value);

  final TakeoverRequestList _value;

  @override
  TakeoverRequestList items(List<TakeoverRequest> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TakeoverRequestList call({Object? items = const $CopyWithPlaceholder()}) {
    return TakeoverRequestList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TakeoverRequest>,
    );
  }
}

extension $TakeoverRequestListCopyWith on TakeoverRequestList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeoverRequestList.copyWith(...)` or `instanceOfTakeoverRequestList.copyWith.fieldName(...)`.
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
