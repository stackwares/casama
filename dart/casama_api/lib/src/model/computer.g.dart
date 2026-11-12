// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerCWProxy {
  Computer id(String id);

  Computer orgId(String orgId);

  Computer kind(ComputerKindEnum kind);

  Computer name(String name);

  Computer ownerBotId(String? ownerBotId);

  Computer provider(String provider);

  Computer profile(ComputerProfileEnum profile);

  Computer state(ComputerState state);

  Computer size(ComputerSize size);

  Computer hasSnapshot(bool hasSnapshot);

  Computer maxDesktops(int maxDesktops);

  Computer lastActiveAt(DateTime? lastActiveAt);

  Computer error(String? error);

  Computer createdAt(DateTime createdAt);

  Computer os(String? os);

  Computer device(ComputerDevice? device);

  Computer idleSleepMinutes(int? idleSleepMinutes);

  Computer operation(ComputerOperation? operation);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Computer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Computer(...).copyWith(id: 12, name: "My name")
  /// ```
  Computer call({
    String id,
    String orgId,
    ComputerKindEnum kind,
    String name,
    String? ownerBotId,
    String provider,
    ComputerProfileEnum profile,
    ComputerState state,
    ComputerSize size,
    bool hasSnapshot,
    int maxDesktops,
    DateTime? lastActiveAt,
    String? error,
    DateTime createdAt,
    String? os,
    ComputerDevice? device,
    int? idleSleepMinutes,
    ComputerOperation? operation,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputer.copyWith(...)` or call `instanceOfComputer.copyWith.fieldName(value)` for a single field.
class _$ComputerCWProxyImpl implements _$ComputerCWProxy {
  const _$ComputerCWProxyImpl(this._value);

  final Computer _value;

  @override
  Computer id(String id) => call(id: id);

  @override
  Computer orgId(String orgId) => call(orgId: orgId);

  @override
  Computer kind(ComputerKindEnum kind) => call(kind: kind);

  @override
  Computer name(String name) => call(name: name);

  @override
  Computer ownerBotId(String? ownerBotId) => call(ownerBotId: ownerBotId);

  @override
  Computer provider(String provider) => call(provider: provider);

  @override
  Computer profile(ComputerProfileEnum profile) => call(profile: profile);

  @override
  Computer state(ComputerState state) => call(state: state);

  @override
  Computer size(ComputerSize size) => call(size: size);

  @override
  Computer hasSnapshot(bool hasSnapshot) => call(hasSnapshot: hasSnapshot);

  @override
  Computer maxDesktops(int maxDesktops) => call(maxDesktops: maxDesktops);

  @override
  Computer lastActiveAt(DateTime? lastActiveAt) =>
      call(lastActiveAt: lastActiveAt);

  @override
  Computer error(String? error) => call(error: error);

  @override
  Computer createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  Computer os(String? os) => call(os: os);

  @override
  Computer device(ComputerDevice? device) => call(device: device);

  @override
  Computer idleSleepMinutes(int? idleSleepMinutes) =>
      call(idleSleepMinutes: idleSleepMinutes);

  @override
  Computer operation(ComputerOperation? operation) =>
      call(operation: operation);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Computer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Computer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Computer call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? ownerBotId = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? profile = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? hasSnapshot = const $CopyWithPlaceholder(),
    Object? maxDesktops = const $CopyWithPlaceholder(),
    Object? lastActiveAt = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? os = const $CopyWithPlaceholder(),
    Object? device = const $CopyWithPlaceholder(),
    Object? idleSleepMinutes = const $CopyWithPlaceholder(),
    Object? operation = const $CopyWithPlaceholder(),
  }) {
    return Computer(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ComputerKindEnum,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      ownerBotId: ownerBotId == const $CopyWithPlaceholder()
          ? _value.ownerBotId
          // ignore: cast_nullable_to_non_nullable
          : ownerBotId as String?,
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as String,
      profile: profile == const $CopyWithPlaceholder() || profile == null
          ? _value.profile
          // ignore: cast_nullable_to_non_nullable
          : profile as ComputerProfileEnum,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as ComputerState,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as ComputerSize,
      hasSnapshot:
          hasSnapshot == const $CopyWithPlaceholder() || hasSnapshot == null
          ? _value.hasSnapshot
          // ignore: cast_nullable_to_non_nullable
          : hasSnapshot as bool,
      maxDesktops:
          maxDesktops == const $CopyWithPlaceholder() || maxDesktops == null
          ? _value.maxDesktops
          // ignore: cast_nullable_to_non_nullable
          : maxDesktops as int,
      lastActiveAt: lastActiveAt == const $CopyWithPlaceholder()
          ? _value.lastActiveAt
          // ignore: cast_nullable_to_non_nullable
          : lastActiveAt as DateTime?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      os: os == const $CopyWithPlaceholder()
          ? _value.os
          // ignore: cast_nullable_to_non_nullable
          : os as String?,
      device: device == const $CopyWithPlaceholder()
          ? _value.device
          // ignore: cast_nullable_to_non_nullable
          : device as ComputerDevice?,
      idleSleepMinutes: idleSleepMinutes == const $CopyWithPlaceholder()
          ? _value.idleSleepMinutes
          // ignore: cast_nullable_to_non_nullable
          : idleSleepMinutes as int?,
      operation: operation == const $CopyWithPlaceholder()
          ? _value.operation
          // ignore: cast_nullable_to_non_nullable
          : operation as ComputerOperation?,
    );
  }
}

extension $ComputerCopyWith on Computer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputer.copyWith(...)` or `instanceOfComputer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerCWProxy get copyWith => _$ComputerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Computer _$ComputerFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Computer',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'kind',
        'name',
        'owner_bot_id',
        'provider',
        'profile',
        'state',
        'size',
        'has_snapshot',
        'max_desktops',
        'last_active_at',
        'error',
        'created_at',
      ],
    );
    final val = Computer(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      kind: $checkedConvert(
        'kind',
        (v) => $enumDecode(_$ComputerKindEnumEnumMap, v),
      ),
      name: $checkedConvert('name', (v) => v as String),
      ownerBotId: $checkedConvert('owner_bot_id', (v) => v as String?),
      provider: $checkedConvert('provider', (v) => v as String),
      profile: $checkedConvert(
        'profile',
        (v) => $enumDecode(_$ComputerProfileEnumEnumMap, v),
      ),
      state: $checkedConvert(
        'state',
        (v) => $enumDecode(_$ComputerStateEnumMap, v),
      ),
      size: $checkedConvert(
        'size',
        (v) => ComputerSize.fromJson(v as Map<String, dynamic>),
      ),
      hasSnapshot: $checkedConvert('has_snapshot', (v) => v as bool),
      maxDesktops: $checkedConvert('max_desktops', (v) => (v as num).toInt()),
      lastActiveAt: $checkedConvert(
        'last_active_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      error: $checkedConvert('error', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
      os: $checkedConvert('os', (v) => v as String?),
      device: $checkedConvert(
        'device',
        (v) => v == null
            ? null
            : ComputerDevice.fromJson(v as Map<String, dynamic>),
      ),
      idleSleepMinutes: $checkedConvert(
        'idle_sleep_minutes',
        (v) => (v as num?)?.toInt(),
      ),
      operation: $checkedConvert(
        'operation',
        (v) => v == null
            ? null
            : ComputerOperation.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'ownerBotId': 'owner_bot_id',
    'hasSnapshot': 'has_snapshot',
    'maxDesktops': 'max_desktops',
    'lastActiveAt': 'last_active_at',
    'createdAt': 'created_at',
    'idleSleepMinutes': 'idle_sleep_minutes',
  },
);

Map<String, dynamic> _$ComputerToJson(Computer instance) => <String, dynamic>{
  'id': instance.id,
  'org_id': instance.orgId,
  'kind': _$ComputerKindEnumEnumMap[instance.kind]!,
  'name': instance.name,
  'owner_bot_id': instance.ownerBotId,
  'provider': instance.provider,
  'profile': _$ComputerProfileEnumEnumMap[instance.profile]!,
  'state': _$ComputerStateEnumMap[instance.state]!,
  'size': instance.size.toJson(),
  'has_snapshot': instance.hasSnapshot,
  'max_desktops': instance.maxDesktops,
  'last_active_at': instance.lastActiveAt?.toIso8601String(),
  'error': instance.error,
  'created_at': instance.createdAt.toIso8601String(),
  'os': ?instance.os,
  'device': ?instance.device?.toJson(),
  'idle_sleep_minutes': ?instance.idleSleepMinutes,
  'operation': ?instance.operation?.toJson(),
};

const _$ComputerKindEnumEnumMap = {
  ComputerKindEnum.private: 'private',
  ComputerKindEnum.team: 'team',
  ComputerKindEnum.local: 'local',
};

const _$ComputerProfileEnumEnumMap = {
  ComputerProfileEnum.headless: 'headless',
  ComputerProfileEnum.desktop: 'desktop',
};

const _$ComputerStateEnumMap = {
  ComputerState.provisioning: 'provisioning',
  ComputerState.starting: 'starting',
  ComputerState.running: 'running',
  ComputerState.idle: 'idle',
  ComputerState.sleeping: 'sleeping',
  ComputerState.stopped: 'stopped',
  ComputerState.error: 'error',
};
