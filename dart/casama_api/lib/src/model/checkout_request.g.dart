// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckoutRequestCWProxy {
  CheckoutRequest planCode(String? planCode);

  CheckoutRequest packCode(String? packCode);

  CheckoutRequest returnUrl(String? returnUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckoutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckoutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CheckoutRequest call({String? planCode, String? packCode, String? returnUrl});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCheckoutRequest.copyWith(...)` or call `instanceOfCheckoutRequest.copyWith.fieldName(value)` for a single field.
class _$CheckoutRequestCWProxyImpl implements _$CheckoutRequestCWProxy {
  const _$CheckoutRequestCWProxyImpl(this._value);

  final CheckoutRequest _value;

  @override
  CheckoutRequest planCode(String? planCode) => call(planCode: planCode);

  @override
  CheckoutRequest packCode(String? packCode) => call(packCode: packCode);

  @override
  CheckoutRequest returnUrl(String? returnUrl) => call(returnUrl: returnUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckoutRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckoutRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CheckoutRequest call({
    Object? planCode = const $CopyWithPlaceholder(),
    Object? packCode = const $CopyWithPlaceholder(),
    Object? returnUrl = const $CopyWithPlaceholder(),
  }) {
    return CheckoutRequest(
      planCode: planCode == const $CopyWithPlaceholder()
          ? _value.planCode
          // ignore: cast_nullable_to_non_nullable
          : planCode as String?,
      packCode: packCode == const $CopyWithPlaceholder()
          ? _value.packCode
          // ignore: cast_nullable_to_non_nullable
          : packCode as String?,
      returnUrl: returnUrl == const $CopyWithPlaceholder()
          ? _value.returnUrl
          // ignore: cast_nullable_to_non_nullable
          : returnUrl as String?,
    );
  }
}

extension $CheckoutRequestCopyWith on CheckoutRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCheckoutRequest.copyWith(...)` or `instanceOfCheckoutRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckoutRequestCWProxy get copyWith => _$CheckoutRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckoutRequest _$CheckoutRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CheckoutRequest',
      json,
      ($checkedConvert) {
        final val = CheckoutRequest(
          planCode: $checkedConvert('plan_code', (v) => v as String?),
          packCode: $checkedConvert('pack_code', (v) => v as String?),
          returnUrl: $checkedConvert('return_url', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'planCode': 'plan_code',
        'packCode': 'pack_code',
        'returnUrl': 'return_url',
      },
    );

Map<String, dynamic> _$CheckoutRequestToJson(CheckoutRequest instance) =>
    <String, dynamic>{
      'plan_code': ?instance.planCode,
      'pack_code': ?instance.packCode,
      'return_url': ?instance.returnUrl,
    };
