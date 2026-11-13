// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_credit_pack_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveCreditPackRequestCWProxy {
  SaveCreditPackRequest name(String? name);

  SaveCreditPackRequest creditsUsd(num? creditsUsd);

  SaveCreditPackRequest active(bool? active);

  SaveCreditPackRequest priceLabel(String? priceLabel);

  SaveCreditPackRequest storeProductIds(Map<String, String>? storeProductIds);

  SaveCreditPackRequest dodoProductId(String? dodoProductId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveCreditPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveCreditPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveCreditPackRequest call({
    String? name,
    num? creditsUsd,
    bool? active,
    String? priceLabel,
    Map<String, String>? storeProductIds,
    String? dodoProductId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveCreditPackRequest.copyWith(...)` or call `instanceOfSaveCreditPackRequest.copyWith.fieldName(value)` for a single field.
class _$SaveCreditPackRequestCWProxyImpl
    implements _$SaveCreditPackRequestCWProxy {
  const _$SaveCreditPackRequestCWProxyImpl(this._value);

  final SaveCreditPackRequest _value;

  @override
  SaveCreditPackRequest name(String? name) => call(name: name);

  @override
  SaveCreditPackRequest creditsUsd(num? creditsUsd) =>
      call(creditsUsd: creditsUsd);

  @override
  SaveCreditPackRequest active(bool? active) => call(active: active);

  @override
  SaveCreditPackRequest priceLabel(String? priceLabel) =>
      call(priceLabel: priceLabel);

  @override
  SaveCreditPackRequest storeProductIds(Map<String, String>? storeProductIds) =>
      call(storeProductIds: storeProductIds);

  @override
  SaveCreditPackRequest dodoProductId(String? dodoProductId) =>
      call(dodoProductId: dodoProductId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveCreditPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveCreditPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveCreditPackRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? creditsUsd = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? priceLabel = const $CopyWithPlaceholder(),
    Object? storeProductIds = const $CopyWithPlaceholder(),
    Object? dodoProductId = const $CopyWithPlaceholder(),
  }) {
    return SaveCreditPackRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      creditsUsd: creditsUsd == const $CopyWithPlaceholder()
          ? _value.creditsUsd
          // ignore: cast_nullable_to_non_nullable
          : creditsUsd as num?,
      active: active == const $CopyWithPlaceholder()
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool?,
      priceLabel: priceLabel == const $CopyWithPlaceholder()
          ? _value.priceLabel
          // ignore: cast_nullable_to_non_nullable
          : priceLabel as String?,
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

extension $SaveCreditPackRequestCopyWith on SaveCreditPackRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveCreditPackRequest.copyWith(...)` or `instanceOfSaveCreditPackRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveCreditPackRequestCWProxy get copyWith =>
      _$SaveCreditPackRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveCreditPackRequest _$SaveCreditPackRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SaveCreditPackRequest',
  json,
  ($checkedConvert) {
    final val = SaveCreditPackRequest(
      name: $checkedConvert('name', (v) => v as String?),
      creditsUsd: $checkedConvert('credits_usd', (v) => v as num?),
      active: $checkedConvert('active', (v) => v as bool?),
      priceLabel: $checkedConvert('price_label', (v) => v as String?),
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
    'creditsUsd': 'credits_usd',
    'priceLabel': 'price_label',
    'storeProductIds': 'store_product_ids',
    'dodoProductId': 'dodo_product_id',
  },
);

Map<String, dynamic> _$SaveCreditPackRequestToJson(
  SaveCreditPackRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'credits_usd': ?instance.creditsUsd,
  'active': ?instance.active,
  'price_label': ?instance.priceLabel,
  'store_product_ids': ?instance.storeProductIds,
  'dodo_product_id': ?instance.dodoProductId,
};
