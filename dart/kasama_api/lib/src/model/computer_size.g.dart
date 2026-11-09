// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_size.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerSizeCWProxy {
  ComputerSize cpus(num? cpus);

  ComputerSize memoryMb(num? memoryMb);

  ComputerSize diskGb(num? diskGb);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerSize(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerSize(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerSize call({num? cpus, num? memoryMb, num? diskGb});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComputerSize.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComputerSize.copyWith.fieldName(...)`
class _$ComputerSizeCWProxyImpl implements _$ComputerSizeCWProxy {
  const _$ComputerSizeCWProxyImpl(this._value);

  final ComputerSize _value;

  @override
  ComputerSize cpus(num? cpus) => this(cpus: cpus);

  @override
  ComputerSize memoryMb(num? memoryMb) => this(memoryMb: memoryMb);

  @override
  ComputerSize diskGb(num? diskGb) => this(diskGb: diskGb);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerSize(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerSize(...).copyWith(id: 12, name: "My name")
  /// ````
  ComputerSize call({
    Object? cpus = const $CopyWithPlaceholder(),
    Object? memoryMb = const $CopyWithPlaceholder(),
    Object? diskGb = const $CopyWithPlaceholder(),
  }) {
    return ComputerSize(
      cpus: cpus == const $CopyWithPlaceholder()
          ? _value.cpus
          // ignore: cast_nullable_to_non_nullable
          : cpus as num?,
      memoryMb: memoryMb == const $CopyWithPlaceholder()
          ? _value.memoryMb
          // ignore: cast_nullable_to_non_nullable
          : memoryMb as num?,
      diskGb: diskGb == const $CopyWithPlaceholder()
          ? _value.diskGb
          // ignore: cast_nullable_to_non_nullable
          : diskGb as num?,
    );
  }
}

extension $ComputerSizeCopyWith on ComputerSize {
  /// Returns a callable class that can be used as follows: `instanceOfComputerSize.copyWith(...)` or like so:`instanceOfComputerSize.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerSizeCWProxy get copyWith => _$ComputerSizeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerSize _$ComputerSizeFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComputerSize',
      json,
      ($checkedConvert) {
        final val = ComputerSize(
          cpus: $checkedConvert('cpus', (v) => v as num?),
          memoryMb: $checkedConvert('memory_mb', (v) => v as num?),
          diskGb: $checkedConvert('disk_gb', (v) => v as num?),
        );
        return val;
      },
      fieldKeyMap: const {'memoryMb': 'memory_mb', 'diskGb': 'disk_gb'},
    );

Map<String, dynamic> _$ComputerSizeToJson(ComputerSize instance) =>
    <String, dynamic>{
      'cpus': ?instance.cpus,
      'memory_mb': ?instance.memoryMb,
      'disk_gb': ?instance.diskGb,
    };
