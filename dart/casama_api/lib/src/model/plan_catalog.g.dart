// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_catalog.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanCatalogCWProxy {
  PlanCatalog enabled(bool enabled);

  PlanCatalog plans(List<Plan> plans);

  PlanCatalog packs(List<CreditPack> packs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanCatalog call({bool enabled, List<Plan> plans, List<CreditPack> packs});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanCatalog.copyWith(...)` or call `instanceOfPlanCatalog.copyWith.fieldName(value)` for a single field.
class _$PlanCatalogCWProxyImpl implements _$PlanCatalogCWProxy {
  const _$PlanCatalogCWProxyImpl(this._value);

  final PlanCatalog _value;

  @override
  PlanCatalog enabled(bool enabled) => call(enabled: enabled);

  @override
  PlanCatalog plans(List<Plan> plans) => call(plans: plans);

  @override
  PlanCatalog packs(List<CreditPack> packs) => call(packs: packs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanCatalog call({
    Object? enabled = const $CopyWithPlaceholder(),
    Object? plans = const $CopyWithPlaceholder(),
    Object? packs = const $CopyWithPlaceholder(),
  }) {
    return PlanCatalog(
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      plans: plans == const $CopyWithPlaceholder() || plans == null
          ? _value.plans
          // ignore: cast_nullable_to_non_nullable
          : plans as List<Plan>,
      packs: packs == const $CopyWithPlaceholder() || packs == null
          ? _value.packs
          // ignore: cast_nullable_to_non_nullable
          : packs as List<CreditPack>,
    );
  }
}

extension $PlanCatalogCopyWith on PlanCatalog {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanCatalog.copyWith(...)` or `instanceOfPlanCatalog.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanCatalogCWProxy get copyWith => _$PlanCatalogCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanCatalog _$PlanCatalogFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlanCatalog', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['enabled', 'plans', 'packs']);
      final val = PlanCatalog(
        enabled: $checkedConvert('enabled', (v) => v as bool),
        plans: $checkedConvert(
          'plans',
          (v) => (v as List<dynamic>)
              .map((e) => Plan.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        packs: $checkedConvert(
          'packs',
          (v) => (v as List<dynamic>)
              .map((e) => CreditPack.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlanCatalogToJson(PlanCatalog instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'plans': instance.plans.map((e) => e.toJson()).toList(),
      'packs': instance.packs.map((e) => e.toJson()).toList(),
    };
