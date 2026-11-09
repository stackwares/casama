// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_summary.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingSummaryCWProxy {
  BillingSummary enabled(bool enabled);

  BillingSummary planCode(String planCode);

  BillingSummary planName(String planName);

  BillingSummary interval(String interval);

  BillingSummary limits(Map<String, num> limits);

  BillingSummary unlimited(bool unlimited);

  BillingSummary validUntil(DateTime? validUntil);

  BillingSummary source_(BillingSummarySource_Enum source_);

  BillingSummary cancelAtPeriodEnd(bool cancelAtPeriodEnd);

  BillingSummary creditsUsd(num creditsUsd);

  BillingSummary subscriptions(List<Subscription> subscriptions);

  BillingSummary providers(List<BillingSource> providers);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingSummary call({
    bool enabled,
    String planCode,
    String planName,
    String interval,
    Map<String, num> limits,
    bool unlimited,
    DateTime? validUntil,
    BillingSummarySource_Enum source_,
    bool cancelAtPeriodEnd,
    num creditsUsd,
    List<Subscription> subscriptions,
    List<BillingSource> providers,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingSummary.copyWith(...)` or call `instanceOfBillingSummary.copyWith.fieldName(value)` for a single field.
class _$BillingSummaryCWProxyImpl implements _$BillingSummaryCWProxy {
  const _$BillingSummaryCWProxyImpl(this._value);

  final BillingSummary _value;

  @override
  BillingSummary enabled(bool enabled) => call(enabled: enabled);

  @override
  BillingSummary planCode(String planCode) => call(planCode: planCode);

  @override
  BillingSummary planName(String planName) => call(planName: planName);

  @override
  BillingSummary interval(String interval) => call(interval: interval);

  @override
  BillingSummary limits(Map<String, num> limits) => call(limits: limits);

  @override
  BillingSummary unlimited(bool unlimited) => call(unlimited: unlimited);

  @override
  BillingSummary validUntil(DateTime? validUntil) =>
      call(validUntil: validUntil);

  @override
  BillingSummary source_(BillingSummarySource_Enum source_) =>
      call(source_: source_);

  @override
  BillingSummary cancelAtPeriodEnd(bool cancelAtPeriodEnd) =>
      call(cancelAtPeriodEnd: cancelAtPeriodEnd);

  @override
  BillingSummary creditsUsd(num creditsUsd) => call(creditsUsd: creditsUsd);

  @override
  BillingSummary subscriptions(List<Subscription> subscriptions) =>
      call(subscriptions: subscriptions);

  @override
  BillingSummary providers(List<BillingSource> providers) =>
      call(providers: providers);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingSummary(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingSummary(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingSummary call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? planName = const $CopyWithPlaceholder(),
    Object? interval = const $CopyWithPlaceholder(),
    Object? limits = const $CopyWithPlaceholder(),
    Object? unlimited = const $CopyWithPlaceholder(),
    Object? validUntil = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? cancelAtPeriodEnd = const $CopyWithPlaceholder(),
    Object? creditsUsd = const $CopyWithPlaceholder(),
    Object? subscriptions = const $CopyWithPlaceholder(),
    Object? providers = const $CopyWithPlaceholder(),
  }) {
    return BillingSummary(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      planName: planName == const $CopyWithPlaceholder() || planName == null
          ? _value.planName
          // ignore: cast_nullable_to_non_nullable
          : planName as String,
      interval: interval == const $CopyWithPlaceholder() || interval == null
          ? _value.interval
          // ignore: cast_nullable_to_non_nullable
          : interval as String,
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, num>,
      unlimited: unlimited == const $CopyWithPlaceholder() || unlimited == null
          ? _value.unlimited
          // ignore: cast_nullable_to_non_nullable
          : unlimited as bool,
      validUntil: validUntil == const $CopyWithPlaceholder()
          ? _value.validUntil
          // ignore: cast_nullable_to_non_nullable
          : validUntil as DateTime?,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as BillingSummarySource_Enum,
      cancelAtPeriodEnd:
          cancelAtPeriodEnd == const $CopyWithPlaceholder() ||
              cancelAtPeriodEnd == null
          ? _value.cancelAtPeriodEnd
          // ignore: cast_nullable_to_non_nullable
          : cancelAtPeriodEnd as bool,
      creditsUsd:
          creditsUsd == const $CopyWithPlaceholder() || creditsUsd == null
          ? _value.creditsUsd
          // ignore: cast_nullable_to_non_nullable
          : creditsUsd as num,
      subscriptions:
          subscriptions == const $CopyWithPlaceholder() || subscriptions == null
          ? _value.subscriptions
          // ignore: cast_nullable_to_non_nullable
          : subscriptions as List<Subscription>,
      providers: providers == const $CopyWithPlaceholder() || providers == null
          ? _value.providers
          // ignore: cast_nullable_to_non_nullable
          : providers as List<BillingSource>,
    );
  }
}

extension $BillingSummaryCopyWith on BillingSummary {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingSummary.copyWith(...)` or `instanceOfBillingSummary.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingSummaryCWProxy get copyWith => _$BillingSummaryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingSummary _$BillingSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'BillingSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'enabled',
            'plan_code',
            'plan_name',
            'interval',
            'limits',
            'unlimited',
            'valid_until',
            'source',
            'cancel_at_period_end',
            'credits_usd',
            'subscriptions',
            'providers',
          ],
        );
        final val = BillingSummary(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          planCode: $checkedConvert('plan_code', (v) => v as String),
          planName: $checkedConvert('plan_name', (v) => v as String),
          interval: $checkedConvert('interval', (v) => v as String),
          limits: $checkedConvert(
            'limits',
            (v) => Map<String, num>.from(v as Map),
          ),
          unlimited: $checkedConvert('unlimited', (v) => v as bool),
          validUntil: $checkedConvert(
            'valid_until',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$BillingSummarySource_EnumEnumMap, v),
          ),
          cancelAtPeriodEnd: $checkedConvert(
            'cancel_at_period_end',
            (v) => v as bool,
          ),
          creditsUsd: $checkedConvert('credits_usd', (v) => v as num),
          subscriptions: $checkedConvert(
            'subscriptions',
            (v) => (v as List<dynamic>)
                .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          providers: $checkedConvert(
            'providers',
            (v) => (v as List<dynamic>)
                .map((e) => $enumDecode(_$BillingSourceEnumMap, e))
                .toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'planCode': 'plan_code',
        'planName': 'plan_name',
        'validUntil': 'valid_until',
        'source_': 'source',
        'cancelAtPeriodEnd': 'cancel_at_period_end',
        'creditsUsd': 'credits_usd',
      },
    );

Map<String, dynamic> _$BillingSummaryToJson(BillingSummary instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'plan_code': instance.planCode,
      'plan_name': instance.planName,
      'interval': instance.interval,
      'limits': instance.limits,
      'unlimited': instance.unlimited,
      'valid_until': instance.validUntil?.toIso8601String(),
      'source': _$BillingSummarySource_EnumEnumMap[instance.source_]!,
      'cancel_at_period_end': instance.cancelAtPeriodEnd,
      'credits_usd': instance.creditsUsd,
      'subscriptions': instance.subscriptions.map((e) => e.toJson()).toList(),
      'providers': instance.providers
          .map((e) => _$BillingSourceEnumMap[e]!)
          .toList(),
    };

const _$BillingSummarySource_EnumEnumMap = {
  BillingSummarySource_Enum.default_: 'default',
  BillingSummarySource_Enum.dodo: 'dodo',
  BillingSummarySource_Enum.appStore: 'app_store',
  BillingSummarySource_Enum.googlePlay: 'google_play',
};

const _$BillingSourceEnumMap = {
  BillingSource.dodo: 'dodo',
  BillingSource.appStore: 'app_store',
  BillingSource.googlePlay: 'google_play',
};
