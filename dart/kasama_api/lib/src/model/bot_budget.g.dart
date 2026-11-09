// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_budget.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotBudgetCWProxy {
  BotBudget perRunUsd(num? perRunUsd);

  BotBudget dailyUsd(num? dailyUsd);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BotBudget(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BotBudget(...).copyWith(id: 12, name: "My name")
  /// ````
  BotBudget call({num? perRunUsd, num? dailyUsd});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfBotBudget.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfBotBudget.copyWith.fieldName(...)`
class _$BotBudgetCWProxyImpl implements _$BotBudgetCWProxy {
  const _$BotBudgetCWProxyImpl(this._value);

  final BotBudget _value;

  @override
  BotBudget perRunUsd(num? perRunUsd) => this(perRunUsd: perRunUsd);

  @override
  BotBudget dailyUsd(num? dailyUsd) => this(dailyUsd: dailyUsd);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `BotBudget(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// BotBudget(...).copyWith(id: 12, name: "My name")
  /// ````
  BotBudget call({
    Object? perRunUsd = const $CopyWithPlaceholder(),
    Object? dailyUsd = const $CopyWithPlaceholder(),
  }) {
    return BotBudget(
      perRunUsd: perRunUsd == const $CopyWithPlaceholder()
          ? _value.perRunUsd
          // ignore: cast_nullable_to_non_nullable
          : perRunUsd as num?,
      dailyUsd: dailyUsd == const $CopyWithPlaceholder()
          ? _value.dailyUsd
          // ignore: cast_nullable_to_non_nullable
          : dailyUsd as num?,
    );
  }
}

extension $BotBudgetCopyWith on BotBudget {
  /// Returns a callable class that can be used as follows: `instanceOfBotBudget.copyWith(...)` or like so:`instanceOfBotBudget.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotBudgetCWProxy get copyWith => _$BotBudgetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotBudget _$BotBudgetFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotBudget',
  json,
  ($checkedConvert) {
    final val = BotBudget(
      perRunUsd: $checkedConvert('per_run_usd', (v) => v as num?),
      dailyUsd: $checkedConvert('daily_usd', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {'perRunUsd': 'per_run_usd', 'dailyUsd': 'daily_usd'},
);

Map<String, dynamic> _$BotBudgetToJson(BotBudget instance) => <String, dynamic>{
  'per_run_usd': ?instance.perRunUsd,
  'daily_usd': ?instance.dailyUsd,
};
