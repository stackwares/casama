// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'own_coding_agent.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OwnCodingAgentCWProxy {
  OwnCodingAgent key(String key);

  OwnCodingAgent label(String label);

  OwnCodingAgent bin(String bin);

  OwnCodingAgent command(String command);

  OwnCodingAgent result(String result);

  OwnCodingAgent timeoutMin(int? timeoutMin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OwnCodingAgent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OwnCodingAgent(...).copyWith(id: 12, name: "My name")
  /// ```
  OwnCodingAgent call({
    String key,
    String label,
    String bin,
    String command,
    String result,
    int? timeoutMin,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOwnCodingAgent.copyWith(...)` or call `instanceOfOwnCodingAgent.copyWith.fieldName(value)` for a single field.
class _$OwnCodingAgentCWProxyImpl implements _$OwnCodingAgentCWProxy {
  const _$OwnCodingAgentCWProxyImpl(this._value);

  final OwnCodingAgent _value;

  @override
  OwnCodingAgent key(String key) => call(key: key);

  @override
  OwnCodingAgent label(String label) => call(label: label);

  @override
  OwnCodingAgent bin(String bin) => call(bin: bin);

  @override
  OwnCodingAgent command(String command) => call(command: command);

  @override
  OwnCodingAgent result(String result) => call(result: result);

  @override
  OwnCodingAgent timeoutMin(int? timeoutMin) => call(timeoutMin: timeoutMin);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OwnCodingAgent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OwnCodingAgent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OwnCodingAgent call({
    Object? key = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? bin = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
    Object? timeoutMin = const $CopyWithPlaceholder(),
  }) {
    return OwnCodingAgent(
      key: key == const $CopyWithPlaceholder() || key == null
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String,
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

extension $OwnCodingAgentCopyWith on OwnCodingAgent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOwnCodingAgent.copyWith(...)` or `instanceOfOwnCodingAgent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OwnCodingAgentCWProxy get copyWith => _$OwnCodingAgentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OwnCodingAgent _$OwnCodingAgentFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OwnCodingAgent', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['key', 'label', 'bin', 'command', 'result'],
      );
      final val = OwnCodingAgent(
        key: $checkedConvert('key', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        bin: $checkedConvert('bin', (v) => v as String),
        command: $checkedConvert('command', (v) => v as String),
        result: $checkedConvert('result', (v) => v as String),
        timeoutMin: $checkedConvert('timeout_min', (v) => (v as num?)?.toInt()),
      );
      return val;
    }, fieldKeyMap: const {'timeoutMin': 'timeout_min'});

Map<String, dynamic> _$OwnCodingAgentToJson(OwnCodingAgent instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'bin': instance.bin,
      'command': instance.command,
      'result': instance.result,
      'timeout_min': ?instance.timeoutMin,
    };
