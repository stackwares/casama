// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_margin_by_day_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMarginByDayInnerCWProxy {
  AdminMarginByDayInner date(String date);

  AdminMarginByDayInner chargedUsd(num chargedUsd);

  AdminMarginByDayInner chargedTrackedUsd(num chargedTrackedUsd);

  AdminMarginByDayInner upstreamUsd(num upstreamUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMarginByDayInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMarginByDayInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMarginByDayInner call({
    String date,
    num chargedUsd,
    num chargedTrackedUsd,
    num upstreamUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMarginByDayInner.copyWith(...)` or call `instanceOfAdminMarginByDayInner.copyWith.fieldName(value)` for a single field.
class _$AdminMarginByDayInnerCWProxyImpl
    implements _$AdminMarginByDayInnerCWProxy {
  const _$AdminMarginByDayInnerCWProxyImpl(this._value);

  final AdminMarginByDayInner _value;

  @override
  AdminMarginByDayInner date(String date) => call(date: date);

  @override
  AdminMarginByDayInner chargedUsd(num chargedUsd) =>
      call(chargedUsd: chargedUsd);

  @override
  AdminMarginByDayInner chargedTrackedUsd(num chargedTrackedUsd) =>
      call(chargedTrackedUsd: chargedTrackedUsd);

  @override
  AdminMarginByDayInner upstreamUsd(num upstreamUsd) =>
      call(upstreamUsd: upstreamUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMarginByDayInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMarginByDayInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMarginByDayInner call({
    Object? date = const $CopyWithPlaceholder(),
    Object? chargedUsd = const $CopyWithPlaceholder(),
    Object? chargedTrackedUsd = const $CopyWithPlaceholder(),
    Object? upstreamUsd = const $CopyWithPlaceholder(),
  }) {
    return AdminMarginByDayInner(
      date: date == const $CopyWithPlaceholder() || date == null
          ? _value.date
          // ignore: cast_nullable_to_non_nullable
          : date as String,
      chargedUsd:
          chargedUsd == const $CopyWithPlaceholder() || chargedUsd == null
          ? _value.chargedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedUsd as num,
      chargedTrackedUsd:
          chargedTrackedUsd == const $CopyWithPlaceholder() ||
              chargedTrackedUsd == null
          ? _value.chargedTrackedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedTrackedUsd as num,
      upstreamUsd:
          upstreamUsd == const $CopyWithPlaceholder() || upstreamUsd == null
          ? _value.upstreamUsd
          // ignore: cast_nullable_to_non_nullable
          : upstreamUsd as num,
    );
  }
}

extension $AdminMarginByDayInnerCopyWith on AdminMarginByDayInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMarginByDayInner.copyWith(...)` or `instanceOfAdminMarginByDayInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMarginByDayInnerCWProxy get copyWith =>
      _$AdminMarginByDayInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMarginByDayInner _$AdminMarginByDayInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'AdminMarginByDayInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'date',
        'charged_usd',
        'charged_tracked_usd',
        'upstream_usd',
      ],
    );
    final val = AdminMarginByDayInner(
      date: $checkedConvert('date', (v) => v as String),
      chargedUsd: $checkedConvert('charged_usd', (v) => v as num),
      chargedTrackedUsd: $checkedConvert(
        'charged_tracked_usd',
        (v) => v as num,
      ),
      upstreamUsd: $checkedConvert('upstream_usd', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'chargedUsd': 'charged_usd',
    'chargedTrackedUsd': 'charged_tracked_usd',
    'upstreamUsd': 'upstream_usd',
  },
);

Map<String, dynamic> _$AdminMarginByDayInnerToJson(
  AdminMarginByDayInner instance,
) => <String, dynamic>{
  'date': instance.date,
  'charged_usd': instance.chargedUsd,
  'charged_tracked_usd': instance.chargedTrackedUsd,
  'upstream_usd': instance.upstreamUsd,
};
