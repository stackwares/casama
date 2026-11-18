// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_vitals.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerVitalsCWProxy {
  ComputerVitals cpuPercent(num cpuPercent);

  ComputerVitals memoryUsedBytes(int memoryUsedBytes);

  ComputerVitals memoryLimitBytes(int memoryLimitBytes);

  ComputerVitals diskUsedBytes(int diskUsedBytes);

  ComputerVitals diskLimitBytes(int diskLimitBytes);

  ComputerVitals at(DateTime at);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerVitals(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerVitals(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerVitals call({
    num cpuPercent,
    int memoryUsedBytes,
    int memoryLimitBytes,
    int diskUsedBytes,
    int diskLimitBytes,
    DateTime at,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerVitals.copyWith(...)` or call `instanceOfComputerVitals.copyWith.fieldName(value)` for a single field.
class _$ComputerVitalsCWProxyImpl implements _$ComputerVitalsCWProxy {
  const _$ComputerVitalsCWProxyImpl(this._value);

  final ComputerVitals _value;

  @override
  ComputerVitals cpuPercent(num cpuPercent) => call(cpuPercent: cpuPercent);

  @override
  ComputerVitals memoryUsedBytes(int memoryUsedBytes) =>
      call(memoryUsedBytes: memoryUsedBytes);

  @override
  ComputerVitals memoryLimitBytes(int memoryLimitBytes) =>
      call(memoryLimitBytes: memoryLimitBytes);

  @override
  ComputerVitals diskUsedBytes(int diskUsedBytes) =>
      call(diskUsedBytes: diskUsedBytes);

  @override
  ComputerVitals diskLimitBytes(int diskLimitBytes) =>
      call(diskLimitBytes: diskLimitBytes);

  @override
  ComputerVitals at(DateTime at) => call(at: at);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerVitals(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerVitals(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerVitals call({
    Object? cpuPercent = const $CopyWithPlaceholder(),
    Object? memoryUsedBytes = const $CopyWithPlaceholder(),
    Object? memoryLimitBytes = const $CopyWithPlaceholder(),
    Object? diskUsedBytes = const $CopyWithPlaceholder(),
    Object? diskLimitBytes = const $CopyWithPlaceholder(),
    Object? at = const $CopyWithPlaceholder(),
  }) {
    return ComputerVitals(
      cpuPercent:
          cpuPercent == const $CopyWithPlaceholder() || cpuPercent == null
          ? _value.cpuPercent
          // ignore: cast_nullable_to_non_nullable
          : cpuPercent as num,
      memoryUsedBytes:
          memoryUsedBytes == const $CopyWithPlaceholder() ||
              memoryUsedBytes == null
          ? _value.memoryUsedBytes
          // ignore: cast_nullable_to_non_nullable
          : memoryUsedBytes as int,
      memoryLimitBytes:
          memoryLimitBytes == const $CopyWithPlaceholder() ||
              memoryLimitBytes == null
          ? _value.memoryLimitBytes
          // ignore: cast_nullable_to_non_nullable
          : memoryLimitBytes as int,
      diskUsedBytes:
          diskUsedBytes == const $CopyWithPlaceholder() || diskUsedBytes == null
          ? _value.diskUsedBytes
          // ignore: cast_nullable_to_non_nullable
          : diskUsedBytes as int,
      diskLimitBytes:
          diskLimitBytes == const $CopyWithPlaceholder() ||
              diskLimitBytes == null
          ? _value.diskLimitBytes
          // ignore: cast_nullable_to_non_nullable
          : diskLimitBytes as int,
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as DateTime,
    );
  }
}

extension $ComputerVitalsCopyWith on ComputerVitals {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerVitals.copyWith(...)` or `instanceOfComputerVitals.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerVitalsCWProxy get copyWith => _$ComputerVitalsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerVitals _$ComputerVitalsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComputerVitals',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'cpu_percent',
            'memory_used_bytes',
            'memory_limit_bytes',
            'disk_used_bytes',
            'disk_limit_bytes',
            'at',
          ],
        );
        final val = ComputerVitals(
          cpuPercent: $checkedConvert('cpu_percent', (v) => v as num),
          memoryUsedBytes: $checkedConvert(
            'memory_used_bytes',
            (v) => (v as num).toInt(),
          ),
          memoryLimitBytes: $checkedConvert(
            'memory_limit_bytes',
            (v) => (v as num).toInt(),
          ),
          diskUsedBytes: $checkedConvert(
            'disk_used_bytes',
            (v) => (v as num).toInt(),
          ),
          diskLimitBytes: $checkedConvert(
            'disk_limit_bytes',
            (v) => (v as num).toInt(),
          ),
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'cpuPercent': 'cpu_percent',
        'memoryUsedBytes': 'memory_used_bytes',
        'memoryLimitBytes': 'memory_limit_bytes',
        'diskUsedBytes': 'disk_used_bytes',
        'diskLimitBytes': 'disk_limit_bytes',
      },
    );

Map<String, dynamic> _$ComputerVitalsToJson(ComputerVitals instance) =>
    <String, dynamic>{
      'cpu_percent': instance.cpuPercent,
      'memory_used_bytes': instance.memoryUsedBytes,
      'memory_limit_bytes': instance.memoryLimitBytes,
      'disk_used_bytes': instance.diskUsedBytes,
      'disk_limit_bytes': instance.diskLimitBytes,
      'at': instance.at.toIso8601String(),
    };
