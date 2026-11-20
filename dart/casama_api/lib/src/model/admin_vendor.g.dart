// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_vendor.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminVendorCWProxy {
  AdminVendor limitValue(num? limitValue);

  AdminVendor period(AdminVendorPeriodEnum? period);

  AdminVendor periodStart(DateTime? periodStart);

  AdminVendor expiresAt(DateTime? expiresAt);

  AdminVendor warnAt(num warnAt);

  AdminVendor enabled(bool enabled);

  AdminVendor balanceWarnBelow(num? balanceWarnBelow);

  AdminVendor billingUrl(String? billingUrl);

  AdminVendor impact(String? impact);

  AdminVendor vendor(String vendor);

  AdminVendor label(String label);

  AdminVendor kind(AdminVendorKindEnum kind);

  AdminVendor unit(String unit);

  AdminVendor latest(VendorReading? latest);

  AdminVendor history(List<VendorReading> history);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminVendor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminVendor(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminVendor call({
    num? limitValue,
    AdminVendorPeriodEnum? period,
    DateTime? periodStart,
    DateTime? expiresAt,
    num warnAt,
    bool enabled,
    num? balanceWarnBelow,
    String? billingUrl,
    String? impact,
    String vendor,
    String label,
    AdminVendorKindEnum kind,
    String unit,
    VendorReading? latest,
    List<VendorReading> history,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminVendor.copyWith(...)` or call `instanceOfAdminVendor.copyWith.fieldName(value)` for a single field.
class _$AdminVendorCWProxyImpl implements _$AdminVendorCWProxy {
  const _$AdminVendorCWProxyImpl(this._value);

  final AdminVendor _value;

  @override
  AdminVendor limitValue(num? limitValue) => call(limitValue: limitValue);

  @override
  AdminVendor period(AdminVendorPeriodEnum? period) => call(period: period);

  @override
  AdminVendor periodStart(DateTime? periodStart) =>
      call(periodStart: periodStart);

  @override
  AdminVendor expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  @override
  AdminVendor warnAt(num warnAt) => call(warnAt: warnAt);

  @override
  AdminVendor enabled(bool enabled) => call(enabled: enabled);

  @override
  AdminVendor balanceWarnBelow(num? balanceWarnBelow) =>
      call(balanceWarnBelow: balanceWarnBelow);

  @override
  AdminVendor billingUrl(String? billingUrl) => call(billingUrl: billingUrl);

  @override
  AdminVendor impact(String? impact) => call(impact: impact);

  @override
  AdminVendor vendor(String vendor) => call(vendor: vendor);

  @override
  AdminVendor label(String label) => call(label: label);

  @override
  AdminVendor kind(AdminVendorKindEnum kind) => call(kind: kind);

  @override
  AdminVendor unit(String unit) => call(unit: unit);

  @override
  AdminVendor latest(VendorReading? latest) => call(latest: latest);

  @override
  AdminVendor history(List<VendorReading> history) => call(history: history);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminVendor(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminVendor(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminVendor call({
    Object? limitValue = const $CopyWithPlaceholder(),
    Object? period = const $CopyWithPlaceholder(),
    Object? periodStart = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? warnAt = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? balanceWarnBelow = const $CopyWithPlaceholder(),
    Object? billingUrl = const $CopyWithPlaceholder(),
    Object? impact = const $CopyWithPlaceholder(),
    Object? vendor = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? latest = const $CopyWithPlaceholder(),
    Object? history = const $CopyWithPlaceholder(),
  }) {
    return AdminVendor(
      limitValue: limitValue == const $CopyWithPlaceholder()
          ? _value.limitValue
          // ignore: cast_nullable_to_non_nullable
          : limitValue as num?,
      period: period == const $CopyWithPlaceholder()
          ? _value.period
          // ignore: cast_nullable_to_non_nullable
          : period as AdminVendorPeriodEnum?,
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
      billingUrl: billingUrl == const $CopyWithPlaceholder()
          ? _value.billingUrl
          // ignore: cast_nullable_to_non_nullable
          : billingUrl as String?,
      impact: impact == const $CopyWithPlaceholder()
          ? _value.impact
          // ignore: cast_nullable_to_non_nullable
          : impact as String?,
      vendor: vendor == const $CopyWithPlaceholder() || vendor == null
          ? _value.vendor
          // ignore: cast_nullable_to_non_nullable
          : vendor as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as AdminVendorKindEnum,
      unit: unit == const $CopyWithPlaceholder() || unit == null
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as String,
      latest: latest == const $CopyWithPlaceholder()
          ? _value.latest
          // ignore: cast_nullable_to_non_nullable
          : latest as VendorReading?,
      history: history == const $CopyWithPlaceholder() || history == null
          ? _value.history
          // ignore: cast_nullable_to_non_nullable
          : history as List<VendorReading>,
    );
  }
}

extension $AdminVendorCopyWith on AdminVendor {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminVendor.copyWith(...)` or `instanceOfAdminVendor.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminVendorCWProxy get copyWith => _$AdminVendorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminVendor _$AdminVendorFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminVendor',
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
        'billing_url',
        'impact',
        'vendor',
        'label',
        'kind',
        'unit',
        'latest',
        'history',
      ],
    );
    final val = AdminVendor(
      limitValue: $checkedConvert('limit_value', (v) => v as num?),
      period: $checkedConvert(
        'period',
        (v) => $enumDecodeNullable(_$AdminVendorPeriodEnumEnumMap, v),
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
      billingUrl: $checkedConvert('billing_url', (v) => v as String?),
      impact: $checkedConvert('impact', (v) => v as String?),
      vendor: $checkedConvert('vendor', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$AdminVendorKindEnumEnumMap, v),
      ),
      unit: $checkedConvert('unit', (v) => v as String),
      latest: $checkedConvert(
        'latest',
        (v) => v == null
            ? null
            : VendorReading.fromJson(v as Map<String, dynamic>),
      ),
      history: $checkedConvert(
        'history',
        (v) => (v as List<dynamic>)
            .map((e) => VendorReading.fromJson(e as Map<String, dynamic>))
            .toList(),
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
    'billingUrl': 'billing_url',
  },
);

Map<String, dynamic> _$AdminVendorToJson(AdminVendor instance) =>
    <String, dynamic>{
      'limit_value': instance.limitValue,
      'period': _$AdminVendorPeriodEnumEnumMap[instance.period],
      'period_start': instance.periodStart?.toIso8601String(),
      'expires_at': instance.expiresAt?.toIso8601String(),
      'warn_at': instance.warnAt,
      'enabled': instance.enabled,
      'balance_warn_below': ?instance.balanceWarnBelow,
      'billing_url': instance.billingUrl,
      'impact': instance.impact,
      'vendor': instance.vendor,
      'label': instance.label,
      'kind': _$AdminVendorKindEnumEnumMap[instance.kind]!,
      'unit': instance.unit,
      'latest': instance.latest?.toJson(),
      'history': instance.history.map((e) => e.toJson()).toList(),
    };

const _$AdminVendorPeriodEnumEnumMap = {
  AdminVendorPeriodEnum.day: 'day',
  AdminVendorPeriodEnum.month: 'month',
  AdminVendorPeriodEnum.billingPeriod: 'billing_period',
  AdminVendorPeriodEnum.prepaid: 'prepaid',
};

const _$AdminVendorKindEnumEnumMap = {
  AdminVendorKindEnum.quota: 'quota',
  AdminVendorKindEnum.balance: 'balance',
  AdminVendorKindEnum.renewal: 'renewal',
};
