// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_credits.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceCreditsCWProxy {
  GlanceCredits billing(bool billing);

  GlanceCredits unlimited(bool unlimited);

  GlanceCredits plan(String? plan);

  GlanceCredits usedShare(num? usedShare);

  GlanceCredits leftUsd(num? leftUsd);

  GlanceCredits todayUsd(num todayUsd);

  GlanceCredits monthUsd(num monthUsd);

  GlanceCredits dailyCapUsd(num? dailyCapUsd);

  GlanceCredits dailyUsedUsd(num? dailyUsedUsd);

  GlanceCredits resetsAt(DateTime? resetsAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceCredits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceCredits(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceCredits call({
    bool billing,
    bool unlimited,
    String? plan,
    num? usedShare,
    num? leftUsd,
    num todayUsd,
    num monthUsd,
    num? dailyCapUsd,
    num? dailyUsedUsd,
    DateTime? resetsAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceCredits.copyWith(...)` or call `instanceOfGlanceCredits.copyWith.fieldName(value)` for a single field.
class _$GlanceCreditsCWProxyImpl implements _$GlanceCreditsCWProxy {
  const _$GlanceCreditsCWProxyImpl(this._value);

  final GlanceCredits _value;

  @override
  GlanceCredits billing(bool billing) => call(billing: billing);

  @override
  GlanceCredits unlimited(bool unlimited) => call(unlimited: unlimited);

  @override
  GlanceCredits plan(String? plan) => call(plan: plan);

  @override
  GlanceCredits usedShare(num? usedShare) => call(usedShare: usedShare);

  @override
  GlanceCredits leftUsd(num? leftUsd) => call(leftUsd: leftUsd);

  @override
  GlanceCredits todayUsd(num todayUsd) => call(todayUsd: todayUsd);

  @override
  GlanceCredits monthUsd(num monthUsd) => call(monthUsd: monthUsd);

  @override
  GlanceCredits dailyCapUsd(num? dailyCapUsd) => call(dailyCapUsd: dailyCapUsd);

  @override
  GlanceCredits dailyUsedUsd(num? dailyUsedUsd) =>
      call(dailyUsedUsd: dailyUsedUsd);

  @override
  GlanceCredits resetsAt(DateTime? resetsAt) => call(resetsAt: resetsAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceCredits(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceCredits(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceCredits call({
    Object? billing = const $CopyWithPlaceholder(),
    Object? unlimited = const $CopyWithPlaceholder(),
    Object? plan = const $CopyWithPlaceholder(),
    Object? usedShare = const $CopyWithPlaceholder(),
    Object? leftUsd = const $CopyWithPlaceholder(),
    Object? todayUsd = const $CopyWithPlaceholder(),
    Object? monthUsd = const $CopyWithPlaceholder(),
    Object? dailyCapUsd = const $CopyWithPlaceholder(),
    Object? dailyUsedUsd = const $CopyWithPlaceholder(),
    Object? resetsAt = const $CopyWithPlaceholder(),
  }) {
    return GlanceCredits(
      billing: billing == const $CopyWithPlaceholder() || billing == null
          ? _value.billing
          // ignore: cast_nullable_to_non_nullable
          : billing as bool,
      unlimited: unlimited == const $CopyWithPlaceholder() || unlimited == null
          ? _value.unlimited
          // ignore: cast_nullable_to_non_nullable
          : unlimited as bool,
      plan: plan == const $CopyWithPlaceholder()
          ? _value.plan
          // ignore: cast_nullable_to_non_nullable
          : plan as String?,
      usedShare: usedShare == const $CopyWithPlaceholder()
          ? _value.usedShare
          // ignore: cast_nullable_to_non_nullable
          : usedShare as num?,
      leftUsd: leftUsd == const $CopyWithPlaceholder()
          ? _value.leftUsd
          // ignore: cast_nullable_to_non_nullable
          : leftUsd as num?,
      todayUsd: todayUsd == const $CopyWithPlaceholder() || todayUsd == null
          ? _value.todayUsd
          // ignore: cast_nullable_to_non_nullable
          : todayUsd as num,
      monthUsd: monthUsd == const $CopyWithPlaceholder() || monthUsd == null
          ? _value.monthUsd
          // ignore: cast_nullable_to_non_nullable
          : monthUsd as num,
      dailyCapUsd: dailyCapUsd == const $CopyWithPlaceholder()
          ? _value.dailyCapUsd
          // ignore: cast_nullable_to_non_nullable
          : dailyCapUsd as num?,
      dailyUsedUsd: dailyUsedUsd == const $CopyWithPlaceholder()
          ? _value.dailyUsedUsd
          // ignore: cast_nullable_to_non_nullable
          : dailyUsedUsd as num?,
      resetsAt: resetsAt == const $CopyWithPlaceholder()
          ? _value.resetsAt
          // ignore: cast_nullable_to_non_nullable
          : resetsAt as DateTime?,
    );
  }
}

extension $GlanceCreditsCopyWith on GlanceCredits {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceCredits.copyWith(...)` or `instanceOfGlanceCredits.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceCreditsCWProxy get copyWith => _$GlanceCreditsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceCredits _$GlanceCreditsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GlanceCredits',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'billing',
            'unlimited',
            'plan',
            'used_share',
            'left_usd',
            'today_usd',
            'month_usd',
            'daily_cap_usd',
            'daily_used_usd',
            'resets_at',
          ],
        );
        final val = GlanceCredits(
          billing: $checkedConvert('billing', (v) => v as bool),
          unlimited: $checkedConvert('unlimited', (v) => v as bool),
          plan: $checkedConvert('plan', (v) => v as String?),
          usedShare: $checkedConvert('used_share', (v) => v as num?),
          leftUsd: $checkedConvert('left_usd', (v) => v as num?),
          todayUsd: $checkedConvert('today_usd', (v) => v as num),
          monthUsd: $checkedConvert('month_usd', (v) => v as num),
          dailyCapUsd: $checkedConvert('daily_cap_usd', (v) => v as num?),
          dailyUsedUsd: $checkedConvert('daily_used_usd', (v) => v as num?),
          resetsAt: $checkedConvert(
            'resets_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'usedShare': 'used_share',
        'leftUsd': 'left_usd',
        'todayUsd': 'today_usd',
        'monthUsd': 'month_usd',
        'dailyCapUsd': 'daily_cap_usd',
        'dailyUsedUsd': 'daily_used_usd',
        'resetsAt': 'resets_at',
      },
    );

Map<String, dynamic> _$GlanceCreditsToJson(GlanceCredits instance) =>
    <String, dynamic>{
      'billing': instance.billing,
      'unlimited': instance.unlimited,
      'plan': instance.plan,
      'used_share': instance.usedShare,
      'left_usd': instance.leftUsd,
      'today_usd': instance.todayUsd,
      'month_usd': instance.monthUsd,
      'daily_cap_usd': instance.dailyCapUsd,
      'daily_used_usd': instance.dailyUsedUsd,
      'resets_at': instance.resetsAt?.toIso8601String(),
    };
