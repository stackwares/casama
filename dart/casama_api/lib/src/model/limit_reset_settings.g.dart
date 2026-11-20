// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_reset_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LimitResetSettingsCWProxy {
  LimitResetSettings enabled(bool enabled);

  LimitResetSettings perPeriod(int perPeriod);

  LimitResetSettings maxHeld(int maxHeld);

  LimitResetSettings notifyOwners(bool notifyOwners);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  LimitResetSettings call({
    bool enabled,
    int perPeriod,
    int maxHeld,
    bool notifyOwners,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLimitResetSettings.copyWith(...)` or call `instanceOfLimitResetSettings.copyWith.fieldName(value)` for a single field.
class _$LimitResetSettingsCWProxyImpl implements _$LimitResetSettingsCWProxy {
  const _$LimitResetSettingsCWProxyImpl(this._value);

  final LimitResetSettings _value;

  @override
  LimitResetSettings enabled(bool enabled) => call(enabled: enabled);

  @override
  LimitResetSettings perPeriod(int perPeriod) => call(perPeriod: perPeriod);

  @override
  LimitResetSettings maxHeld(int maxHeld) => call(maxHeld: maxHeld);

  @override
  LimitResetSettings notifyOwners(bool notifyOwners) =>
      call(notifyOwners: notifyOwners);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LimitResetSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LimitResetSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LimitResetSettings call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? perPeriod = const $CopyWithPlaceholder(),
    Object? maxHeld = const $CopyWithPlaceholder(),
    Object? notifyOwners = const $CopyWithPlaceholder(),
  }) {
    return LimitResetSettings(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      perPeriod: perPeriod == const $CopyWithPlaceholder() || perPeriod == null
          ? _value.perPeriod
          // ignore: cast_nullable_to_non_nullable
          : perPeriod as int,
      maxHeld: maxHeld == const $CopyWithPlaceholder() || maxHeld == null
          ? _value.maxHeld
          // ignore: cast_nullable_to_non_nullable
          : maxHeld as int,
      notifyOwners:
          notifyOwners == const $CopyWithPlaceholder() || notifyOwners == null
          ? _value.notifyOwners
          // ignore: cast_nullable_to_non_nullable
          : notifyOwners as bool,
    );
  }
}

extension $LimitResetSettingsCopyWith on LimitResetSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLimitResetSettings.copyWith(...)` or `instanceOfLimitResetSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LimitResetSettingsCWProxy get copyWith =>
      _$LimitResetSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitResetSettings _$LimitResetSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LimitResetSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'enabled',
            'per_period',
            'max_held',
            'notify_owners',
          ],
        );
        final val = LimitResetSettings(
          enabled: $checkedConvert('enabled', (v) => v as bool),
          perPeriod: $checkedConvert('per_period', (v) => (v as num).toInt()),
          maxHeld: $checkedConvert('max_held', (v) => (v as num).toInt()),
          notifyOwners: $checkedConvert('notify_owners', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'perPeriod': 'per_period',
        'maxHeld': 'max_held',
        'notifyOwners': 'notify_owners',
      },
    );

Map<String, dynamic> _$LimitResetSettingsToJson(LimitResetSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'per_period': instance.perPeriod,
      'max_held': instance.maxHeld,
      'notify_owners': instance.notifyOwners,
    };
