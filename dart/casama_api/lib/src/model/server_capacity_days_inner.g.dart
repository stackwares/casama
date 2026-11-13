// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_capacity_days_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ServerCapacityDaysInnerCWProxy {
  ServerCapacityDaysInner day(String day);

  ServerCapacityDaysInner peakComputersMemMb(int peakComputersMemMb);

  ServerCapacityDaysInner peakComputers(int peakComputers);

  ServerCapacityDaysInner minAvailableMb(int minAvailableMb);

  ServerCapacityDaysInner peakLoad1(num peakLoad1);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacityDaysInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacityDaysInner(...).copyWith(id: 12, name: "My name")
  /// ```
  ServerCapacityDaysInner call({
    String day,
    int peakComputersMemMb,
    int peakComputers,
    int minAvailableMb,
    num peakLoad1,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfServerCapacityDaysInner.copyWith(...)` or call `instanceOfServerCapacityDaysInner.copyWith.fieldName(value)` for a single field.
class _$ServerCapacityDaysInnerCWProxyImpl
    implements _$ServerCapacityDaysInnerCWProxy {
  const _$ServerCapacityDaysInnerCWProxyImpl(this._value);

  final ServerCapacityDaysInner _value;

  @override
  ServerCapacityDaysInner day(String day) => call(day: day);

  @override
  ServerCapacityDaysInner peakComputersMemMb(int peakComputersMemMb) =>
      call(peakComputersMemMb: peakComputersMemMb);

  @override
  ServerCapacityDaysInner peakComputers(int peakComputers) =>
      call(peakComputers: peakComputers);

  @override
  ServerCapacityDaysInner minAvailableMb(int minAvailableMb) =>
      call(minAvailableMb: minAvailableMb);

  @override
  ServerCapacityDaysInner peakLoad1(num peakLoad1) =>
      call(peakLoad1: peakLoad1);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ServerCapacityDaysInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ServerCapacityDaysInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ServerCapacityDaysInner call({
    Object? day = const $CopyWithPlaceholder(),
    Object? peakComputersMemMb = const $CopyWithPlaceholder(),
    Object? peakComputers = const $CopyWithPlaceholder(),
    Object? minAvailableMb = const $CopyWithPlaceholder(),
    Object? peakLoad1 = const $CopyWithPlaceholder(),
  }) {
    return ServerCapacityDaysInner(
      day: day == const $CopyWithPlaceholder() || day == null
          ? _value.day
          // ignore: cast_nullable_to_non_nullable
          : day as String,
      peakComputersMemMb:
          peakComputersMemMb == const $CopyWithPlaceholder() ||
              peakComputersMemMb == null
          ? _value.peakComputersMemMb
          // ignore: cast_nullable_to_non_nullable
          : peakComputersMemMb as int,
      peakComputers:
          peakComputers == const $CopyWithPlaceholder() || peakComputers == null
          ? _value.peakComputers
          // ignore: cast_nullable_to_non_nullable
          : peakComputers as int,
      minAvailableMb:
          minAvailableMb == const $CopyWithPlaceholder() ||
              minAvailableMb == null
          ? _value.minAvailableMb
          // ignore: cast_nullable_to_non_nullable
          : minAvailableMb as int,
      peakLoad1: peakLoad1 == const $CopyWithPlaceholder() || peakLoad1 == null
          ? _value.peakLoad1
          // ignore: cast_nullable_to_non_nullable
          : peakLoad1 as num,
    );
  }
}

extension $ServerCapacityDaysInnerCopyWith on ServerCapacityDaysInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfServerCapacityDaysInner.copyWith(...)` or `instanceOfServerCapacityDaysInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ServerCapacityDaysInnerCWProxy get copyWith =>
      _$ServerCapacityDaysInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerCapacityDaysInner _$ServerCapacityDaysInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ServerCapacityDaysInner',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'day',
        'peak_computers_mem_mb',
        'peak_computers',
        'min_available_mb',
        'peak_load1',
      ],
    );
    final val = ServerCapacityDaysInner(
      day: $checkedConvert('day', (v) => v as String),
      peakComputersMemMb: $checkedConvert(
        'peak_computers_mem_mb',
        (v) => (v as num).toInt(),
      ),
      peakComputers: $checkedConvert(
        'peak_computers',
        (v) => (v as num).toInt(),
      ),
      minAvailableMb: $checkedConvert(
        'min_available_mb',
        (v) => (v as num).toInt(),
      ),
      peakLoad1: $checkedConvert('peak_load1', (v) => v as num),
    );
    return val;
  },
  fieldKeyMap: const {
    'peakComputersMemMb': 'peak_computers_mem_mb',
    'peakComputers': 'peak_computers',
    'minAvailableMb': 'min_available_mb',
    'peakLoad1': 'peak_load1',
  },
);

Map<String, dynamic> _$ServerCapacityDaysInnerToJson(
  ServerCapacityDaysInner instance,
) => <String, dynamic>{
  'day': instance.day,
  'peak_computers_mem_mb': instance.peakComputersMemMb,
  'peak_computers': instance.peakComputers,
  'min_available_mb': instance.minAvailableMb,
  'peak_load1': instance.peakLoad1,
};
