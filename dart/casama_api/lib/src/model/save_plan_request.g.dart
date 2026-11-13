// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_plan_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SavePlanRequestCWProxy {
  SavePlanRequest name(String? name);

  SavePlanRequest interval(SavePlanRequestIntervalEnum? interval);

  SavePlanRequest active(bool? active);

  SavePlanRequest sort(int? sort);

  SavePlanRequest priceLabel(String? priceLabel);

  SavePlanRequest limits(Map<String, num>? limits);

  SavePlanRequest creditGate(bool? creditGate);

  SavePlanRequest storeProductIds(Map<String, String>? storeProductIds);

  SavePlanRequest dodoProductId(String? dodoProductId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavePlanRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavePlanRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SavePlanRequest call({
    String? name,
    SavePlanRequestIntervalEnum? interval,
    bool? active,
    int? sort,
    String? priceLabel,
    Map<String, num>? limits,
    bool? creditGate,
    Map<String, String>? storeProductIds,
    String? dodoProductId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSavePlanRequest.copyWith(...)` or call `instanceOfSavePlanRequest.copyWith.fieldName(value)` for a single field.
class _$SavePlanRequestCWProxyImpl implements _$SavePlanRequestCWProxy {
  const _$SavePlanRequestCWProxyImpl(this._value);

  final SavePlanRequest _value;

  @override
  SavePlanRequest name(String? name) => call(name: name);

  @override
  SavePlanRequest interval(SavePlanRequestIntervalEnum? interval) =>
      call(interval: interval);

  @override
  SavePlanRequest active(bool? active) => call(active: active);

  @override
  SavePlanRequest sort(int? sort) => call(sort: sort);

  @override
  SavePlanRequest priceLabel(String? priceLabel) =>
      call(priceLabel: priceLabel);

  @override
  SavePlanRequest limits(Map<String, num>? limits) => call(limits: limits);

  @override
  SavePlanRequest creditGate(bool? creditGate) => call(creditGate: creditGate);

  @override
  SavePlanRequest storeProductIds(Map<String, String>? storeProductIds) =>
      call(storeProductIds: storeProductIds);

  @override
  SavePlanRequest dodoProductId(String? dodoProductId) =>
      call(dodoProductId: dodoProductId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SavePlanRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SavePlanRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SavePlanRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? interval = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? sort = const $CopyWithPlaceholder(),
    Object? priceLabel = const $CopyWithPlaceholder(),
    Object? limits = const $CopyWithPlaceholder(),
    Object? creditGate = const $CopyWithPlaceholder(),
    Object? storeProductIds = const $CopyWithPlaceholder(),
    Object? dodoProductId = const $CopyWithPlaceholder(),
  }) {
    return SavePlanRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      interval: interval == const $CopyWithPlaceholder()
          ? _value.interval
          // ignore: cast_nullable_to_non_nullable
          : interval as SavePlanRequestIntervalEnum?,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool?,
      sort: sort == const $CopyWithPlaceholder()
          ? _value.sort
          // ignore: cast_nullable_to_non_nullable
          : sort as int?,
      priceLabel: priceLabel == const $CopyWithPlaceholder()
          ? _value.priceLabel
          // ignore: cast_nullable_to_non_nullable
          : priceLabel as String?,
      limits: limits == const $CopyWithPlaceholder()
          ? _value.limits
          // ignore: cast_nullable_to_non_nullable
          : limits as Map<String, num>?,
      creditGate: creditGate == const $CopyWithPlaceholder()
          ? _value.creditGate
          // ignore: cast_nullable_to_non_nullable
          : creditGate as bool?,
      storeProductIds: storeProductIds == const $CopyWithPlaceholder()
          ? _value.storeProductIds
          // ignore: cast_nullable_to_non_nullable
          : storeProductIds as Map<String, String>?,
      dodoProductId: dodoProductId == const $CopyWithPlaceholder()
          ? _value.dodoProductId
          // ignore: cast_nullable_to_non_nullable
          : dodoProductId as String?,
    );
  }
}

extension $SavePlanRequestCopyWith on SavePlanRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSavePlanRequest.copyWith(...)` or `instanceOfSavePlanRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SavePlanRequestCWProxy get copyWith => _$SavePlanRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SavePlanRequest _$SavePlanRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SavePlanRequest',
  json,
  ($checkedConvert) {
    final val = SavePlanRequest(
      name: $checkedConvert('name', (v) => v as String?),
      interval: $checkedConvert(
        'interval',
        (v) => $enumDecodeNullable(_$SavePlanRequestIntervalEnumEnumMap, v),
      ),
      active: $checkedConvert('active', (v) => v as bool?),
      sort: $checkedConvert('sort', (v) => (v as num?)?.toInt()),
      priceLabel: $checkedConvert('price_label', (v) => v as String?),
      limits: $checkedConvert(
        'limits',
        (v) =>
            (v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as num)),
      ),
      creditGate: $checkedConvert('credit_gate', (v) => v as bool?),
      storeProductIds: $checkedConvert(
        'store_product_ids',
        (v) => (v as Map<String, dynamic>?)?.map(
          (k, e) => MapEntry(k, e as String),
        ),
      ),
      dodoProductId: $checkedConvert('dodo_product_id', (v) => v as String?),
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

Map<String, dynamic> _$SavePlanRequestToJson(SavePlanRequest instance) =>
    <String, dynamic>{
      'name': ?instance.name,
      'interval': ?_$SavePlanRequestIntervalEnumEnumMap[instance.interval],
      'active': ?instance.active,
      'sort': ?instance.sort,
      'price_label': ?instance.priceLabel,
      'limits': ?instance.limits,
      'credit_gate': ?instance.creditGate,
      'store_product_ids': ?instance.storeProductIds,
      'dodo_product_id': ?instance.dodoProductId,
    };

const _$SavePlanRequestIntervalEnumEnumMap = {
  SavePlanRequestIntervalEnum.none: 'none',
  SavePlanRequestIntervalEnum.month: 'month',
  SavePlanRequestIntervalEnum.year: 'year',
};
