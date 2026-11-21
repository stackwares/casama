// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_fares.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchFaresCWProxy {
  WatchFares below(num? below);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchFares(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchFares(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchFares call({num? below});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchFares.copyWith(...)` or call `instanceOfWatchFares.copyWith.fieldName(value)` for a single field.
class _$WatchFaresCWProxyImpl implements _$WatchFaresCWProxy {
  const _$WatchFaresCWProxyImpl(this._value);

  final WatchFares _value;

  @override
  WatchFares below(num? below) => call(below: below);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchFares(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchFares(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchFares call({Object? below = const $CopyWithPlaceholder()}) {
    return WatchFares(
      below: below == const $CopyWithPlaceholder()
          ? _value.below
          // ignore: cast_nullable_to_non_nullable
          : below as num?,
    );
  }
}

extension $WatchFaresCopyWith on WatchFares {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchFares.copyWith(...)` or `instanceOfWatchFares.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchFaresCWProxy get copyWith => _$WatchFaresCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchFares _$WatchFaresFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WatchFares', json, ($checkedConvert) {
      final val = WatchFares(below: $checkedConvert('below', (v) => v as num?));
      return val;
    });

Map<String, dynamic> _$WatchFaresToJson(WatchFares instance) =>
    <String, dynamic>{'below': ?instance.below};
