// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_pricing.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPricingCWProxy {
  AdminPricing billingEnabled(bool billingEnabled);

  AdminPricing plans(List<AdminPlan> plans);

  AdminPricing packs(List<AdminCreditPack> packs);

  AdminPricing settings(BillingSettings settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPricing(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPricing(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPricing call({
    bool billingEnabled,
    List<AdminPlan> plans,
    List<AdminCreditPack> packs,
    BillingSettings settings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPricing.copyWith(...)` or call `instanceOfAdminPricing.copyWith.fieldName(value)` for a single field.
class _$AdminPricingCWProxyImpl implements _$AdminPricingCWProxy {
  const _$AdminPricingCWProxyImpl(this._value);

  final AdminPricing _value;

  @override
  AdminPricing billingEnabled(bool billingEnabled) =>
      call(billingEnabled: billingEnabled);

  @override
  AdminPricing plans(List<AdminPlan> plans) => call(plans: plans);

  @override
  AdminPricing packs(List<AdminCreditPack> packs) => call(packs: packs);

  @override
  AdminPricing settings(BillingSettings settings) => call(settings: settings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPricing(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPricing(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPricing call({
    Object? billingEnabled = const $CopyWithPlaceholder(),
    Object? plans = const $CopyWithPlaceholder(),
    Object? packs = const $CopyWithPlaceholder(),
    Object? settings = const $CopyWithPlaceholder(),
  }) {
    return AdminPricing(
      billingEnabled:
          billingEnabled == const $CopyWithPlaceholder() ||
              billingEnabled == null
          ? _value.billingEnabled
          // ignore: cast_nullable_to_non_nullable
          : billingEnabled as bool,
      plans: plans == const $CopyWithPlaceholder() || plans == null
          ? _value.plans
          // ignore: cast_nullable_to_non_nullable
          : plans as List<AdminPlan>,
      packs: packs == const $CopyWithPlaceholder() || packs == null
          ? _value.packs
          // ignore: cast_nullable_to_non_nullable
          : packs as List<AdminCreditPack>,
      settings: settings == const $CopyWithPlaceholder() || settings == null
          ? _value.settings
          // ignore: cast_nullable_to_non_nullable
          : settings as BillingSettings,
    );
  }
}

extension $AdminPricingCopyWith on AdminPricing {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPricing.copyWith(...)` or `instanceOfAdminPricing.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPricingCWProxy get copyWith => _$AdminPricingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPricing _$AdminPricingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminPricing', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['billing_enabled', 'plans', 'packs', 'settings'],
      );
      final val = AdminPricing(
        billingEnabled: $checkedConvert('billing_enabled', (v) => v as bool),
        plans: $checkedConvert(
          'plans',
          (v) => (v as List<dynamic>)
              .map((e) => AdminPlan.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        packs: $checkedConvert(
          'packs',
          (v) => (v as List<dynamic>)
              .map((e) => AdminCreditPack.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        settings: $checkedConvert(
          'settings',
          (v) => BillingSettings.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'billingEnabled': 'billing_enabled'});

Map<String, dynamic> _$AdminPricingToJson(AdminPricing instance) =>
    <String, dynamic>{
      'billing_enabled': instance.billingEnabled,
      'plans': instance.plans.map((e) => e.toJson()).toList(),
      'packs': instance.packs.map((e) => e.toJson()).toList(),
      'settings': instance.settings.toJson(),
    };
