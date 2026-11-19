// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_changed.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistChangedCWProxy {
  WaitlistChanged count(int count);

  WaitlistChanged skipped(List<String>? skipped);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistChanged(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistChanged(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistChanged call({int count, List<String>? skipped});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistChanged.copyWith(...)` or call `instanceOfWaitlistChanged.copyWith.fieldName(value)` for a single field.
class _$WaitlistChangedCWProxyImpl implements _$WaitlistChangedCWProxy {
  const _$WaitlistChangedCWProxyImpl(this._value);

  final WaitlistChanged _value;

  @override
  WaitlistChanged count(int count) => call(count: count);

  @override
  WaitlistChanged skipped(List<String>? skipped) => call(skipped: skipped);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistChanged(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistChanged(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistChanged call({
    Object? count = const $CopyWithPlaceholder(),
    Object? skipped = const $CopyWithPlaceholder(),
  }) {
    return WaitlistChanged(
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      skipped: skipped == const $CopyWithPlaceholder()
          ? _value.skipped
          // ignore: cast_nullable_to_non_nullable
          : skipped as List<String>?,
    );
  }
}

extension $WaitlistChangedCopyWith on WaitlistChanged {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistChanged.copyWith(...)` or `instanceOfWaitlistChanged.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistChangedCWProxy get copyWith => _$WaitlistChangedCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistChanged _$WaitlistChangedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WaitlistChanged', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['count']);
      final val = WaitlistChanged(
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        skipped: $checkedConvert(
          'skipped',
          (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$WaitlistChangedToJson(WaitlistChanged instance) =>
    <String, dynamic>{'count': instance.count, 'skipped': ?instance.skipped};
