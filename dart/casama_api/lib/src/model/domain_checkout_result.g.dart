// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_checkout_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainCheckoutResultCWProxy {
  DomainCheckoutResult order(DomainOrder order);

  DomainCheckoutResult checkoutUrl(String? checkoutUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainCheckoutResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainCheckoutResult(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainCheckoutResult call({DomainOrder order, String? checkoutUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainCheckoutResult.copyWith(...)` or call `instanceOfDomainCheckoutResult.copyWith.fieldName(value)` for a single field.
class _$DomainCheckoutResultCWProxyImpl
    implements _$DomainCheckoutResultCWProxy {
  const _$DomainCheckoutResultCWProxyImpl(this._value);

  final DomainCheckoutResult _value;

  @override
  DomainCheckoutResult order(DomainOrder order) => call(order: order);

  @override
  DomainCheckoutResult checkoutUrl(String? checkoutUrl) =>
      call(checkoutUrl: checkoutUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainCheckoutResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainCheckoutResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainCheckoutResult call({
    Object? order = const $CopyWithPlaceholder(),
    Object? checkoutUrl = const $CopyWithPlaceholder(),
  }) {
    return DomainCheckoutResult(
      order: order == const $CopyWithPlaceholder() || order == null
          ? _value.order
          // ignore: cast_nullable_to_non_nullable
          : order as DomainOrder,
      checkoutUrl: checkoutUrl == const $CopyWithPlaceholder()
          ? _value.checkoutUrl
          // ignore: cast_nullable_to_non_nullable
          : checkoutUrl as String?,
    );
  }
}

extension $DomainCheckoutResultCopyWith on DomainCheckoutResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainCheckoutResult.copyWith(...)` or `instanceOfDomainCheckoutResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainCheckoutResultCWProxy get copyWith =>
      _$DomainCheckoutResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainCheckoutResult _$DomainCheckoutResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DomainCheckoutResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['order', 'checkout_url']);
  final val = DomainCheckoutResult(
    order: $checkedConvert(
      'order',
      (v) => DomainOrder.fromJson(v as Map<String, dynamic>),
    ),
    checkoutUrl: $checkedConvert('checkout_url', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'checkoutUrl': 'checkout_url'});

Map<String, dynamic> _$DomainCheckoutResultToJson(
  DomainCheckoutResult instance,
) => <String, dynamic>{
  'order': instance.order.toJson(),
  'checkout_url': instance.checkoutUrl,
};
