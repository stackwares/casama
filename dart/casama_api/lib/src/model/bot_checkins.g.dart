// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_checkins.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotCheckinsCWProxy {
  BotCheckins enabled(bool enabled);

  BotCheckins briefTime(String briefTime);

  BotCheckins scanEveryHours(int scanEveryHours);

  BotCheckins dailyCapUsd(num dailyCapUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotCheckins(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotCheckins(...).copyWith(id: 12, name: "My name")
  /// ```
  BotCheckins call({
    bool enabled,
    String briefTime,
    int scanEveryHours,
    num dailyCapUsd,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotCheckins.copyWith(...)` or call `instanceOfBotCheckins.copyWith.fieldName(value)` for a single field.
class _$BotCheckinsCWProxyImpl implements _$BotCheckinsCWProxy {
  const _$BotCheckinsCWProxyImpl(this._value);

  final BotCheckins _value;

  @override
  BotCheckins enabled(bool enabled) => call(enabled: enabled);

  @override
  BotCheckins briefTime(String briefTime) => call(briefTime: briefTime);

  @override
  BotCheckins scanEveryHours(int scanEveryHours) =>
      call(scanEveryHours: scanEveryHours);

  @override
  BotCheckins dailyCapUsd(num dailyCapUsd) => call(dailyCapUsd: dailyCapUsd);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotCheckins(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotCheckins(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotCheckins call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? briefTime = const $CopyWithPlaceholder(),
    Object? scanEveryHours = const $CopyWithPlaceholder(),
    Object? dailyCapUsd = const $CopyWithPlaceholder(),
  }) {
    return BotCheckins(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      briefTime: briefTime == const $CopyWithPlaceholder() || briefTime == null
          ? _value.briefTime
          // ignore: cast_nullable_to_non_nullable
          : briefTime as String,
      scanEveryHours:
          scanEveryHours == const $CopyWithPlaceholder() ||
              scanEveryHours == null
          ? _value.scanEveryHours
          // ignore: cast_nullable_to_non_nullable
          : scanEveryHours as int,
      dailyCapUsd:
          dailyCapUsd == const $CopyWithPlaceholder() || dailyCapUsd == null
          ? _value.dailyCapUsd
          // ignore: cast_nullable_to_non_nullable
          : dailyCapUsd as num,
    );
  }
}

extension $BotCheckinsCopyWith on BotCheckins {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotCheckins.copyWith(...)` or `instanceOfBotCheckins.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotCheckinsCWProxy get copyWith => _$BotCheckinsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotCheckins _$BotCheckinsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'BotCheckins',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'enabled',
        'brief_time',
        'scan_every_hours',
        'daily_cap_usd',
      ],
    );
    final val = BotCheckins(
      enabled: $checkedConvert('enabled', (v) => v as bool),
      briefTime: $checkedConvert('brief_time', (v) => v as String),
      scanEveryHours: $checkedConvert(
        'scan_every_hours',
        (v) => (v as num).toInt(),
      ),
      dailyCapUsd: $checkedConvert('daily_cap_usd', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'briefTime': 'brief_time',
    'scanEveryHours': 'scan_every_hours',
    'dailyCapUsd': 'daily_cap_usd',
  },
);

Map<String, dynamic> _$BotCheckinsToJson(BotCheckins instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'brief_time': instance.briefTime,
      'scan_every_hours': instance.scanEveryHours,
      'daily_cap_usd': instance.dailyCapUsd,
    };
