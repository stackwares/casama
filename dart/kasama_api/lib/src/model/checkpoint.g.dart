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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Checkpoint(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Checkpoint(...).copyWith(id: 12, name: "My name")
  /// ```
  Checkpoint call({
    String id,
    String computerId,
    String? runId,
    String label,
    int size,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCheckpoint.copyWith(...)` or call `instanceOfCheckpoint.copyWith.fieldName(value)` for a single field.
class _$CheckpointCWProxyImpl implements _$CheckpointCWProxy {
  const _$CheckpointCWProxyImpl(this._value);

  final Checkpoint _value;

  @override
  Checkpoint id(String id) => call(id: id);

  @override
  Checkpoint computerId(String computerId) => call(computerId: computerId);

  @override
  Checkpoint runId(String? runId) => call(runId: runId);

  @override
  Checkpoint label(String label) => call(label: label);

  @override
  Checkpoint size(int size) => call(size: size);

  @override
  Checkpoint createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Checkpoint(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Checkpoint(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Checkpoint call({
    Object? id = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Checkpoint(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      computerId:
          computerId == const $CopyWithPlaceholder() || computerId == null
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String?,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $CheckpointCopyWith on Checkpoint {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCheckpoint.copyWith(...)` or `instanceOfCheckpoint.copyWith.fieldName(...)`.
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
