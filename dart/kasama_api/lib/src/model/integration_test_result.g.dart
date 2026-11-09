// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_test_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationTestResultCWProxy {
  IntegrationTestResult ok(bool ok);

  IntegrationTestResult tools(List<String> tools);

  IntegrationTestResult error(String? error);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntegrationTestResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntegrationTestResult(...).copyWith(id: 12, name: "My name")
  /// ````
  IntegrationTestResult call({bool ok, List<String> tools, String? error});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIntegrationTestResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIntegrationTestResult.copyWith.fieldName(...)`
class _$IntegrationTestResultCWProxyImpl
    implements _$IntegrationTestResultCWProxy {
  const _$IntegrationTestResultCWProxyImpl(this._value);

  final IntegrationTestResult _value;

  @override
  IntegrationTestResult ok(bool ok) => this(ok: ok);

  @override
  IntegrationTestResult tools(List<String> tools) => this(tools: tools);

  @override
  IntegrationTestResult error(String? error) => this(error: error);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntegrationTestResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntegrationTestResult(...).copyWith(id: 12, name: "My name")
  /// ````
  IntegrationTestResult call({
    Object? ok = const $CopyWithPlaceholder(),
    Object? tools = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
  }) {
    return IntegrationTestResult(
      ok: ok == const $CopyWithPlaceholder()
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
      tools: tools == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfIntegrationTestResult.copyWith(...)` or like so:`instanceOfIntegrationTestResult.copyWith.fieldName(...)`.
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
