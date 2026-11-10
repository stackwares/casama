// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_request_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PaymentRequestListCWProxy {
  PaymentRequestList items(List<PaymentRequest> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  PaymentRequestList call({List<PaymentRequest> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPaymentRequestList.copyWith(...)` or call `instanceOfPaymentRequestList.copyWith.fieldName(value)` for a single field.
class _$PaymentRequestListCWProxyImpl implements _$PaymentRequestListCWProxy {
  const _$PaymentRequestListCWProxyImpl(this._value);

  final PaymentRequestList _value;

  @override
  PaymentRequestList items(List<PaymentRequest> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PaymentRequestList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PaymentRequestList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PaymentRequestList call({Object? items = const $CopyWithPlaceholder()}) {
    return PaymentRequestList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<PaymentRequest>,
    );
  }
}

extension $PaymentRequestListCopyWith on PaymentRequestList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPaymentRequestList.copyWith(...)` or `instanceOfPaymentRequestList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PaymentRequestListCWProxy get copyWith =>
      _$PaymentRequestListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentRequestList _$PaymentRequestListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PaymentRequestList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PaymentRequestList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => PaymentRequest.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PaymentRequestListToJson(PaymentRequestList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
