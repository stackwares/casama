// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fare_watch_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FareWatchListCWProxy {
  FareWatchList items(List<FareWatch> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FareWatchList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FareWatchList(...).copyWith(id: 12, name: "My name")
  /// ```
  FareWatchList call({List<FareWatch> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfFareWatchList.copyWith(...)` or call `instanceOfFareWatchList.copyWith.fieldName(value)` for a single field.
class _$FareWatchListCWProxyImpl implements _$FareWatchListCWProxy {
  const _$FareWatchListCWProxyImpl(this._value);

  final FareWatchList _value;

  @override
  FareWatchList items(List<FareWatch> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FareWatchList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FareWatchList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  FareWatchList call({Object? items = const $CopyWithPlaceholder()}) {
    return FareWatchList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<FareWatch>,
    );
  }
}

extension $FareWatchListCopyWith on FareWatchList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfFareWatchList.copyWith(...)` or `instanceOfFareWatchList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FareWatchListCWProxy get copyWith => _$FareWatchListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FareWatchList _$FareWatchListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FareWatchList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = FareWatchList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => FareWatch.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$FareWatchListToJson(FareWatchList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
