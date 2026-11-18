// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_usage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BillingUsageCWProxy {
  BillingUsage periodStart(DateTime periodStart);

  BillingUsage items(List<BillingUsageItem> items);

  BillingUsage totalUsd(num totalUsd);

  BillingUsage credits(List<CreditEntry> credits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  BillingUsage call({
    DateTime periodStart,
    List<BillingUsageItem> items,
    num totalUsd,
    List<CreditEntry> credits,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBillingUsage.copyWith(...)` or call `instanceOfBillingUsage.copyWith.fieldName(value)` for a single field.
class _$BillingUsageCWProxyImpl implements _$BillingUsageCWProxy {
  const _$BillingUsageCWProxyImpl(this._value);

  final BillingUsage _value;

  @override
  BillingUsage periodStart(DateTime periodStart) =>
      call(periodStart: periodStart);

  @override
  BillingUsage items(List<BillingUsageItem> items) => call(items: items);

  @override
  BillingUsage totalUsd(num totalUsd) => call(totalUsd: totalUsd);

  @override
  BillingUsage credits(List<CreditEntry> credits) => call(credits: credits);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BillingUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BillingUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BillingUsage call({
    Object? periodStart = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? totalUsd = const $CopyWithPlaceholder(),
    Object? credits = const $CopyWithPlaceholder(),
  }) {
    return BillingUsage(
      periodStart:
          periodStart == const $CopyWithPlaceholder() || periodStart == null
          ? _value.periodStart
          // ignore: cast_nullable_to_non_nullable
          : periodStart as DateTime,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<BillingUsageItem>,
      totalUsd: totalUsd == const $CopyWithPlaceholder() || totalUsd == null
          ? _value.totalUsd
          // ignore: cast_nullable_to_non_nullable
          : totalUsd as num,
      credits: credits == const $CopyWithPlaceholder() || credits == null
          ? _value.credits
          // ignore: cast_nullable_to_non_nullable
          : credits as List<CreditEntry>,
    );
  }
}

extension $BillingUsageCopyWith on BillingUsage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBillingUsage.copyWith(...)` or `instanceOfBillingUsage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BillingUsageCWProxy get copyWith => _$BillingUsageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillingUsage _$BillingUsageFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BillingUsage', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['period_start', 'items', 'total_usd', 'credits'],
  );
  final val = BillingUsage(
    periodStart: $checkedConvert(
      'period_start',
      (v) => DateTime.parse(v as String),
    ),
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => BillingUsageItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    totalUsd: $checkedConvert('total_usd', (v) => v as num),
    credits: $checkedConvert(
      'credits',
      (v) => (v as List<dynamic>)
          .map((e) => CreditEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'periodStart': 'period_start', 'totalUsd': 'total_usd'});

Map<String, dynamic> _$BillingUsageToJson(BillingUsage instance) =>
    <String, dynamic>{
      'period_start': instance.periodStart.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      'total_usd': instance.totalUsd,
      'credits': instance.credits.map((e) => e.toJson()).toList(),
    };
