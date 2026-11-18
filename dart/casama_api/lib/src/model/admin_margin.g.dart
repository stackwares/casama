// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_margin.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMarginCWProxy {
  AdminMargin days(int days);

  AdminMargin chargedUsd(num chargedUsd);

  AdminMargin chargedTrackedUsd(num chargedTrackedUsd);

  AdminMargin upstreamUsd(num upstreamUsd);

  AdminMargin byDay(List<AdminMarginByDayInner> byDay);

  AdminMargin byKind(List<AdminMarginByKindInner> byKind);

  AdminMargin topOrgs(List<AdminMarginTopOrgsInner> topOrgs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMargin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMargin(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMargin call({
    int days,
    num chargedUsd,
    num chargedTrackedUsd,
    num upstreamUsd,
    List<AdminMarginByDayInner> byDay,
    List<AdminMarginByKindInner> byKind,
    List<AdminMarginTopOrgsInner> topOrgs,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMargin.copyWith(...)` or call `instanceOfAdminMargin.copyWith.fieldName(value)` for a single field.
class _$AdminMarginCWProxyImpl implements _$AdminMarginCWProxy {
  const _$AdminMarginCWProxyImpl(this._value);

  final AdminMargin _value;

  @override
  AdminMargin days(int days) => call(days: days);

  @override
  AdminMargin chargedUsd(num chargedUsd) => call(chargedUsd: chargedUsd);

  @override
  AdminMargin chargedTrackedUsd(num chargedTrackedUsd) =>
      call(chargedTrackedUsd: chargedTrackedUsd);

  @override
  AdminMargin upstreamUsd(num upstreamUsd) => call(upstreamUsd: upstreamUsd);

  @override
  AdminMargin byDay(List<AdminMarginByDayInner> byDay) => call(byDay: byDay);

  @override
  AdminMargin byKind(List<AdminMarginByKindInner> byKind) =>
      call(byKind: byKind);

  @override
  AdminMargin topOrgs(List<AdminMarginTopOrgsInner> topOrgs) =>
      call(topOrgs: topOrgs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMargin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMargin(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMargin call({
    Object? days = const $CopyWithPlaceholder(),
    Object? chargedUsd = const $CopyWithPlaceholder(),
    Object? chargedTrackedUsd = const $CopyWithPlaceholder(),
    Object? upstreamUsd = const $CopyWithPlaceholder(),
    Object? byDay = const $CopyWithPlaceholder(),
    Object? byKind = const $CopyWithPlaceholder(),
    Object? topOrgs = const $CopyWithPlaceholder(),
  }) {
    return AdminMargin(
      days: days == const $CopyWithPlaceholder() || days == null
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as int,
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
      byDay: byDay == const $CopyWithPlaceholder() || byDay == null
          ? _value.byDay
          // ignore: cast_nullable_to_non_nullable
          : byDay as List<AdminMarginByDayInner>,
      byKind: byKind == const $CopyWithPlaceholder() || byKind == null
          ? _value.byKind
          // ignore: cast_nullable_to_non_nullable
          : byKind as List<AdminMarginByKindInner>,
      topOrgs: topOrgs == const $CopyWithPlaceholder() || topOrgs == null
          ? _value.topOrgs
          // ignore: cast_nullable_to_non_nullable
          : topOrgs as List<AdminMarginTopOrgsInner>,
    );
  }
}

extension $AdminMarginCopyWith on AdminMargin {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMargin.copyWith(...)` or `instanceOfAdminMargin.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMarginCWProxy get copyWith => _$AdminMarginCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMargin _$AdminMarginFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminMargin',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'days',
        'charged_usd',
        'charged_tracked_usd',
        'upstream_usd',
        'by_day',
        'by_kind',
        'top_orgs',
      ],
    );
    final val = AdminMargin(
      days: $checkedConvert('days', (v) => (v as num).toInt()),
      chargedUsd: $checkedConvert('charged_usd', (v) => v as num),
      chargedTrackedUsd: $checkedConvert(
        'charged_tracked_usd',
        (v) => v as num,
      ),
      upstreamUsd: $checkedConvert('upstream_usd', (v) => v as num),
      byDay: $checkedConvert(
        'by_day',
        (v) => (v as List<dynamic>)
            .map(
              (e) => AdminMarginByDayInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      byKind: $checkedConvert(
        'by_kind',
        (v) => (v as List<dynamic>)
            .map(
              (e) => AdminMarginByKindInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      topOrgs: $checkedConvert(
        'top_orgs',
        (v) => (v as List<dynamic>)
            .map(
              (e) =>
                  AdminMarginTopOrgsInner.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'chargedUsd': 'charged_usd',
    'chargedTrackedUsd': 'charged_tracked_usd',
    'upstreamUsd': 'upstream_usd',
    'byDay': 'by_day',
    'byKind': 'by_kind',
    'topOrgs': 'top_orgs',
  },
);

Map<String, dynamic> _$AdminMarginToJson(AdminMargin instance) =>
    <String, dynamic>{
      'days': instance.days,
      'charged_usd': instance.chargedUsd,
      'charged_tracked_usd': instance.chargedTrackedUsd,
      'upstream_usd': instance.upstreamUsd,
      'by_day': instance.byDay.map((e) => e.toJson()).toList(),
      'by_kind': instance.byKind.map((e) => e.toJson()).toList(),
      'top_orgs': instance.topOrgs.map((e) => e.toJson()).toList(),
    };
