// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential_test_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CredentialTestResultCWProxy {
  CredentialTestResult ok(bool ok);

  CredentialTestResult model(String model);

  CredentialTestResult latencyMs(int latencyMs);

  CredentialTestResult error(String? error);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CredentialTestResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CredentialTestResult(...).copyWith(id: 12, name: "My name")
  /// ````
  CredentialTestResult call({
    bool ok,
    String model,
    int latencyMs,
    String? error,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCredentialTestResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCredentialTestResult.copyWith.fieldName(...)`
class _$CredentialTestResultCWProxyImpl
    implements _$CredentialTestResultCWProxy {
  const _$CredentialTestResultCWProxyImpl(this._value);

  final CredentialTestResult _value;

  @override
  CredentialTestResult ok(bool ok) => this(ok: ok);

  @override
  CredentialTestResult model(String model) => this(model: model);

  @override
  CredentialTestResult latencyMs(int latencyMs) => this(latencyMs: latencyMs);

  @override
  CredentialTestResult error(String? error) => this(error: error);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CredentialTestResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CredentialTestResult(...).copyWith(id: 12, name: "My name")
  /// ````
  CredentialTestResult call({
    Object? ok = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? latencyMs = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return CredentialTestResult(
      ok: ok == const $CopyWithPlaceholder()
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      latencyMs: latencyMs == const $CopyWithPlaceholder()
          ? _value.latencyMs
          // ignore: cast_nullable_to_non_nullable
          : latencyMs as int,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $CredentialTestResultCopyWith on CredentialTestResult {
  /// Returns a callable class that can be used as follows: `instanceOfCredentialTestResult.copyWith(...)` or like so:`instanceOfCredentialTestResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CredentialTestResultCWProxy get copyWith =>
      _$CredentialTestResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredentialTestResult _$CredentialTestResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CredentialTestResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['ok', 'model', 'latency_ms']);
  final val = CredentialTestResult(
    ok: $checkedConvert('ok', (v) => v as bool),
    model: $checkedConvert('model', (v) => v as String),
    latencyMs: $checkedConvert('latency_ms', (v) => (v as num).toInt()),
    error: $checkedConvert('error', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'latencyMs': 'latency_ms'});

Map<String, dynamic> _$CredentialTestResultToJson(
  CredentialTestResult instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'model': instance.model,
  'latency_ms': instance.latencyMs,
  'error': ?instance.error,
};
