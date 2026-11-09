// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_credential_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TestCredentialRequestCWProxy {
  TestCredentialRequest model(String? model);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TestCredentialRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TestCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  TestCredentialRequest call({String? model});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTestCredentialRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTestCredentialRequest.copyWith.fieldName(...)`
class _$TestCredentialRequestCWProxyImpl
    implements _$TestCredentialRequestCWProxy {
  const _$TestCredentialRequestCWProxyImpl(this._value);

  final TestCredentialRequest _value;

  @override
  TestCredentialRequest model(String? model) => this(model: model);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TestCredentialRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TestCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ````
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
  /// Returns a callable class that can be used as follows: `instanceOfTestCredentialRequest.copyWith(...)` or like so:`instanceOfTestCredentialRequest.copyWith.fieldName(...)`.
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
