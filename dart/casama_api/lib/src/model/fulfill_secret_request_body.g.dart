// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fulfill_secret_request_body.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$FulfillSecretRequestBodyCWProxy {
  FulfillSecretRequestBody value(String value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FulfillSecretRequestBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FulfillSecretRequestBody(...).copyWith(id: 12, name: "My name")
  /// ```
  FulfillSecretRequestBody call({String value});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfFulfillSecretRequestBody.copyWith(...)` or call `instanceOfFulfillSecretRequestBody.copyWith.fieldName(value)` for a single field.
class _$FulfillSecretRequestBodyCWProxyImpl
    implements _$FulfillSecretRequestBodyCWProxy {
  const _$FulfillSecretRequestBodyCWProxyImpl(this._value);

  final FulfillSecretRequestBody _value;

  @override
  FulfillSecretRequestBody value(String value) => call(value: value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `FulfillSecretRequestBody(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// FulfillSecretRequestBody(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  FulfillSecretRequestBody call({
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return FulfillSecretRequestBody(
      value: value == const $CopyWithPlaceholder() || value == null
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as String,
    );
  }
}

extension $FulfillSecretRequestBodyCopyWith on FulfillSecretRequestBody {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfFulfillSecretRequestBody.copyWith(...)` or `instanceOfFulfillSecretRequestBody.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$FulfillSecretRequestBodyCWProxy get copyWith =>
      _$FulfillSecretRequestBodyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FulfillSecretRequestBody _$FulfillSecretRequestBodyFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('FulfillSecretRequestBody', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['value']);
  final val = FulfillSecretRequestBody(
    value: $checkedConvert('value', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$FulfillSecretRequestBodyToJson(
  FulfillSecretRequestBody instance,
) => <String, dynamic>{'value': instance.value};
