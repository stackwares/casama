// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_tool_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$VoiceToolResultCWProxy {
  VoiceToolResult status(VoiceToolResultStatusEnum status);

  VoiceToolResult runId(String runId);

  VoiceToolResult output(String output);

  VoiceToolResult approvalId(String? approvalId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceToolResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceToolResult(...).copyWith(id: 12, name: "My name")
  /// ```
  VoiceToolResult call({
    VoiceToolResultStatusEnum status,
    String runId,
    String output,
    String? approvalId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfVoiceToolResult.copyWith(...)` or call `instanceOfVoiceToolResult.copyWith.fieldName(value)` for a single field.
class _$VoiceToolResultCWProxyImpl implements _$VoiceToolResultCWProxy {
  const _$VoiceToolResultCWProxyImpl(this._value);

  final VoiceToolResult _value;

  @override
  VoiceToolResult status(VoiceToolResultStatusEnum status) =>
      call(status: status);

  @override
  VoiceToolResult runId(String runId) => call(runId: runId);

  @override
  VoiceToolResult output(String output) => call(output: output);

  @override
  VoiceToolResult approvalId(String? approvalId) =>
      call(approvalId: approvalId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `VoiceToolResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// VoiceToolResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  VoiceToolResult call({
    Object? status = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? output = const $CopyWithPlaceholder(),
    Object? approvalId = const $CopyWithPlaceholder(),
  }) {
    return VoiceToolResult(
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as VoiceToolResultStatusEnum,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      output: output == const $CopyWithPlaceholder() || output == null
          ? _value.output
          // ignore: cast_nullable_to_non_nullable
          : output as String,
      approvalId: approvalId == const $CopyWithPlaceholder()
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String?,
    );
  }
}

extension $VoiceToolResultCopyWith on VoiceToolResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfVoiceToolResult.copyWith(...)` or `instanceOfVoiceToolResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$VoiceToolResultCWProxy get copyWith => _$VoiceToolResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceToolResult _$VoiceToolResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VoiceToolResult', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['status', 'run_id', 'output', 'approval_id'],
      );
      final val = VoiceToolResult(
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$VoiceToolResultStatusEnumEnumMap, v),
        ),
        runId: $checkedConvert('run_id', (v) => v as String),
        output: $checkedConvert('output', (v) => v as String),
        approvalId: $checkedConvert('approval_id', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'approvalId': 'approval_id'});

Map<String, dynamic> _$VoiceToolResultToJson(VoiceToolResult instance) =>
    <String, dynamic>{
      'status': _$VoiceToolResultStatusEnumEnumMap[instance.status]!,
      'run_id': instance.runId,
      'output': instance.output,
      'approval_id': instance.approvalId,
    };

const _$VoiceToolResultStatusEnumEnumMap = {
  VoiceToolResultStatusEnum.completed: 'completed',
  VoiceToolResultStatusEnum.failed: 'failed',
  VoiceToolResultStatusEnum.waitingApproval: 'waiting_approval',
  VoiceToolResultStatusEnum.running: 'running',
};
