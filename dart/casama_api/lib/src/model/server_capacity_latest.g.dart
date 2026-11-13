// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_capacity_latest.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServerCapacityLatestCWProxy {
  ServerCapacityLatest at(String at);

  ServerCapacityLatest memTotalMb(int memTotalMb);

  ServerCapacityLatest memAvailableMb(int memAvailableMb);

  ServerCapacityLatest load1(num load1);

  ServerCapacityLatest cpus(int cpus);

  ServerCapacityLatest diskUsedPct(num? diskUsedPct);

  ServerCapacityLatest computersRunning(int computersRunning);

  ServerCapacityLatest computersMemMb(int computersMemMb);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacityLatest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacityLatest(...).copyWith(id: 12, name: "My name")
  /// ```
  ServerCapacityLatest call({
    String at,
    int memTotalMb,
    int memAvailableMb,
    num load1,
    int cpus,
    num? diskUsedPct,
    int computersRunning,
    int computersMemMb,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServerCapacityLatest.copyWith(...)` or call `instanceOfServerCapacityLatest.copyWith.fieldName(value)` for a single field.
class _$ServerCapacityLatestCWProxyImpl
    implements _$ServerCapacityLatestCWProxy {
  const _$ServerCapacityLatestCWProxyImpl(this._value);

  final ServerCapacityLatest _value;

  @override
  ServerCapacityLatest at(String at) => call(at: at);

  @override
  ServerCapacityLatest memTotalMb(int memTotalMb) =>
      call(memTotalMb: memTotalMb);

  @override
  ServerCapacityLatest memAvailableMb(int memAvailableMb) =>
      call(memAvailableMb: memAvailableMb);

  @override
  ServerCapacityLatest load1(num load1) => call(load1: load1);

  @override
  ServerCapacityLatest cpus(int cpus) => call(cpus: cpus);

  @override
  ServerCapacityLatest diskUsedPct(num? diskUsedPct) =>
      call(diskUsedPct: diskUsedPct);

  @override
  ServerCapacityLatest computersRunning(int computersRunning) =>
      call(computersRunning: computersRunning);

  @override
  ServerCapacityLatest computersMemMb(int computersMemMb) =>
      call(computersMemMb: computersMemMb);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacityLatest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacityLatest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServerCapacityLatest call({
    Object? at = const $CopyWithPlaceholder(),
    Object? memTotalMb = const $CopyWithPlaceholder(),
    Object? memAvailableMb = const $CopyWithPlaceholder(),
    Object? load1 = const $CopyWithPlaceholder(),
    Object? cpus = const $CopyWithPlaceholder(),
    Object? diskUsedPct = const $CopyWithPlaceholder(),
    Object? computersRunning = const $CopyWithPlaceholder(),
    Object? computersMemMb = const $CopyWithPlaceholder(),
  }) {
    return ServerCapacityLatest(
      at: at == const $CopyWithPlaceholder() || at == null
          ? _value.at
          // ignore: cast_nullable_to_non_nullable
          : at as String,
      memTotalMb:
          memTotalMb == const $CopyWithPlaceholder() || memTotalMb == null
          ? _value.memTotalMb
          // ignore: cast_nullable_to_non_nullable
          : memTotalMb as int,
      memAvailableMb:
          memAvailableMb == const $CopyWithPlaceholder() ||
              memAvailableMb == null
          ? _value.memAvailableMb
          // ignore: cast_nullable_to_non_nullable
          : memAvailableMb as int,
      load1: load1 == const $CopyWithPlaceholder() || load1 == null
          ? _value.load1
          // ignore: cast_nullable_to_non_nullable
          : load1 as num,
      cpus: cpus == const $CopyWithPlaceholder() || cpus == null
          ? _value.cpus
          // ignore: cast_nullable_to_non_nullable
          : cpus as int,
      diskUsedPct: diskUsedPct == const $CopyWithPlaceholder()
          ? _value.diskUsedPct
          // ignore: cast_nullable_to_non_nullable
          : diskUsedPct as num?,
      computersRunning:
          computersRunning == const $CopyWithPlaceholder() ||
              computersRunning == null
          ? _value.computersRunning
          // ignore: cast_nullable_to_non_nullable
          : computersRunning as int,
      computersMemMb:
          computersMemMb == const $CopyWithPlaceholder() ||
              computersMemMb == null
          ? _value.computersMemMb
          // ignore: cast_nullable_to_non_nullable
          : computersMemMb as int,
    );
  }
}

extension $ServerCapacityLatestCopyWith on ServerCapacityLatest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServerCapacityLatest.copyWith(...)` or `instanceOfServerCapacityLatest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServerCapacityLatestCWProxy get copyWith =>
      _$ServerCapacityLatestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerCapacityLatest _$ServerCapacityLatestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ServerCapacityLatest',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'at',
        'mem_total_mb',
        'mem_available_mb',
        'load1',
        'cpus',
        'disk_used_pct',
        'computers_running',
        'computers_mem_mb',
      ],
    );
    final val = ServerCapacityLatest(
      at: $checkedConvert('at', (v) => v as String),
      memTotalMb: $checkedConvert('mem_total_mb', (v) => (v as num).toInt()),
      memAvailableMb: $checkedConvert(
        'mem_available_mb',
        (v) => (v as num).toInt(),
      ),
      load1: $checkedConvert('load1', (v) => v as num),
      cpus: $checkedConvert('cpus', (v) => (v as num).toInt()),
      diskUsedPct: $checkedConvert('disk_used_pct', (v) => v as num?),
      computersRunning: $checkedConvert(
        'computers_running',
        (v) => (v as num).toInt(),
      ),
      computersMemMb: $checkedConvert(
        'computers_mem_mb',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'memTotalMb': 'mem_total_mb',
    'memAvailableMb': 'mem_available_mb',
    'diskUsedPct': 'disk_used_pct',
    'computersRunning': 'computers_running',
    'computersMemMb': 'computers_mem_mb',
  },
);

Map<String, dynamic> _$ServerCapacityLatestToJson(
  ServerCapacityLatest instance,
) => <String, dynamic>{
  'at': instance.at,
  'mem_total_mb': instance.memTotalMb,
  'mem_available_mb': instance.memAvailableMb,
  'load1': instance.load1,
  'cpus': instance.cpus,
  'disk_used_pct': instance.diskUsedPct,
  'computers_running': instance.computersRunning,
  'computers_mem_mb': instance.computersMemMb,
};
