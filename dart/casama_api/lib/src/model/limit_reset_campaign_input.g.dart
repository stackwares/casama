// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_reset_campaign_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LimitResetCampaignInputCWProxy {
  LimitResetCampaignInput name(String name);

  LimitResetCampaignInput message(String message);

  LimitResetCampaignInput audience(LimitResetAudience audience);

  LimitResetCampaignInput startsAt(DateTime startsAt);

  LimitResetCampaignInput expiresAt(DateTime expiresAt);

  LimitResetCampaignInput refillPercent(int? refillPercent);

  LimitResetCampaignInput resetDaily(bool? resetDaily);

  LimitResetCampaignInput resetComputer(bool? resetComputer);

  LimitResetCampaignInput maxPerUseUsd(num? maxPerUseUsd);

  LimitResetCampaignInput budgetUsd(num? budgetUsd);

  LimitResetCampaignInput notifyArrival(bool? notifyArrival);

  LimitResetCampaignInput notifyReminder(bool? notifyReminder);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetCampaignInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetCampaignInput(...).copyWith(id: 12, name: "My name")
  /// ```
  LimitResetCampaignInput call({
    String name,
    String message,
    LimitResetAudience audience,
    DateTime startsAt,
    DateTime expiresAt,
    int? refillPercent,
    bool? resetDaily,
    bool? resetComputer,
    num? maxPerUseUsd,
    num? budgetUsd,
    bool? notifyArrival,
    bool? notifyReminder,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLimitResetCampaignInput.copyWith(...)` or call `instanceOfLimitResetCampaignInput.copyWith.fieldName(value)` for a single field.
class _$LimitResetCampaignInputCWProxyImpl
    implements _$LimitResetCampaignInputCWProxy {
  const _$LimitResetCampaignInputCWProxyImpl(this._value);

  final LimitResetCampaignInput _value;

  @override
  LimitResetCampaignInput name(String name) => call(name: name);

  @override
  LimitResetCampaignInput message(String message) => call(message: message);

  @override
  LimitResetCampaignInput audience(LimitResetAudience audience) =>
      call(audience: audience);

  @override
  LimitResetCampaignInput startsAt(DateTime startsAt) =>
      call(startsAt: startsAt);

  @override
  LimitResetCampaignInput expiresAt(DateTime expiresAt) =>
      call(expiresAt: expiresAt);

  @override
  LimitResetCampaignInput refillPercent(int? refillPercent) =>
      call(refillPercent: refillPercent);

  @override
  LimitResetCampaignInput resetDaily(bool? resetDaily) =>
      call(resetDaily: resetDaily);

  @override
  LimitResetCampaignInput resetComputer(bool? resetComputer) =>
      call(resetComputer: resetComputer);

  @override
  LimitResetCampaignInput maxPerUseUsd(num? maxPerUseUsd) =>
      call(maxPerUseUsd: maxPerUseUsd);

  @override
  LimitResetCampaignInput budgetUsd(num? budgetUsd) =>
      call(budgetUsd: budgetUsd);

  @override
  LimitResetCampaignInput notifyArrival(bool? notifyArrival) =>
      call(notifyArrival: notifyArrival);

  @override
  LimitResetCampaignInput notifyReminder(bool? notifyReminder) =>
      call(notifyReminder: notifyReminder);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetCampaignInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetCampaignInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LimitResetCampaignInput call({
    Object? name = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? audience = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? refillPercent = const $CopyWithPlaceholder(),
    Object? resetDaily = const $CopyWithPlaceholder(),
    Object? resetComputer = const $CopyWithPlaceholder(),
    Object? maxPerUseUsd = const $CopyWithPlaceholder(),
    Object? budgetUsd = const $CopyWithPlaceholder(),
    Object? notifyArrival = const $CopyWithPlaceholder(),
    Object? notifyReminder = const $CopyWithPlaceholder(),
  }) {
    return LimitResetCampaignInput(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      audience: audience == const $CopyWithPlaceholder() || audience == null
          ? _value.audience
          // ignore: cast_nullable_to_non_nullable
          : audience as LimitResetAudience,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      refillPercent: refillPercent == const $CopyWithPlaceholder()
          ? _value.refillPercent
          // ignore: cast_nullable_to_non_nullable
          : refillPercent as int?,
      resetDaily: resetDaily == const $CopyWithPlaceholder()
          ? _value.resetDaily
          // ignore: cast_nullable_to_non_nullable
          : resetDaily as bool?,
      resetComputer: resetComputer == const $CopyWithPlaceholder()
          ? _value.resetComputer
          // ignore: cast_nullable_to_non_nullable
          : resetComputer as bool?,
      maxPerUseUsd: maxPerUseUsd == const $CopyWithPlaceholder()
          ? _value.maxPerUseUsd
          // ignore: cast_nullable_to_non_nullable
          : maxPerUseUsd as num?,
      budgetUsd: budgetUsd == const $CopyWithPlaceholder()
          ? _value.budgetUsd
          // ignore: cast_nullable_to_non_nullable
          : budgetUsd as num?,
      notifyArrival: notifyArrival == const $CopyWithPlaceholder()
          ? _value.notifyArrival
          // ignore: cast_nullable_to_non_nullable
          : notifyArrival as bool?,
      notifyReminder: notifyReminder == const $CopyWithPlaceholder()
          ? _value.notifyReminder
          // ignore: cast_nullable_to_non_nullable
          : notifyReminder as bool?,
    );
  }
}

extension $LimitResetCampaignInputCopyWith on LimitResetCampaignInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLimitResetCampaignInput.copyWith(...)` or `instanceOfLimitResetCampaignInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LimitResetCampaignInputCWProxy get copyWith =>
      _$LimitResetCampaignInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitResetCampaignInput _$LimitResetCampaignInputFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'LimitResetCampaignInput',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'name',
        'message',
        'audience',
        'starts_at',
        'expires_at',
      ],
    );
    final val = LimitResetCampaignInput(
      name: $checkedConvert('name', (v) => v as String),
      message: $checkedConvert('message', (v) => v as String),
      audience: $checkedConvert(
        'audience',
        (v) => LimitResetAudience.fromJson(v as Map<String, dynamic>),
      ),
      startsAt: $checkedConvert(
        'starts_at',
        (v) => DateTime.parse(v as String),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      refillPercent: $checkedConvert(
        'refill_percent',
        (v) => (v as num?)?.toInt() ?? 100,
      ),
      resetDaily: $checkedConvert('reset_daily', (v) => v as bool? ?? true),
      resetComputer: $checkedConvert(
        'reset_computer',
        (v) => v as bool? ?? false,
      ),
      maxPerUseUsd: $checkedConvert('max_per_use_usd', (v) => v as num?),
      budgetUsd: $checkedConvert('budget_usd', (v) => v as num?),
      notifyArrival: $checkedConvert(
        'notify_arrival',
        (v) => v as bool? ?? true,
      ),
      notifyReminder: $checkedConvert(
        'notify_reminder',
        (v) => v as bool? ?? true,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'startsAt': 'starts_at',
    'expiresAt': 'expires_at',
    'refillPercent': 'refill_percent',
    'resetDaily': 'reset_daily',
    'resetComputer': 'reset_computer',
    'maxPerUseUsd': 'max_per_use_usd',
    'budgetUsd': 'budget_usd',
    'notifyArrival': 'notify_arrival',
    'notifyReminder': 'notify_reminder',
  },
);

Map<String, dynamic> _$LimitResetCampaignInputToJson(
  LimitResetCampaignInput instance,
) => <String, dynamic>{
  'name': instance.name,
  'message': instance.message,
  'audience': instance.audience.toJson(),
  'starts_at': instance.startsAt.toIso8601String(),
  'expires_at': instance.expiresAt.toIso8601String(),
  'refill_percent': ?instance.refillPercent,
  'reset_daily': ?instance.resetDaily,
  'reset_computer': ?instance.resetComputer,
  'max_per_use_usd': ?instance.maxPerUseUsd,
  'budget_usd': ?instance.budgetUsd,
  'notify_arrival': ?instance.notifyArrival,
  'notify_reminder': ?instance.notifyReminder,
};
