// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckpointCWProxy {
  Checkpoint id(String id);

  Checkpoint computerId(String computerId);

  Checkpoint runId(String? runId);

  Checkpoint label(String label);

  Checkpoint size(int size);

  Checkpoint createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Checkpoint(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Checkpoint(...).copyWith(id: 12, name: "My name")
  /// ````
  Checkpoint call({
    String id,
    String computerId,
    String? runId,
    String label,
    int size,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCheckpoint.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCheckpoint.copyWith.fieldName(...)`
class _$CheckpointCWProxyImpl implements _$CheckpointCWProxy {
  const _$CheckpointCWProxyImpl(this._value);

  final Checkpoint _value;

  @override
  Checkpoint id(String id) => this(id: id);

  @override
  Checkpoint computerId(String computerId) => this(computerId: computerId);

  @override
  Checkpoint runId(String? runId) => this(runId: runId);

  @override
  Checkpoint label(String label) => this(label: label);

  @override
  Checkpoint size(int size) => this(size: size);

  @override
  Checkpoint createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Checkpoint(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Checkpoint(...).copyWith(id: 12, name: "My name")
  /// ````
  Checkpoint call({
    Object? id = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Checkpoint(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String?,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      size: size == const $CopyWithPlaceholder()
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CheckpointCopyWith on Checkpoint {
  /// Returns a callable class that can be used as follows: `instanceOfCheckpoint.copyWith(...)` or like so:`instanceOfCheckpoint.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckpointCWProxy get copyWith => _$CheckpointCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Checkpoint _$CheckpointFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Checkpoint',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'computer_id',
        'run_id',
        'label',
        'size',
        'created_at',
      ],
    );
    final val = Checkpoint(
      id: $checkedConvert('id', (v) => v as String),
      computerId: $checkedConvert('computer_id', (v) => v as String),
      runId: $checkedConvert('run_id', (v) => v as String?),
      label: $checkedConvert('label', (v) => v as String),
      size: $checkedConvert('size', (v) => (v as num).toInt()),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'computerId': 'computer_id',
    'runId': 'run_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$CheckpointToJson(Checkpoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'computer_id': instance.computerId,
      'run_id': instance.runId,
      'label': instance.label,
      'size': instance.size,
      'created_at': instance.createdAt.toIso8601String(),
    };
