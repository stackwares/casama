// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_process.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerProcessCWProxy {
  ComputerProcess pid(int pid);

  ComputerProcess name(String name);

  ComputerProcess command(String command);

  ComputerProcess cpuPercent(num cpuPercent);

  ComputerProcess memoryBytes(int memoryBytes);

  ComputerProcess elapsedSeconds(int elapsedSeconds);

  ComputerProcess system(bool system);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerProcess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerProcess(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerProcess call({
    int pid,
    String name,
    String command,
    num cpuPercent,
    int memoryBytes,
    int elapsedSeconds,
    bool system,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerProcess.copyWith(...)` or call `instanceOfComputerProcess.copyWith.fieldName(value)` for a single field.
class _$ComputerProcessCWProxyImpl implements _$ComputerProcessCWProxy {
  const _$ComputerProcessCWProxyImpl(this._value);

  final ComputerProcess _value;

  @override
  ComputerProcess pid(int pid) => call(pid: pid);

  @override
  ComputerProcess name(String name) => call(name: name);

  @override
  ComputerProcess command(String command) => call(command: command);

  @override
  ComputerProcess cpuPercent(num cpuPercent) => call(cpuPercent: cpuPercent);

  @override
  ComputerProcess memoryBytes(int memoryBytes) =>
      call(memoryBytes: memoryBytes);

  @override
  ComputerProcess elapsedSeconds(int elapsedSeconds) =>
      call(elapsedSeconds: elapsedSeconds);

  @override
  ComputerProcess system(bool system) => call(system: system);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerProcess(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerProcess(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerProcess call({
    Object? pid = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? command = const $CopyWithPlaceholder(),
    Object? cpuPercent = const $CopyWithPlaceholder(),
    Object? memoryBytes = const $CopyWithPlaceholder(),
    Object? elapsedSeconds = const $CopyWithPlaceholder(),
    Object? system = const $CopyWithPlaceholder(),
  }) {
    return ComputerProcess(
      pid: pid == const $CopyWithPlaceholder() || pid == null
          ? _value.pid
          // ignore: cast_nullable_to_non_nullable
          : pid as int,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      command: command == const $CopyWithPlaceholder() || command == null
          ? _value.command
          // ignore: cast_nullable_to_non_nullable
          : command as String,
      cpuPercent:
          cpuPercent == const $CopyWithPlaceholder() || cpuPercent == null
          ? _value.cpuPercent
          // ignore: cast_nullable_to_non_nullable
          : cpuPercent as num,
      memoryBytes:
          memoryBytes == const $CopyWithPlaceholder() || memoryBytes == null
          ? _value.memoryBytes
          // ignore: cast_nullable_to_non_nullable
          : memoryBytes as int,
      elapsedSeconds:
          elapsedSeconds == const $CopyWithPlaceholder() ||
              elapsedSeconds == null
          ? _value.elapsedSeconds
          // ignore: cast_nullable_to_non_nullable
          : elapsedSeconds as int,
      system: system == const $CopyWithPlaceholder() || system == null
          ? _value.system
          // ignore: cast_nullable_to_non_nullable
          : system as bool,
    );
  }
}

extension $ComputerProcessCopyWith on ComputerProcess {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerProcess.copyWith(...)` or `instanceOfComputerProcess.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerProcessCWProxy get copyWith => _$ComputerProcessCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerProcess _$ComputerProcessFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComputerProcess',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'pid',
            'name',
            'command',
            'cpu_percent',
            'memory_bytes',
            'elapsed_seconds',
            'system',
          ],
        );
        final val = ComputerProcess(
          pid: $checkedConvert('pid', (v) => (v as num).toInt()),
          name: $checkedConvert('name', (v) => v as String),
          command: $checkedConvert('command', (v) => v as String),
          cpuPercent: $checkedConvert('cpu_percent', (v) => v as num),
          memoryBytes: $checkedConvert(
            'memory_bytes',
            (v) => (v as num).toInt(),
          ),
          elapsedSeconds: $checkedConvert(
            'elapsed_seconds',
            (v) => (v as num).toInt(),
          ),
          system: $checkedConvert('system', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'cpuPercent': 'cpu_percent',
        'memoryBytes': 'memory_bytes',
        'elapsedSeconds': 'elapsed_seconds',
      },
    );

Map<String, dynamic> _$ComputerProcessToJson(ComputerProcess instance) =>
    <String, dynamic>{
      'pid': instance.pid,
      'name': instance.name,
      'command': instance.command,
      'cpu_percent': instance.cpuPercent,
      'memory_bytes': instance.memoryBytes,
      'elapsed_seconds': instance.elapsedSeconds,
      'system': instance.system,
    };
