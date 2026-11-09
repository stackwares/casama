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

  Computer lastActiveAt(DateTime? lastActiveAt);

  Computer error(String? error);

  Computer createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Computer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Computer(...).copyWith(id: 12, name: "My name")
  /// ````
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
    DateTime? lastActiveAt,
    String? error,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComputer.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComputer.copyWith.fieldName(...)`
class _$ComputerCWProxyImpl implements _$ComputerCWProxy {
  const _$ComputerCWProxyImpl(this._value);

  final Computer _value;

  @override
  Computer id(String id) => this(id: id);

  @override
  Computer orgId(String orgId) => this(orgId: orgId);

  @override
  Computer kind(ComputerKindEnum kind) => this(kind: kind);

  @override
  Computer name(String name) => this(name: name);

  @override
  Computer ownerBotId(String? ownerBotId) => this(ownerBotId: ownerBotId);

  @override
  Computer provider(String provider) => this(provider: provider);

  @override
  Computer profile(ComputerProfileEnum profile) => this(profile: profile);

  @override
  Computer state(ComputerState state) => this(state: state);

  @override
  Computer size(ComputerSize size) => this(size: size);

  @override
  Computer hasSnapshot(bool hasSnapshot) => this(hasSnapshot: hasSnapshot);

  @override
  Computer lastActiveAt(DateTime? lastActiveAt) =>
      this(lastActiveAt: lastActiveAt);

  @override
  Computer error(String? error) => this(error: error);

  @override
  Computer createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Computer(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Computer(...).copyWith(id: 12, name: "My name")
  /// ````
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
    Object? lastActiveAt = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Computer(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      kind: kind == const $CopyWithPlaceholder()
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ComputerKindEnum,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      ownerBotId: ownerBotId == const $CopyWithPlaceholder()
          ? _value.ownerBotId
          // ignore: cast_nullable_to_non_nullable
          : ownerBotId as String?,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as String,
      profile: profile == const $CopyWithPlaceholder()
          ? _value.profile
          // ignore: cast_nullable_to_non_nullable
          : profile as ComputerProfileEnum,
      state: state == const $CopyWithPlaceholder()
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as ComputerState,
      size: size == const $CopyWithPlaceholder()
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as ComputerSize,
      hasSnapshot: hasSnapshot == const $CopyWithPlaceholder()
          ? _value.hasSnapshot
          // ignore: cast_nullable_to_non_nullable
          : hasSnapshot as bool,
      lastActiveAt: lastActiveAt == const $CopyWithPlaceholder()
          ? _value.lastActiveAt
          // ignore: cast_nullable_to_non_nullable
          : lastActiveAt as DateTime?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ComputerCopyWith on Computer {
  /// Returns a callable class that can be used as follows: `instanceOfComputer.copyWith(...)` or like so:`instanceOfComputer.copyWith.fieldName(...)`.
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
      lastActiveAt: $checkedConvert(
        'last_active_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      error: $checkedConvert('error', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'ownerBotId': 'owner_bot_id',
    'hasSnapshot': 'has_snapshot',
    'lastActiveAt': 'last_active_at',
    'createdAt': 'created_at',
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
  'last_active_at': instance.lastActiveAt?.toIso8601String(),
  'error': instance.error,
  'created_at': instance.createdAt.toIso8601String(),
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
