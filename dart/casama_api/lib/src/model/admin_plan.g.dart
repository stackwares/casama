// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_plan.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminPlanCWProxy {
  AdminPlan code(String code);

  AdminPlan name(String name);

  AdminPlan interval(AdminPlanIntervalEnum interval);

  AdminPlan active(bool active);

  AdminPlan sort(int sort);

  AdminPlan priceLabel(String? priceLabel);

  AdminPlan limits(Map<String, num> limits);

  AdminPlan creditGate(bool creditGate);

  AdminPlan storeProductIds(Map<String, String> storeProductIds);

  AdminPlan dodoProductId(String? dodoProductId);

  AdminPlan workspaces(int workspaces);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPlan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPlan(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminPlan call({
    String code,
    String name,
    AdminPlanIntervalEnum interval,
    bool active,
    int sort,
    String? priceLabel,
    Map<String, num> limits,
    bool creditGate,
    Map<String, String> storeProductIds,
    String? dodoProductId,
    int workspaces,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminPlan.copyWith(...)` or call `instanceOfAdminPlan.copyWith.fieldName(value)` for a single field.
class _$AdminPlanCWProxyImpl implements _$AdminPlanCWProxy {
  const _$AdminPlanCWProxyImpl(this._value);

  final AdminPlan _value;

  @override
  AdminPlan code(String code) => call(code: code);

  @override
  AdminPlan name(String name) => call(name: name);

  @override
  AdminPlan interval(AdminPlanIntervalEnum interval) =>
      call(interval: interval);

  @override
  AdminPlan active(bool active) => call(active: active);

  @override
  AdminPlan sort(int sort) => call(sort: sort);

  @override
  AdminPlan priceLabel(String? priceLabel) => call(priceLabel: priceLabel);

  @override
  AdminPlan limits(Map<String, num> limits) => call(limits: limits);

  @override
  AdminPlan creditGate(bool creditGate) => call(creditGate: creditGate);

  @override
  AdminPlan storeProductIds(Map<String, String> storeProductIds) =>
      call(storeProductIds: storeProductIds);

  @override
  AdminPlan dodoProductId(String? dodoProductId) =>
      call(dodoProductId: dodoProductId);

  @override
  AdminPlan workspaces(int workspaces) => call(workspaces: workspaces);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminPlan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminPlan(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminPlan call({
    Object? code = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? interval = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? sort = const $CopyWithPlaceholder(),
    Object? priceLabel = const $CopyWithPlaceholder(),
    Object? limits = const $CopyWithPlaceholder(),
    Object? creditGate = const $CopyWithPlaceholder(),
    Object? storeProductIds = const $CopyWithPlaceholder(),
    Object? dodoProductId = const $CopyWithPlaceholder(),
    Object? workspaces = const $CopyWithPlaceholder(),
  }) {
    return AdminPlan(
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
          : interval as AdminPlanIntervalEnum,
      active: active == const $CopyWithPlaceholder() || active == null
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      sort: sort == const $CopyWithPlaceholder() || sort == null
          ? _value.sort
          // ignore: cast_nullable_to_non_nullable
          : sort as int,
      priceLabel: priceLabel == const $CopyWithPlaceholder()
          ? _value.priceLabel
          // ignore: cast_nullable_to_non_nullable
          : priceLabel as String?,
      limits: limits == const $CopyWithPlaceholder() || limits == null
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, num>,
      creditGate:
          creditGate == const $CopyWithPlaceholder() || creditGate == null
          ? _value.creditGate
          // ignore: cast_nullable_to_non_nullable
          : creditGate as bool,
      storeProductIds:
          storeProductIds == const $CopyWithPlaceholder() ||
              storeProductIds == null
          ? _value.storeProductIds
          // ignore: cast_nullable_to_non_nullable
          : storeProductIds as Map<String, String>,
      dodoProductId: dodoProductId == const $CopyWithPlaceholder()
          ? _value.dodoProductId
          // ignore: cast_nullable_to_non_nullable
          : dodoProductId as String?,
      workspaces:
          workspaces == const $CopyWithPlaceholder() || workspaces == null
          ? _value.workspaces
          // ignore: cast_nullable_to_non_nullable
          : workspaces as int,
    );
  }
}

extension $AdminPlanCopyWith on AdminPlan {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminPlan.copyWith(...)` or `instanceOfAdminPlan.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminPlanCWProxy get copyWith => _$AdminPlanCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminPlan _$AdminPlanFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AdminPlan',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'code',
        'name',
        'interval',
        'active',
        'sort',
        'price_label',
        'limits',
        'credit_gate',
        'store_product_ids',
        'dodo_product_id',
        'workspaces',
      ],
    );
    final val = AdminPlan(
      code: $checkedConvert('code', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      interval: $checkedConvert(
        'interval',
        (v) => $enumDecode(_$AdminPlanIntervalEnumEnumMap, v),
      ),
      active: $checkedConvert('active', (v) => v as bool),
      sort: $checkedConvert('sort', (v) => (v as num).toInt()),
      priceLabel: $checkedConvert('price_label', (v) => v as String?),
      limits: $checkedConvert('limits', (v) => Map<String, num>.from(v as Map)),
      creditGate: $checkedConvert('credit_gate', (v) => v as bool),
      storeProductIds: $checkedConvert(
        'store_product_ids',
        (v) => Map<String, String>.from(v as Map),
      ),
      dodoProductId: $checkedConvert('dodo_product_id', (v) => v as String?),
      workspaces: $checkedConvert('workspaces', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'priceLabel': 'price_label',
    'creditGate': 'credit_gate',
    'storeProductIds': 'store_product_ids',
    'dodoProductId': 'dodo_product_id',
  },
);

Map<String, dynamic> _$AdminPlanToJson(AdminPlan instance) => <String, dynamic>{
  'code': instance.code,
  'name': instance.name,
  'interval': _$AdminPlanIntervalEnumEnumMap[instance.interval]!,
  'active': instance.active,
  'sort': instance.sort,
  'price_label': instance.priceLabel,
  'limits': instance.limits,
  'credit_gate': instance.creditGate,
  'store_product_ids': instance.storeProductIds,
  'dodo_product_id': instance.dodoProductId,
  'workspaces': instance.workspaces,
};

const _$AdminPlanIntervalEnumEnumMap = {
  AdminPlanIntervalEnum.none: 'none',
  AdminPlanIntervalEnum.month: 'month',
  AdminPlanIntervalEnum.year: 'year',
};
