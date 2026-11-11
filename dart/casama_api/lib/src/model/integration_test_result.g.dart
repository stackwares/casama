// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_test_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationTestResultCWProxy {
  IntegrationTestResult ok(bool ok);

  IntegrationTestResult tools(List<String> tools);

  IntegrationTestResult error(String? error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationTestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationTestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  IntegrationTestResult call({bool ok, List<String> tools, String? error});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIntegrationTestResult.copyWith(...)` or call `instanceOfIntegrationTestResult.copyWith.fieldName(value)` for a single field.
class _$IntegrationTestResultCWProxyImpl
    implements _$IntegrationTestResultCWProxy {
  const _$IntegrationTestResultCWProxyImpl(this._value);

  final IntegrationTestResult _value;

  @override
  IntegrationTestResult ok(bool ok) => call(ok: ok);

  @override
  IntegrationTestResult tools(List<String> tools) => call(tools: tools);

  @override
  IntegrationTestResult error(String? error) => call(error: error);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationTestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationTestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IntegrationTestResult call({
    Object? ok = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return IntegrationTestResult(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
      tools: tools == const $CopyWithPlaceholder() || tools == null
          ? _value.tools
          // ignore: cast_nullable_to_non_nullable
          : tools as List<String>,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
    );
  }
}

extension $IntegrationTestResultCopyWith on IntegrationTestResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIntegrationTestResult.copyWith(...)` or `instanceOfIntegrationTestResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IntegrationTestResultCWProxy get copyWith =>
      _$IntegrationTestResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationTestResult _$IntegrationTestResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('IntegrationTestResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['ok', 'tools']);
  final val = IntegrationTestResult(
    ok: $checkedConvert('ok', (v) => v as bool),
    tools: $checkedConvert(
      'tools',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    error: $checkedConvert('error', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$IntegrationTestResultToJson(
  IntegrationTestResult instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'tools': instance.tools,
  'error': ?instance.error,
};
