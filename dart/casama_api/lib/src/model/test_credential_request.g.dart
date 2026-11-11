// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_credential_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TestCredentialRequestCWProxy {
  TestCredentialRequest model(String? model);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TestCredentialRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TestCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TestCredentialRequest call({String? model});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTestCredentialRequest.copyWith(...)` or call `instanceOfTestCredentialRequest.copyWith.fieldName(value)` for a single field.
class _$TestCredentialRequestCWProxyImpl
    implements _$TestCredentialRequestCWProxy {
  const _$TestCredentialRequestCWProxyImpl(this._value);

  final TestCredentialRequest _value;

  @override
  TestCredentialRequest model(String? model) => call(model: model);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TestCredentialRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TestCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TestCredentialRequest call({Object? model = const $CopyWithPlaceholder()}) {
    return TestCredentialRequest(
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String?,
    );
  }
}

extension $TestCredentialRequestCopyWith on TestCredentialRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTestCredentialRequest.copyWith(...)` or `instanceOfTestCredentialRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TestCredentialRequestCWProxy get copyWith =>
      _$TestCredentialRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestCredentialRequest _$TestCredentialRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TestCredentialRequest', json, ($checkedConvert) {
  final val = TestCredentialRequest(
    model: $checkedConvert('model', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$TestCredentialRequestToJson(
  TestCredentialRequest instance,
) => <String, dynamic>{'model': ?instance.model};
