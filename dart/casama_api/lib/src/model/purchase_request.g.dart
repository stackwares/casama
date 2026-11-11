// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PurchaseRequestCWProxy {
  PurchaseRequest source_(PurchaseRequestSource_Enum source_);

  PurchaseRequest productId(String productId);

  PurchaseRequest transactionId(String? transactionId);

  PurchaseRequest purchaseToken(String? purchaseToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PurchaseRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PurchaseRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PurchaseRequest call({
    PurchaseRequestSource_Enum source_,
    String productId,
    String? transactionId,
    String? purchaseToken,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPurchaseRequest.copyWith(...)` or call `instanceOfPurchaseRequest.copyWith.fieldName(value)` for a single field.
class _$PurchaseRequestCWProxyImpl implements _$PurchaseRequestCWProxy {
  const _$PurchaseRequestCWProxyImpl(this._value);

  final PurchaseRequest _value;

  @override
  PurchaseRequest source_(PurchaseRequestSource_Enum source_) =>
      call(source_: source_);

  @override
  PurchaseRequest productId(String productId) => call(productId: productId);

  @override
  PurchaseRequest transactionId(String? transactionId) =>
      call(transactionId: transactionId);

  @override
  PurchaseRequest purchaseToken(String? purchaseToken) =>
      call(purchaseToken: purchaseToken);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PurchaseRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PurchaseRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PurchaseRequest call({
    Object? source_ = const $CopyWithPlaceholder(),
    Object? productId = const $CopyWithPlaceholder(),
    Object? transactionId = const $CopyWithPlaceholder(),
    Object? purchaseToken = const $CopyWithPlaceholder(),
  }) {
    return PurchaseRequest(
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as PurchaseRequestSource_Enum,
      productId: productId == const $CopyWithPlaceholder() || productId == null
          ? _value.productId
          // ignore: cast_nullable_to_non_nullable
          : productId as String,
      transactionId: transactionId == const $CopyWithPlaceholder()
          ? _value.transactionId
          // ignore: cast_nullable_to_non_nullable
          : transactionId as String?,
      purchaseToken: purchaseToken == const $CopyWithPlaceholder()
          ? _value.purchaseToken
          // ignore: cast_nullable_to_non_nullable
          : purchaseToken as String?,
    );
  }
}

extension $PurchaseRequestCopyWith on PurchaseRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPurchaseRequest.copyWith(...)` or `instanceOfPurchaseRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PurchaseRequestCWProxy get copyWith => _$PurchaseRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseRequest _$PurchaseRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PurchaseRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['source', 'product_id']);
        final val = PurchaseRequest(
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$PurchaseRequestSource_EnumEnumMap, v),
          ),
          productId: $checkedConvert('product_id', (v) => v as String),
          transactionId: $checkedConvert('transaction_id', (v) => v as String?),
          purchaseToken: $checkedConvert('purchase_token', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'source_': 'source',
        'productId': 'product_id',
        'transactionId': 'transaction_id',
        'purchaseToken': 'purchase_token',
      },
    );

Map<String, dynamic> _$PurchaseRequestToJson(PurchaseRequest instance) =>
    <String, dynamic>{
      'source': _$PurchaseRequestSource_EnumEnumMap[instance.source_]!,
      'product_id': instance.productId,
      'transaction_id': ?instance.transactionId,
      'purchase_token': ?instance.purchaseToken,
    };

const _$PurchaseRequestSource_EnumEnumMap = {
  PurchaseRequestSource_Enum.appStore: 'app_store',
  PurchaseRequestSource_Enum.googlePlay: 'google_play',
};
