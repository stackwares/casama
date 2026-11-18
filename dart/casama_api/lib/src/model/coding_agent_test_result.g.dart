// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coding_agent_test_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CodingAgentTestResultCWProxy {
  CodingAgentTestResult ok(bool ok);

  CodingAgentTestResult exitCode(int exitCode);

  CodingAgentTestResult timedOut(bool timedOut);

  CodingAgentTestResult reply(String reply);

  CodingAgentTestResult output(String output);

  CodingAgentTestResult command(String command);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodingAgentTestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodingAgentTestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  CodingAgentTestResult call({
    bool ok,
    int exitCode,
    bool timedOut,
    String reply,
    String output,
    String command,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCodingAgentTestResult.copyWith(...)` or call `instanceOfCodingAgentTestResult.copyWith.fieldName(value)` for a single field.
class _$CodingAgentTestResultCWProxyImpl
    implements _$CodingAgentTestResultCWProxy {
  const _$CodingAgentTestResultCWProxyImpl(this._value);

  final CodingAgentTestResult _value;

  @override
  CodingAgentTestResult ok(bool ok) => call(ok: ok);

  @override
  CodingAgentTestResult exitCode(int exitCode) => call(exitCode: exitCode);

  @override
  CodingAgentTestResult timedOut(bool timedOut) => call(timedOut: timedOut);

  @override
  CodingAgentTestResult reply(String reply) => call(reply: reply);

  @override
  CodingAgentTestResult output(String output) => call(output: output);

  @override
  CodingAgentTestResult command(String command) => call(command: command);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CodingAgentTestResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CodingAgentTestResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CodingAgentTestResult call({
    Object? ok = const $CopyWithPlaceholder(),
    Object? exitCode = const $CopyWithPlaceholder(),
    Object? timedOut = const $CopyWithPlaceholder(),
    Object? reply = const $CopyWithPlaceholder(),
    Object? output = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
  }) {
    return CodingAgentTestResult(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
      exitCode: exitCode == const $CopyWithPlaceholder() || exitCode == null
          ? _value.exitCode
          // ignore: cast_nullable_to_non_nullable
          : exitCode as int,
      timedOut: timedOut == const $CopyWithPlaceholder() || timedOut == null
          ? _value.timedOut
          // ignore: cast_nullable_to_non_nullable
          : timedOut as bool,
      reply: reply == const $CopyWithPlaceholder() || reply == null
          ? _value.reply
          // ignore: cast_nullable_to_non_nullable
          : reply as String,
      output: output == const $CopyWithPlaceholder() || output == null
          ? _value.output
          // ignore: cast_nullable_to_non_nullable
          : output as String,
      command: command == const $CopyWithPlaceholder() || command == null
          ? _value.command
          // ignore: cast_nullable_to_non_nullable
          : command as String,
    );
  }
}

extension $CodingAgentTestResultCopyWith on CodingAgentTestResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCodingAgentTestResult.copyWith(...)` or `instanceOfCodingAgentTestResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CodingAgentTestResultCWProxy get copyWith =>
      _$CodingAgentTestResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodingAgentTestResult _$CodingAgentTestResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CodingAgentTestResult', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'ok',
      'exit_code',
      'timed_out',
      'reply',
      'output',
      'command',
    ],
  );
  final val = CodingAgentTestResult(
    ok: $checkedConvert('ok', (v) => v as bool),
    exitCode: $checkedConvert('exit_code', (v) => (v as num).toInt()),
    timedOut: $checkedConvert('timed_out', (v) => v as bool),
    reply: $checkedConvert('reply', (v) => v as String),
    output: $checkedConvert('output', (v) => v as String),
    command: $checkedConvert('command', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'exitCode': 'exit_code', 'timedOut': 'timed_out'});

Map<String, dynamic> _$CodingAgentTestResultToJson(
  CodingAgentTestResult instance,
) => <String, dynamic>{
  'ok': instance.ok,
  'exit_code': instance.exitCode,
  'timed_out': instance.timedOut,
  'reply': instance.reply,
  'output': instance.output,
  'command': instance.command,
};
