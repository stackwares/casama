// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VendorSettingsCWProxy {
  VendorSettings limitValue(num? limitValue);

  VendorSettings period(VendorSettingsPeriodEnum? period);

  VendorSettings periodStart(DateTime? periodStart);

  VendorSettings expiresAt(DateTime? expiresAt);

  VendorSettings warnAt(num warnAt);

  VendorSettings enabled(bool enabled);

  VendorSettings balanceWarnBelow(num? balanceWarnBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VendorSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VendorSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  VendorSettings call({
    num? limitValue,
    VendorSettingsPeriodEnum? period,
    DateTime? periodStart,
    DateTime? expiresAt,
    num warnAt,
    bool enabled,
    num? balanceWarnBelow,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVendorSettings.copyWith(...)` or call `instanceOfVendorSettings.copyWith.fieldName(value)` for a single field.
class _$VendorSettingsCWProxyImpl implements _$VendorSettingsCWProxy {
  const _$VendorSettingsCWProxyImpl(this._value);

  final VendorSettings _value;

  @override
  VendorSettings limitValue(num? limitValue) => call(limitValue: limitValue);

  @override
  VendorSettings period(VendorSettingsPeriodEnum? period) =>
      call(period: period);

  @override
  VendorSettings periodStart(DateTime? periodStart) =>
      call(periodStart: periodStart);

  @override
  VendorSettings expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  VendorSettings warnAt(num warnAt) => call(warnAt: warnAt);

  @override
  VendorSettings enabled(bool enabled) => call(enabled: enabled);

  @override
  VendorSettings balanceWarnBelow(num? balanceWarnBelow) =>
      call(balanceWarnBelow: balanceWarnBelow);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VendorSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VendorSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VendorSettings call({
    Object? limitValue = const $CopyWithPlaceholder(),
    Object? period = const $CopyWithPlaceholder(),
    Object? periodStart = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? warnAt = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? balanceWarnBelow = const $CopyWithPlaceholder(),
  }) {
    return VendorSettings(
      limitValue: limitValue == const $CopyWithPlaceholder()
          ? _value.limitValue
          // ignore: cast_nullable_to_non_nullable
          : limitValue as num?,
      period: period == const $CopyWithPlaceholder()
          ? _value.period
          // ignore: cast_nullable_to_non_nullable
          : period as VendorSettingsPeriodEnum?,
      periodStart: periodStart == const $CopyWithPlaceholder()
          ? _value.periodStart
          // ignore: cast_nullable_to_non_nullable
          : periodStart as DateTime?,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
      warnAt: warnAt == const $CopyWithPlaceholder() || warnAt == null
          ? _value.warnAt
          // ignore: cast_nullable_to_non_nullable
          : warnAt as num,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      balanceWarnBelow: balanceWarnBelow == const $CopyWithPlaceholder()
          ? _value.balanceWarnBelow
          // ignore: cast_nullable_to_non_nullable
          : balanceWarnBelow as num?,
    );
  }
}

extension $VendorSettingsCopyWith on VendorSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVendorSettings.copyWith(...)` or `instanceOfVendorSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VendorSettingsCWProxy get copyWith => _$VendorSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VendorSettings _$VendorSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'VendorSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'limit_value',
            'period',
            'period_start',
            'expires_at',
            'warn_at',
            'enabled',
          ],
        );
        final val = VendorSettings(
          limitValue: $checkedConvert('limit_value', (v) => v as num?),
          period: $checkedConvert(
            'period',
            (v) => $enumDecodeNullable(_$VendorSettingsPeriodEnumEnumMap, v),
          ),
          periodStart: $checkedConvert(
            'period_start',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          warnAt: $checkedConvert('warn_at', (v) => v as num),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          balanceWarnBelow: $checkedConvert(
            'balance_warn_below',
            (v) => v as num? ?? 5,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'limitValue': 'limit_value',
        'periodStart': 'period_start',
        'expiresAt': 'expires_at',
        'warnAt': 'warn_at',
        'balanceWarnBelow': 'balance_warn_below',
      },
    );

Map<String, dynamic> _$VendorSettingsToJson(VendorSettings instance) =>
    <String, dynamic>{
      'limit_value': instance.limitValue,
      'period': _$VendorSettingsPeriodEnumEnumMap[instance.period],
      'period_start': instance.periodStart?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'warn_at': instance.warnAt,
      'enabled': instance.enabled,
      'balance_warn_below': ?instance.balanceWarnBelow,
    };

const _$VendorSettingsPeriodEnumEnumMap = {
  VendorSettingsPeriodEnum.day: 'day',
  VendorSettingsPeriodEnum.month: 'month',
  VendorSettingsPeriodEnum.billingPeriod: 'billing_period',
  VendorSettingsPeriodEnum.prepaid: 'prepaid',
};
