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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UsageReportByBotInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UsageReportByBotInner(...).copyWith(id: 12, name: "My name")
  /// ````
  UsageReportByBotInner call({
    String? botId,
    String? name,
    num costUsd,
    int tokensIn,
    int tokensOut,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUsageReportByBotInner.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUsageReportByBotInner.copyWith.fieldName(...)`
class _$UsageReportByBotInnerCWProxyImpl
    implements _$UsageReportByBotInnerCWProxy {
  const _$UsageReportByBotInnerCWProxyImpl(this._value);

  final UsageReportByBotInner _value;

  @override
  UsageReportByBotInner botId(String? botId) => this(botId: botId);

  @override
  UsageReportByBotInner name(String? name) => this(name: name);

  @override
  UsageReportByBotInner costUsd(num costUsd) => this(costUsd: costUsd);

  @override
  UsageReportByBotInner tokensIn(int tokensIn) => this(tokensIn: tokensIn);

  @override
  UsageReportByBotInner tokensOut(int tokensOut) => this(tokensOut: tokensOut);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UsageReportByBotInner(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UsageReportByBotInner(...).copyWith(id: 12, name: "My name")
  /// ````
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
      costUsd: costUsd == const $CopyWithPlaceholder()
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      tokensIn: tokensIn == const $CopyWithPlaceholder()
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder()
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
    );
  }
}

extension $UsageReportByBotInnerCopyWith on UsageReportByBotInner {
  /// Returns a callable class that can be used as follows: `instanceOfUsageReportByBotInner.copyWith(...)` or like so:`instanceOfUsageReportByBotInner.copyWith.fieldName(...)`.
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
