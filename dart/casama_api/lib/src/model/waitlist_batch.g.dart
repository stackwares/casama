// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_batch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WaitlistBatchCWProxy {
  WaitlistBatch day(String day);

  WaitlistBatch ranAt(DateTime ranAt);

  WaitlistBatch admitted(int admitted);

  WaitlistBatch skippedReason(String? skippedReason);

  WaitlistBatch detail(String? detail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistBatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistBatch(...).copyWith(id: 12, name: "My name")
  /// ```
  WaitlistBatch call({
    String day,
    DateTime ranAt,
    int admitted,
    String? skippedReason,
    String? detail,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWaitlistBatch.copyWith(...)` or call `instanceOfWaitlistBatch.copyWith.fieldName(value)` for a single field.
class _$WaitlistBatchCWProxyImpl implements _$WaitlistBatchCWProxy {
  const _$WaitlistBatchCWProxyImpl(this._value);

  final WaitlistBatch _value;

  @override
  WaitlistBatch day(String day) => call(day: day);

  @override
  WaitlistBatch ranAt(DateTime ranAt) => call(ranAt: ranAt);

  @override
  WaitlistBatch admitted(int admitted) => call(admitted: admitted);

  @override
  WaitlistBatch skippedReason(String? skippedReason) =>
      call(skippedReason: skippedReason);

  @override
  WaitlistBatch detail(String? detail) => call(detail: detail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WaitlistBatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WaitlistBatch(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WaitlistBatch call({
    Object? day = const $CopyWithPlaceholder(),
    Object? ranAt = const $CopyWithPlaceholder(),
    Object? admitted = const $CopyWithPlaceholder(),
    Object? skippedReason = const $CopyWithPlaceholder(),
    Object? detail = const $CopyWithPlaceholder(),
  }) {
    return WaitlistBatch(
      day: day == const $CopyWithPlaceholder() || day == null
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as String,
      ranAt: ranAt == const $CopyWithPlaceholder() || ranAt == null
          ? _value.ranAt
          // ignore: cast_nullable_to_non_nullable
          : ranAt as DateTime,
      admitted: admitted == const $CopyWithPlaceholder() || admitted == null
          ? _value.admitted
          // ignore: cast_nullable_to_non_nullable
          : admitted as int,
      skippedReason: skippedReason == const $CopyWithPlaceholder()
          ? _value.skippedReason
          // ignore: cast_nullable_to_non_nullable
          : skippedReason as String?,
      detail: detail == const $CopyWithPlaceholder()
          ? _value.detail
          // ignore: cast_nullable_to_non_nullable
          : detail as String?,
    );
  }
}

extension $WaitlistBatchCopyWith on WaitlistBatch {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWaitlistBatch.copyWith(...)` or `instanceOfWaitlistBatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WaitlistBatchCWProxy get copyWith => _$WaitlistBatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WaitlistBatch _$WaitlistBatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WaitlistBatch',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'day',
            'ran_at',
            'admitted',
            'skipped_reason',
            'detail',
          ],
        );
        final val = WaitlistBatch(
          day: $checkedConvert('day', (v) => v as String),
          ranAt: $checkedConvert('ran_at', (v) => DateTime.parse(v as String)),
          admitted: $checkedConvert('admitted', (v) => (v as num).toInt()),
          skippedReason: $checkedConvert('skipped_reason', (v) => v as String?),
          detail: $checkedConvert('detail', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'ranAt': 'ran_at', 'skippedReason': 'skipped_reason'},
    );

Map<String, dynamic> _$WaitlistBatchToJson(WaitlistBatch instance) =>
    <String, dynamic>{
      'day': instance.day,
      'ran_at': instance.ranAt.toIso8601String(),
      'admitted': instance.admitted,
      'skipped_reason': instance.skippedReason,
      'detail': instance.detail,
    };
