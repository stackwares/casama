// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportCWProxy {
  UsageReport period(UsageReportPeriodEnum period);

  UsageReport since(DateTime since);

  UsageReport totalCostUsd(num totalCostUsd);

  UsageReport byBot(List<UsageReportByBotInner> byBot);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReport(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReport call({
    UsageReportPeriodEnum period,
    DateTime since,
    num totalCostUsd,
    List<UsageReportByBotInner> byBot,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReport.copyWith(...)` or call `instanceOfUsageReport.copyWith.fieldName(value)` for a single field.
class _$UsageReportCWProxyImpl implements _$UsageReportCWProxy {
  const _$UsageReportCWProxyImpl(this._value);

  final UsageReport _value;

  @override
  UsageReport period(UsageReportPeriodEnum period) => call(period: period);

  @override
  UsageReport since(DateTime since) => call(since: since);

  @override
  UsageReport totalCostUsd(num totalCostUsd) =>
      call(totalCostUsd: totalCostUsd);

  @override
  UsageReport byBot(List<UsageReportByBotInner> byBot) => call(byBot: byBot);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReport(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReport call({
    Object? period = const $CopyWithPlaceholder(),
    Object? since = const $CopyWithPlaceholder(),
    Object? totalCostUsd = const $CopyWithPlaceholder(),
    Object? byBot = const $CopyWithPlaceholder(),
  }) {
    return UsageReport(
      period: period == const $CopyWithPlaceholder() || period == null
          ? _value.period
          // ignore: cast_nullable_to_non_nullable
          : period as UsageReportPeriodEnum,
      since: since == const $CopyWithPlaceholder() || since == null
          ? _value.since
          // ignore: cast_nullable_to_non_nullable
          : since as DateTime,
      totalCostUsd:
          totalCostUsd == const $CopyWithPlaceholder() || totalCostUsd == null
          ? _value.totalCostUsd
          // ignore: cast_nullable_to_non_nullable
          : totalCostUsd as num,
      byBot: byBot == const $CopyWithPlaceholder() || byBot == null
          ? _value.byBot
          // ignore: cast_nullable_to_non_nullable
          : byBot as List<UsageReportByBotInner>,
    );
  }
}

extension $UsageReportCopyWith on UsageReport {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReport.copyWith(...)` or `instanceOfUsageReport.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportCWProxy get copyWith => _$UsageReportCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReport _$UsageReportFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UsageReport', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['period', 'since', 'total_cost_usd', 'by_bot'],
  );
  final val = UsageReport(
    period: $checkedConvert(
      'period',
      (v) => $enumDecode(_$UsageReportPeriodEnumEnumMap, v),
    ),
    since: $checkedConvert('since', (v) => DateTime.parse(v as String)),
    totalCostUsd: $checkedConvert('total_cost_usd', (v) => v as num),
    byBot: $checkedConvert(
      'by_bot',
      (v) => (v as List<dynamic>)
          .map((e) => UsageReportByBotInner.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'totalCostUsd': 'total_cost_usd', 'byBot': 'by_bot'});

Map<String, dynamic> _$UsageReportToJson(UsageReport instance) =>
    <String, dynamic>{
      'period': _$UsageReportPeriodEnumEnumMap[instance.period]!,
      'since': instance.since.toIso8601String(),
      'total_cost_usd': instance.totalCostUsd,
      'by_bot': instance.byBot.map((e) => e.toJson()).toList(),
    };

const _$UsageReportPeriodEnumEnumMap = {
  UsageReportPeriodEnum.day: 'day',
  UsageReportPeriodEnum.month: 'month',
};
