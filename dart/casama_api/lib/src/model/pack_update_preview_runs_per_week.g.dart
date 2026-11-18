// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_update_preview_runs_per_week.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackUpdatePreviewRunsPerWeekCWProxy {
  PackUpdatePreviewRunsPerWeek from(num from);

  PackUpdatePreviewRunsPerWeek to(num to);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackUpdatePreviewRunsPerWeek(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackUpdatePreviewRunsPerWeek(...).copyWith(id: 12, name: "My name")
  /// ```
  PackUpdatePreviewRunsPerWeek call({num from, num to});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackUpdatePreviewRunsPerWeek.copyWith(...)` or call `instanceOfPackUpdatePreviewRunsPerWeek.copyWith.fieldName(value)` for a single field.
class _$PackUpdatePreviewRunsPerWeekCWProxyImpl
    implements _$PackUpdatePreviewRunsPerWeekCWProxy {
  const _$PackUpdatePreviewRunsPerWeekCWProxyImpl(this._value);

  final PackUpdatePreviewRunsPerWeek _value;

  @override
  PackUpdatePreviewRunsPerWeek from(num from) => call(from: from);

  @override
  PackUpdatePreviewRunsPerWeek to(num to) => call(to: to);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackUpdatePreviewRunsPerWeek(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackUpdatePreviewRunsPerWeek(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackUpdatePreviewRunsPerWeek call({
    Object? from = const $CopyWithPlaceholder(),
    Object? to = const $CopyWithPlaceholder(),
  }) {
    return PackUpdatePreviewRunsPerWeek(
      from: from == const $CopyWithPlaceholder() || from == null
          ? _value.from
          // ignore: cast_nullable_to_non_nullable
          : from as num,
      to: to == const $CopyWithPlaceholder() || to == null
          ? _value.to
          // ignore: cast_nullable_to_non_nullable
          : to as num,
    );
  }
}

extension $PackUpdatePreviewRunsPerWeekCopyWith
    on PackUpdatePreviewRunsPerWeek {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackUpdatePreviewRunsPerWeek.copyWith(...)` or `instanceOfPackUpdatePreviewRunsPerWeek.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackUpdatePreviewRunsPerWeekCWProxy get copyWith =>
      _$PackUpdatePreviewRunsPerWeekCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackUpdatePreviewRunsPerWeek _$PackUpdatePreviewRunsPerWeekFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackUpdatePreviewRunsPerWeek', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['from', 'to']);
  final val = PackUpdatePreviewRunsPerWeek(
    from: $checkedConvert('from', (v) => v as num),
    to: $checkedConvert('to', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$PackUpdatePreviewRunsPerWeekToJson(
  PackUpdatePreviewRunsPerWeek instance,
) => <String, dynamic>{'from': instance.from, 'to': instance.to};
