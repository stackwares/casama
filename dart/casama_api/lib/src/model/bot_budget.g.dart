// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_budget.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotBudgetCWProxy {
  BotBudget perRunUsd(num? perRunUsd);

  BotBudget dailyUsd(num? dailyUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotBudget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotBudget(...).copyWith(id: 12, name: "My name")
  /// ```
  BotBudget call({num? perRunUsd, num? dailyUsd});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotBudget.copyWith(...)` or call `instanceOfBotBudget.copyWith.fieldName(value)` for a single field.
class _$BotBudgetCWProxyImpl implements _$BotBudgetCWProxy {
  const _$BotBudgetCWProxyImpl(this._value);

  final BotBudget _value;

  @override
  BotBudget perRunUsd(num? perRunUsd) => call(perRunUsd: perRunUsd);

  @override
  BotBudget dailyUsd(num? dailyUsd) => call(dailyUsd: dailyUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotBudget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotBudget(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotBudget.copyWith(...)` or `instanceOfBotBudget.copyWith.fieldName(...)`.
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
