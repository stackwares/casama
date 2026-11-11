// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanCWProxy {
  Plan code(String code);

  Plan name(String name);

  Plan interval(PlanIntervalEnum interval);

  Plan limits(Map<String, num> limits);

  Plan priceLabel(String? priceLabel);

  Plan web(bool web);

  Plan storeProductIds(Map<String, String> storeProductIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Plan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Plan(...).copyWith(id: 12, name: "My name")
  /// ```
  Plan call({
    String code,
    String name,
    PlanIntervalEnum interval,
    Map<String, num> limits,
    String? priceLabel,
    bool web,
    Map<String, String> storeProductIds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlan.copyWith(...)` or call `instanceOfPlan.copyWith.fieldName(value)` for a single field.
class _$PlanCWProxyImpl implements _$PlanCWProxy {
  const _$PlanCWProxyImpl(this._value);

  final Plan _value;

  @override
  Plan code(String code) => call(code: code);

  @override
  Plan name(String name) => call(name: name);

  @override
  Plan interval(PlanIntervalEnum interval) => call(interval: interval);

  @override
  Plan limits(Map<String, num> limits) => call(limits: limits);

  @override
  Plan priceLabel(String? priceLabel) => call(priceLabel: priceLabel);

  @override
  Plan web(bool web) => call(web: web);

  @override
  Plan storeProductIds(Map<String, String> storeProductIds) =>
      call(storeProductIds: storeProductIds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Plan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Plan(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Plan call({
    Object? code = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? interval = const $CopyWithPlaceholder(),
    Object? limits = const $CopyWithPlaceholder(),
    Object? priceLabel = const $CopyWithPlaceholder(),
    Object? web = const $CopyWithPlaceholder(),
    Object? storeProductIds = const $CopyWithPlaceholder(),
  }) {
    return Plan(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      interval: interval == const $CopyWithPlaceholder() || interval == null
          ? _value.interval
          // ignore: cast_nullable_to_non_nullable
          : interval as PlanIntervalEnum,
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, num>,
      priceLabel: priceLabel == const $CopyWithPlaceholder()
          ? _value.priceLabel
          // ignore: cast_nullable_to_non_nullable
          : priceLabel as String?,
      web: web == const $CopyWithPlaceholder() || web == null
          ? _value.web
          // ignore: cast_nullable_to_non_nullable
          : web as bool,
      storeProductIds:
          storeProductIds == const $CopyWithPlaceholder() ||
              storeProductIds == null
          ? _value.storeProductIds
          // ignore: cast_nullable_to_non_nullable
          : storeProductIds as Map<String, String>,
    );
  }
}

extension $PlanCopyWith on Plan {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlan.copyWith(...)` or `instanceOfPlan.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanCWProxy get copyWith => _$PlanCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Plan',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'code',
        'name',
        'interval',
        'limits',
        'price_label',
        'web',
        'store_product_ids',
      ],
    );
    final val = Plan(
      code: $checkedConvert('code', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      interval: $checkedConvert(
        'interval',
        (v) => $enumDecode(_$PlanIntervalEnumEnumMap, v),
      ),
      limits: $checkedConvert('limits', (v) => Map<String, num>.from(v as Map)),
      priceLabel: $checkedConvert('price_label', (v) => v as String?),
      web: $checkedConvert('web', (v) => v as bool),
      storeProductIds: $checkedConvert(
        'store_product_ids',
        (v) => Map<String, String>.from(v as Map),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'priceLabel': 'price_label',
    'storeProductIds': 'store_product_ids',
  },
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'interval': _$PlanIntervalEnumEnumMap[instance.interval]!,
  'limits': instance.limits,
  'price_label': instance.priceLabel,
  'web': instance.web,
  'store_product_ids': instance.storeProductIds,
};

const _$PlanIntervalEnumEnumMap = {
  PlanIntervalEnum.none: 'none',
  PlanIntervalEnum.month: 'month',
  PlanIntervalEnum.year: 'year',
};
