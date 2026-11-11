// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_replay_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunReplayResponseCWProxy {
  RunReplayResponse conversationId(String conversationId);

  RunReplayResponse runId(String runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunReplayResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunReplayResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  RunReplayResponse call({String conversationId, String runId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunReplayResponse.copyWith(...)` or call `instanceOfRunReplayResponse.copyWith.fieldName(value)` for a single field.
class _$RunReplayResponseCWProxyImpl implements _$RunReplayResponseCWProxy {
  const _$RunReplayResponseCWProxyImpl(this._value);

  final RunReplayResponse _value;

  @override
  RunReplayResponse conversationId(String conversationId) =>
      call(conversationId: conversationId);

  @override
  RunReplayResponse runId(String runId) => call(runId: runId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunReplayResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunReplayResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunReplayResponse call({
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
  }) {
    return RunReplayResponse(
      conversationId:
          conversationId == const $CopyWithPlaceholder() ||
              conversationId == null
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
    );
  }
}

extension $RunReplayResponseCopyWith on RunReplayResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunReplayResponse.copyWith(...)` or `instanceOfRunReplayResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunReplayResponseCWProxy get copyWith =>
      _$RunReplayResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunReplayResponse _$RunReplayResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RunReplayResponse', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['conversation_id', 'run_id']);
  final val = RunReplayResponse(
    conversationId: $checkedConvert('conversation_id', (v) => v as String),
    runId: $checkedConvert('run_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'conversationId': 'conversation_id', 'runId': 'run_id'});

Map<String, dynamic> _$RunReplayResponseToJson(RunReplayResponse instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'run_id': instance.runId,
    };
