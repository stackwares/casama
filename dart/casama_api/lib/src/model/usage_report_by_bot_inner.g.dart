// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_report_by_bot_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageReportByBotInnerCWProxy {
  UsageReportByBotInner botId(String? botId);

  UsageReportByBotInner name(String? name);

  UsageReportByBotInner costUsd(num costUsd);

  UsageReportByBotInner tokensIn(int tokensIn);

  UsageReportByBotInner tokensOut(int tokensOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByBotInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByBotInner(...).copyWith(id: 12, name: "My name")
  /// ```
  UsageReportByBotInner call({
    String? botId,
    String? name,
    num costUsd,
    int tokensIn,
    int tokensOut,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUsageReportByBotInner.copyWith(...)` or call `instanceOfUsageReportByBotInner.copyWith.fieldName(value)` for a single field.
class _$UsageReportByBotInnerCWProxyImpl
    implements _$UsageReportByBotInnerCWProxy {
  const _$UsageReportByBotInnerCWProxyImpl(this._value);

  final UsageReportByBotInner _value;

  @override
  UsageReportByBotInner botId(String? botId) => call(botId: botId);

  @override
  UsageReportByBotInner name(String? name) => call(name: name);

  @override
  UsageReportByBotInner costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  UsageReportByBotInner tokensIn(int tokensIn) => call(tokensIn: tokensIn);

  @override
  UsageReportByBotInner tokensOut(int tokensOut) => call(tokensOut: tokensOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UsageReportByBotInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UsageReportByBotInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UsageReportByBotInner call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
  }) {
    return UsageReportByBotInner(
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      tokensIn: tokensIn == const $CopyWithPlaceholder() || tokensIn == null
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder() || tokensOut == null
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
    );
  }
}

extension $UsageReportByBotInnerCopyWith on UsageReportByBotInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUsageReportByBotInner.copyWith(...)` or `instanceOfUsageReportByBotInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageReportByBotInnerCWProxy get copyWith =>
      _$UsageReportByBotInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageReportByBotInner _$UsageReportByBotInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UsageReportByBotInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'bot_id',
        'name',
        'cost_usd',
        'tokens_in',
        'tokens_out',
      ],
    );
    final val = UsageReportByBotInner(
      botId: $checkedConvert('bot_id', (v) => v as String?),
      name: $checkedConvert('name', (v) => v as String?),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      tokensIn: $checkedConvert('tokens_in', (v) => (v as num).toInt()),
      tokensOut: $checkedConvert('tokens_out', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'costUsd': 'cost_usd',
    'tokensIn': 'tokens_in',
    'tokensOut': 'tokens_out',
  },
);

Map<String, dynamic> _$UsageReportByBotInnerToJson(
  UsageReportByBotInner instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'name': instance.name,
  'cost_usd': instance.costUsd,
  'tokens_in': instance.tokensIn,
  'tokens_out': instance.tokensOut,
};
