// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubscriptionCWProxy {
  Subscription id(String id);

  Subscription source_(BillingSource source_);

  Subscription planCode(String planCode);

  Subscription status(String status);

  Subscription currentPeriodEnd(DateTime? currentPeriodEnd);

  Subscription cancelAtPeriodEnd(bool cancelAtPeriodEnd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Subscription(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Subscription(...).copyWith(id: 12, name: "My name")
  /// ```
  Subscription call({
    String id,
    BillingSource source_,
    String planCode,
    String status,
    DateTime? currentPeriodEnd,
    bool cancelAtPeriodEnd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubscription.copyWith(...)` or call `instanceOfSubscription.copyWith.fieldName(value)` for a single field.
class _$SubscriptionCWProxyImpl implements _$SubscriptionCWProxy {
  const _$SubscriptionCWProxyImpl(this._value);

  final Subscription _value;

  @override
  Subscription id(String id) => call(id: id);

  @override
  Subscription source_(BillingSource source_) => call(source_: source_);

  @override
  Subscription planCode(String planCode) => call(planCode: planCode);

  @override
  Subscription status(String status) => call(status: status);

  @override
  Subscription currentPeriodEnd(DateTime? currentPeriodEnd) =>
      call(currentPeriodEnd: currentPeriodEnd);

  @override
  Subscription cancelAtPeriodEnd(bool cancelAtPeriodEnd) =>
      call(cancelAtPeriodEnd: cancelAtPeriodEnd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Subscription(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Subscription(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Subscription call({
    Object? id = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? planCode = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? currentPeriodEnd = const $CopyWithPlaceholder(),
    Object? cancelAtPeriodEnd = const $CopyWithPlaceholder(),
  }) {
    return Subscription(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as BillingSource,
      planCode: planCode == const $CopyWithPlaceholder() || planCode == null
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      currentPeriodEnd: currentPeriodEnd == const $CopyWithPlaceholder()
          ? _value.currentPeriodEnd
          // ignore: cast_nullable_to_non_nullable
          : currentPeriodEnd as DateTime?,
      cancelAtPeriodEnd:
          cancelAtPeriodEnd == const $CopyWithPlaceholder() ||
              cancelAtPeriodEnd == null
          ? _value.cancelAtPeriodEnd
          // ignore: cast_nullable_to_non_nullable
          : cancelAtPeriodEnd as bool,
    );
  }
}

extension $SubscriptionCopyWith on Subscription {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubscription.copyWith(...)` or `instanceOfSubscription.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubscriptionCWProxy get copyWith => _$SubscriptionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Subscription',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'source',
            'plan_code',
            'status',
            'current_period_end',
            'cancel_at_period_end',
          ],
        );
        final val = Subscription(
          id: $checkedConvert('id', (v) => v as String),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$BillingSourceEnumMap, v),
          ),
          planCode: $checkedConvert('plan_code', (v) => v as String),
          status: $checkedConvert('status', (v) => v as String),
          currentPeriodEnd: $checkedConvert(
            'current_period_end',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          cancelAtPeriodEnd: $checkedConvert(
            'cancel_at_period_end',
            (v) => v as bool,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'source_': 'source',
        'planCode': 'plan_code',
        'currentPeriodEnd': 'current_period_end',
        'cancelAtPeriodEnd': 'cancel_at_period_end',
      },
    );

Map<String, dynamic> _$SubscriptionToJson(Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': _$BillingSourceEnumMap[instance.source_]!,
      'plan_code': instance.planCode,
      'status': instance.status,
      'current_period_end': instance.currentPeriodEnd?.toIso8601String(),
      'cancel_at_period_end': instance.cancelAtPeriodEnd,
    };

const _$BillingSourceEnumMap = {
  BillingSource.dodo: 'dodo',
  BillingSource.appStore: 'app_store',
  BillingSource.googlePlay: 'google_play',
};
