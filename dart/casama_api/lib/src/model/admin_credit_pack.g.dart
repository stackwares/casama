// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_credit_pack.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminCreditPackCWProxy {
  AdminCreditPack code(String code);

  AdminCreditPack name(String name);

  AdminCreditPack creditsUsd(num creditsUsd);

  AdminCreditPack active(bool active);

  AdminCreditPack priceLabel(String? priceLabel);

  AdminCreditPack storeProductIds(Map<String, String> storeProductIds);

  AdminCreditPack dodoProductId(String? dodoProductId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCreditPack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCreditPack(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminCreditPack call({
    String code,
    String name,
    num creditsUsd,
    bool active,
    String? priceLabel,
    Map<String, String> storeProductIds,
    String? dodoProductId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminCreditPack.copyWith(...)` or call `instanceOfAdminCreditPack.copyWith.fieldName(value)` for a single field.
class _$AdminCreditPackCWProxyImpl implements _$AdminCreditPackCWProxy {
  const _$AdminCreditPackCWProxyImpl(this._value);

  final AdminCreditPack _value;

  @override
  AdminCreditPack code(String code) => call(code: code);

  @override
  AdminCreditPack name(String name) => call(name: name);

  @override
  AdminCreditPack creditsUsd(num creditsUsd) => call(creditsUsd: creditsUsd);

  @override
  AdminCreditPack active(bool active) => call(active: active);

  @override
  AdminCreditPack priceLabel(String? priceLabel) =>
      call(priceLabel: priceLabel);

  @override
  AdminCreditPack storeProductIds(Map<String, String> storeProductIds) =>
      call(storeProductIds: storeProductIds);

  @override
  AdminCreditPack dodoProductId(String? dodoProductId) =>
      call(dodoProductId: dodoProductId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminCreditPack(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminCreditPack(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminCreditPack call({
    Object? code = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? creditsUsd = const $CopyWithPlaceholder(),
    Object? active = const $CopyWithPlaceholder(),
    Object? priceLabel = const $CopyWithPlaceholder(),
    Object? storeProductIds = const $CopyWithPlaceholder(),
    Object? dodoProductId = const $CopyWithPlaceholder(),
  }) {
    return AdminCreditPack(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      creditsUsd:
          creditsUsd == const $CopyWithPlaceholder() || creditsUsd == null
          ? _value.creditsUsd
          // ignore: cast_nullable_to_non_nullable
          : creditsUsd as num,
      active: active == const $CopyWithPlaceholder() || active == null
          ? _value.active
          // ignore: cast_nullable_to_non_nullable
          : active as bool,
      priceLabel: priceLabel == const $CopyWithPlaceholder()
          ? _value.priceLabel
          // ignore: cast_nullable_to_non_nullable
          : priceLabel as String?,
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
    );
  }
}

extension $AdminCreditPackCopyWith on AdminCreditPack {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminCreditPack.copyWith(...)` or `instanceOfAdminCreditPack.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminCreditPackCWProxy get copyWith => _$AdminCreditPackCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminCreditPack _$AdminCreditPackFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AdminCreditPack',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'code',
            'name',
            'credits_usd',
            'active',
            'price_label',
            'store_product_ids',
            'dodo_product_id',
          ],
        );
        final val = AdminCreditPack(
          code: $checkedConvert('code', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          creditsUsd: $checkedConvert('credits_usd', (v) => v as num),
          active: $checkedConvert('active', (v) => v as bool),
          priceLabel: $checkedConvert('price_label', (v) => v as String?),
          storeProductIds: $checkedConvert(
            'store_product_ids',
            (v) => Map<String, String>.from(v as Map),
          ),
          dodoProductId: $checkedConvert(
            'dodo_product_id',
            (v) => v as String?,
          ),
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

Map<String, dynamic> _$AdminCreditPackToJson(AdminCreditPack instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'credits_usd': instance.creditsUsd,
      'active': instance.active,
      'price_label': instance.priceLabel,
      'store_product_ids': instance.storeProductIds,
      'dodo_product_id': instance.dodoProductId,
    };
