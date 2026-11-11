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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CredentialTestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CredentialTestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  CredentialTestResult call({
    bool ok,
    String model,
    int latencyMs,
    String? error,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCredentialTestResult.copyWith(...)` or call `instanceOfCredentialTestResult.copyWith.fieldName(value)` for a single field.
class _$CredentialTestResultCWProxyImpl
    implements _$CredentialTestResultCWProxy {
  const _$CredentialTestResultCWProxyImpl(this._value);

  final CredentialTestResult _value;

  @override
  CredentialTestResult ok(bool ok) => call(ok: ok);

  @override
  CredentialTestResult model(String model) => call(model: model);

  @override
  CredentialTestResult latencyMs(int latencyMs) => call(latencyMs: latencyMs);

  @override
  CredentialTestResult error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CredentialTestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CredentialTestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CredentialTestResult call({
    Object? ok = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? latencyMs = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return CredentialTestResult(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      latencyMs: latencyMs == const $CopyWithPlaceholder() || latencyMs == null
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCredentialTestResult.copyWith(...)` or `instanceOfCredentialTestResult.copyWith.fieldName(...)`.
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
