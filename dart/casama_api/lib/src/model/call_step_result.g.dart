// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_step_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CallStepResultCWProxy {
  CallStepResult runId(String? runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CallStepResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CallStepResult(...).copyWith(id: 12, name: "My name")
  /// ```
  CallStepResult call({String? runId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCallStepResult.copyWith(...)` or call `instanceOfCallStepResult.copyWith.fieldName(value)` for a single field.
class _$CallStepResultCWProxyImpl implements _$CallStepResultCWProxy {
  const _$CallStepResultCWProxyImpl(this._value);

  final CallStepResult _value;

  @override
  CallStepResult runId(String? runId) => call(runId: runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CallStepResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CallStepResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CallStepResult call({Object? runId = const $CopyWithPlaceholder()}) {
    return CallStepResult(
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String?,
    );
  }
}

extension $CallStepResultCopyWith on CallStepResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCallStepResult.copyWith(...)` or `instanceOfCallStepResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CallStepResultCWProxy get copyWith => _$CallStepResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallStepResult _$CallStepResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CallStepResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['run_id']);
      final val = CallStepResult(
        runId: $checkedConvert('run_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id'});

Map<String, dynamic> _$CallStepResultToJson(CallStepResult instance) =>
    <String, dynamic>{'run_id': instance.runId};
