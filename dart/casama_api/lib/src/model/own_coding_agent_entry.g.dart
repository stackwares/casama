// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'own_coding_agent_entry.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OwnCodingAgentEntryCWProxy {
  OwnCodingAgentEntry key(String key);

  OwnCodingAgentEntry label(String label);

  OwnCodingAgentEntry bin(String bin);

  OwnCodingAgentEntry command(String command);

  OwnCodingAgentEntry result(String result);

  OwnCodingAgentEntry timeoutMin(int? timeoutMin);

  OwnCodingAgentEntry id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OwnCodingAgentEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OwnCodingAgentEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  OwnCodingAgentEntry call({
    String key,
    String label,
    String bin,
    String command,
    String result,
    int? timeoutMin,
    String id,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOwnCodingAgentEntry.copyWith(...)` or call `instanceOfOwnCodingAgentEntry.copyWith.fieldName(value)` for a single field.
class _$OwnCodingAgentEntryCWProxyImpl implements _$OwnCodingAgentEntryCWProxy {
  const _$OwnCodingAgentEntryCWProxyImpl(this._value);

  final OwnCodingAgentEntry _value;

  @override
  OwnCodingAgentEntry key(String key) => call(key: key);

  @override
  OwnCodingAgentEntry label(String label) => call(label: label);

  @override
  OwnCodingAgentEntry bin(String bin) => call(bin: bin);

  @override
  OwnCodingAgentEntry command(String command) => call(command: command);

  @override
  OwnCodingAgentEntry result(String result) => call(result: result);

  @override
  OwnCodingAgentEntry timeoutMin(int? timeoutMin) =>
      call(timeoutMin: timeoutMin);

  @override
  OwnCodingAgentEntry id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OwnCodingAgentEntry(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OwnCodingAgentEntry(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OwnCodingAgentEntry call({
    Object? key = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? bin = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
    Object? result = const $CopyWithPlaceholder(),
    Object? timeoutMin = const $CopyWithPlaceholder(),
    Object? id = const $CopyWithPlaceholder(),
  }) {
    return OwnCodingAgentEntry(
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
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $OwnCodingAgentEntryCopyWith on OwnCodingAgentEntry {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOwnCodingAgentEntry.copyWith(...)` or `instanceOfOwnCodingAgentEntry.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OwnCodingAgentEntryCWProxy get copyWith =>
      _$OwnCodingAgentEntryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OwnCodingAgentEntry _$OwnCodingAgentEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OwnCodingAgentEntry', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['key', 'label', 'bin', 'command', 'result', 'id'],
      );
      final val = OwnCodingAgentEntry(
        key: $checkedConvert('key', (v) => v as String),
        label: $checkedConvert('label', (v) => v as String),
        bin: $checkedConvert('bin', (v) => v as String),
        command: $checkedConvert('command', (v) => v as String),
        result: $checkedConvert('result', (v) => v as String),
        timeoutMin: $checkedConvert('timeout_min', (v) => (v as num?)?.toInt()),
        id: $checkedConvert('id', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'timeoutMin': 'timeout_min'});

Map<String, dynamic> _$OwnCodingAgentEntryToJson(
  OwnCodingAgentEntry instance,
) => <String, dynamic>{
  'key': instance.key,
  'label': instance.label,
  'bin': instance.bin,
  'command': instance.command,
  'result': instance.result,
  'timeout_min': ?instance.timeoutMin,
  'id': instance.id,
};
