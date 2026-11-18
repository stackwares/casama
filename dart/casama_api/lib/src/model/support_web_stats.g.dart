// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_web_stats.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportWebStatsCWProxy {
  SupportWebStats on_(bool on_);

  SupportWebStats messagesToday(int messagesToday);

  SupportWebStats usdToday(num usdToday);

  SupportWebStats dailyBudgetUsd(num dailyBudgetUsd);

  SupportWebStats pausedAddresses(int pausedAddresses);

  SupportWebStats gaps(List<SupportWebStatsGapsInner> gaps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebStats(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportWebStats call({
    bool on_,
    int messagesToday,
    num usdToday,
    num dailyBudgetUsd,
    int pausedAddresses,
    List<SupportWebStatsGapsInner> gaps,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportWebStats.copyWith(...)` or call `instanceOfSupportWebStats.copyWith.fieldName(value)` for a single field.
class _$SupportWebStatsCWProxyImpl implements _$SupportWebStatsCWProxy {
  const _$SupportWebStatsCWProxyImpl(this._value);

  final SupportWebStats _value;

  @override
  SupportWebStats on_(bool on_) => call(on_: on_);

  @override
  SupportWebStats messagesToday(int messagesToday) =>
      call(messagesToday: messagesToday);

  @override
  SupportWebStats usdToday(num usdToday) => call(usdToday: usdToday);

  @override
  SupportWebStats dailyBudgetUsd(num dailyBudgetUsd) =>
      call(dailyBudgetUsd: dailyBudgetUsd);

  @override
  SupportWebStats pausedAddresses(int pausedAddresses) =>
      call(pausedAddresses: pausedAddresses);

  @override
  SupportWebStats gaps(List<SupportWebStatsGapsInner> gaps) => call(gaps: gaps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportWebStats(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportWebStats(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportWebStats call({
    Object? on_ = const $CopyWithPlaceholder(),
    Object? messagesToday = const $CopyWithPlaceholder(),
    Object? usdToday = const $CopyWithPlaceholder(),
    Object? dailyBudgetUsd = const $CopyWithPlaceholder(),
    Object? pausedAddresses = const $CopyWithPlaceholder(),
    Object? gaps = const $CopyWithPlaceholder(),
  }) {
    return SupportWebStats(
      on_: on_ == const $CopyWithPlaceholder() || on_ == null
          ? _value.on_
          // ignore: cast_nullable_to_non_nullable
          : on_ as bool,
      messagesToday:
          messagesToday == const $CopyWithPlaceholder() || messagesToday == null
          ? _value.messagesToday
          // ignore: cast_nullable_to_non_nullable
          : messagesToday as int,
      usdToday: usdToday == const $CopyWithPlaceholder() || usdToday == null
          ? _value.usdToday
          // ignore: cast_nullable_to_non_nullable
          : usdToday as num,
      dailyBudgetUsd:
          dailyBudgetUsd == const $CopyWithPlaceholder() ||
              dailyBudgetUsd == null
          ? _value.dailyBudgetUsd
          // ignore: cast_nullable_to_non_nullable
          : dailyBudgetUsd as num,
      pausedAddresses:
          pausedAddresses == const $CopyWithPlaceholder() ||
              pausedAddresses == null
          ? _value.pausedAddresses
          // ignore: cast_nullable_to_non_nullable
          : pausedAddresses as int,
      gaps: gaps == const $CopyWithPlaceholder() || gaps == null
          ? _value.gaps
          // ignore: cast_nullable_to_non_nullable
          : gaps as List<SupportWebStatsGapsInner>,
    );
  }
}

extension $SupportWebStatsCopyWith on SupportWebStats {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportWebStats.copyWith(...)` or `instanceOfSupportWebStats.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportWebStatsCWProxy get copyWith => _$SupportWebStatsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportWebStats _$SupportWebStatsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SupportWebStats',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'on',
            'messages_today',
            'usd_today',
            'daily_budget_usd',
            'paused_addresses',
            'gaps',
          ],
        );
        final val = SupportWebStats(
          on_: $checkedConvert('on', (v) => v as bool),
          messagesToday: $checkedConvert(
            'messages_today',
            (v) => (v as num).toInt(),
          ),
          usdToday: $checkedConvert('usd_today', (v) => v as num),
          dailyBudgetUsd: $checkedConvert('daily_budget_usd', (v) => v as num),
          pausedAddresses: $checkedConvert(
            'paused_addresses',
            (v) => (v as num).toInt(),
          ),
          gaps: $checkedConvert(
            'gaps',
            (v) => (v as List<dynamic>)
                .map(
                  (e) => SupportWebStatsGapsInner.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'on_': 'on',
        'messagesToday': 'messages_today',
        'usdToday': 'usd_today',
        'dailyBudgetUsd': 'daily_budget_usd',
        'pausedAddresses': 'paused_addresses',
      },
    );

Map<String, dynamic> _$SupportWebStatsToJson(SupportWebStats instance) =>
    <String, dynamic>{
      'on': instance.on_,
      'messages_today': instance.messagesToday,
      'usd_today': instance.usdToday,
      'daily_budget_usd': instance.dailyBudgetUsd,
      'paused_addresses': instance.pausedAddresses,
      'gaps': instance.gaps.map((e) => e.toJson()).toList(),
    };
