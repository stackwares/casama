// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_operation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerOperationCWProxy {
  ComputerOperation kind(ComputerOperationKindEnum kind);

  ComputerOperation step(ComputerOperationStepEnum step);

  ComputerOperation checkpointId(String? checkpointId);

  ComputerOperation error(String? error);

  ComputerOperation startedAt(DateTime startedAt);

  ComputerOperation finishedAt(DateTime? finishedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerOperation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerOperation(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerOperation call({
    ComputerOperationKindEnum kind,
    ComputerOperationStepEnum step,
    String? checkpointId,
    String? error,
    DateTime startedAt,
    DateTime? finishedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerOperation.copyWith(...)` or call `instanceOfComputerOperation.copyWith.fieldName(value)` for a single field.
class _$ComputerOperationCWProxyImpl implements _$ComputerOperationCWProxy {
  const _$ComputerOperationCWProxyImpl(this._value);

  final ComputerOperation _value;

  @override
  ComputerOperation kind(ComputerOperationKindEnum kind) => call(kind: kind);

  @override
  ComputerOperation step(ComputerOperationStepEnum step) => call(step: step);

  @override
  ComputerOperation checkpointId(String? checkpointId) =>
      call(checkpointId: checkpointId);

  @override
  ComputerOperation error(String? error) => call(error: error);

  @override
  ComputerOperation startedAt(DateTime startedAt) => call(startedAt: startedAt);

  @override
  ComputerOperation finishedAt(DateTime? finishedAt) =>
      call(finishedAt: finishedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerOperation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerOperation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerOperation call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? step = const $CopyWithPlaceholder(),
    Object? checkpointId = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? finishedAt = const $CopyWithPlaceholder(),
  }) {
    return ComputerOperation(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as ComputerOperationKindEnum,
      step: step == const $CopyWithPlaceholder() || step == null
          ? _value.step
          // ignore: cast_nullable_to_non_nullable
          : step as ComputerOperationStepEnum,
      checkpointId: checkpointId == const $CopyWithPlaceholder()
          ? _value.checkpointId
          // ignore: cast_nullable_to_non_nullable
          : checkpointId as String?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      startedAt: startedAt == const $CopyWithPlaceholder() || startedAt == null
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime,
      finishedAt: finishedAt == const $CopyWithPlaceholder()
          ? _value.finishedAt
          // ignore: cast_nullable_to_non_nullable
          : finishedAt as DateTime?,
    );
  }
}

extension $ComputerOperationCopyWith on ComputerOperation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerOperation.copyWith(...)` or `instanceOfComputerOperation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerOperationCWProxy get copyWith =>
      _$ComputerOperationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerOperation _$ComputerOperationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComputerOperation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'kind',
            'step',
            'checkpoint_id',
            'error',
            'started_at',
            'finished_at',
          ],
        );
        final val = ComputerOperation(
          kind: $checkedConvert(
            'kind',
            (v) => $enumDecode(_$ComputerOperationKindEnumEnumMap, v),
          ),
          step: $checkedConvert(
            'step',
            (v) => $enumDecode(_$ComputerOperationStepEnumEnumMap, v),
          ),
          checkpointId: $checkedConvert('checkpoint_id', (v) => v as String?),
          error: $checkedConvert('error', (v) => v as String?),
          startedAt: $checkedConvert(
            'started_at',
            (v) => DateTime.parse(v as String),
          ),
          finishedAt: $checkedConvert(
            'finished_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'checkpointId': 'checkpoint_id',
        'startedAt': 'started_at',
        'finishedAt': 'finished_at',
      },
    );

Map<String, dynamic> _$ComputerOperationToJson(ComputerOperation instance) =>
    <String, dynamic>{
      'kind': _$ComputerOperationKindEnumEnumMap[instance.kind]!,
      'step': _$ComputerOperationStepEnumEnumMap[instance.step]!,
      'checkpoint_id': instance.checkpointId,
      'error': instance.error,
      'started_at': instance.startedAt.toIso8601String(),
      'finished_at': instance.finishedAt?.toIso8601String(),
    };

const _$ComputerOperationKindEnumEnumMap = {
  ComputerOperationKindEnum.resetSystem: 'reset_system',
  ComputerOperationKindEnum.erase: 'erase',
};

const _$ComputerOperationStepEnumEnumMap = {
  ComputerOperationStepEnum.saving: 'saving',
  ComputerOperationStepEnum.wiping: 'wiping',
  ComputerOperationStepEnum.restarting: 'restarting',
  ComputerOperationStepEnum.done: 'done',
  ComputerOperationStepEnum.failed: 'failed',
};
