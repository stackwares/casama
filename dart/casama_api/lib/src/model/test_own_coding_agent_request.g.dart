// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_own_coding_agent_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TestOwnCodingAgentRequestCWProxy {
  TestOwnCodingAgentRequest label(String label);

  TestOwnCodingAgentRequest bin(String bin);

  TestOwnCodingAgentRequest command(String command);

  TestOwnCodingAgentRequest result(String result);

  TestOwnCodingAgentRequest timeoutMin(int? timeoutMin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TestOwnCodingAgentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TestOwnCodingAgentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  TestOwnCodingAgentRequest call({
    String label,
    String bin,
    String command,
    String result,
    int? timeoutMin,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTestOwnCodingAgentRequest.copyWith(...)` or call `instanceOfTestOwnCodingAgentRequest.copyWith.fieldName(value)` for a single field.
class _$TestOwnCodingAgentRequestCWProxyImpl
    implements _$TestOwnCodingAgentRequestCWProxy {
  const _$TestOwnCodingAgentRequestCWProxyImpl(this._value);

  final TestOwnCodingAgentRequest _value;

  @override
  TestOwnCodingAgentRequest label(String label) => call(label: label);

  @override
  TestOwnCodingAgentRequest bin(String bin) => call(bin: bin);

  @override
  TestOwnCodingAgentRequest command(String command) => call(command: command);

  @override
  TestOwnCodingAgentRequest result(String result) => call(result: result);

  @override
  TestOwnCodingAgentRequest timeoutMin(int? timeoutMin) =>
      call(timeoutMin: timeoutMin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TestOwnCodingAgentRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TestOwnCodingAgentRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TestOwnCodingAgentRequest call({
    Object? label = const $CopyWithPlaceholder(),
    Object? bin = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
    Object? timeoutMin = const $CopyWithPlaceholder(),
  }) {
    return TestOwnCodingAgentRequest(
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      bin: bin == const $CopyWithPlaceholder() || bin == null
          ? _value.bin
          // ignore: cast_nullable_to_non_nullable
          : bin as String,
      command: command == const $CopyWithPlaceholder() || command == null
          ? _value.command
          // ignore: cast_nullable_to_non_nullable
          : command as String,
      result: result == const $CopyWithPlaceholder() || result == null
          ? _value.result
          // ignore: cast_nullable_to_non_nullable
          : result as String,
      timeoutMin: timeoutMin == const $CopyWithPlaceholder()
          ? _value.timeoutMin
          // ignore: cast_nullable_to_non_nullable
          : timeoutMin as int?,
    );
  }
}

extension $TestOwnCodingAgentRequestCopyWith on TestOwnCodingAgentRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTestOwnCodingAgentRequest.copyWith(...)` or `instanceOfTestOwnCodingAgentRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TestOwnCodingAgentRequestCWProxy get copyWith =>
      _$TestOwnCodingAgentRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TestOwnCodingAgentRequest _$TestOwnCodingAgentRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TestOwnCodingAgentRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['label', 'bin', 'command', 'result']);
  final val = TestOwnCodingAgentRequest(
    label: $checkedConvert('label', (v) => v as String),
    bin: $checkedConvert('bin', (v) => v as String),
    command: $checkedConvert('command', (v) => v as String),
    result: $checkedConvert('result', (v) => v as String),
    timeoutMin: $checkedConvert('timeout_min', (v) => (v as num?)?.toInt()),
  );
  return val;
}, fieldKeyMap: const {'timeoutMin': 'timeout_min'});

Map<String, dynamic> _$TestOwnCodingAgentRequestToJson(
  TestOwnCodingAgentRequest instance,
) => <String, dynamic>{
  'label': instance.label,
  'bin': instance.bin,
  'command': instance.command,
  'result': instance.result,
  'timeout_min': ?instance.timeoutMin,
};
