// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_question_resolved_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpQuestionResolvedEventPayloadCWProxy {
  McpQuestionResolvedEventPayload questionId(String questionId);

  McpQuestionResolvedEventPayload outcome(
    McpQuestionResolvedEventPayloadOutcomeEnum outcome,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestionResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestionResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  McpQuestionResolvedEventPayload call({
    String questionId,
    McpQuestionResolvedEventPayloadOutcomeEnum outcome,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpQuestionResolvedEventPayload.copyWith(...)` or call `instanceOfMcpQuestionResolvedEventPayload.copyWith.fieldName(value)` for a single field.
class _$McpQuestionResolvedEventPayloadCWProxyImpl
    implements _$McpQuestionResolvedEventPayloadCWProxy {
  const _$McpQuestionResolvedEventPayloadCWProxyImpl(this._value);

  final McpQuestionResolvedEventPayload _value;

  @override
  McpQuestionResolvedEventPayload questionId(String questionId) =>
      call(questionId: questionId);

  @override
  McpQuestionResolvedEventPayload outcome(
    McpQuestionResolvedEventPayloadOutcomeEnum outcome,
  ) => call(outcome: outcome);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestionResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestionResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpQuestionResolvedEventPayload call({
    Object? questionId = const $CopyWithPlaceholder(),
    Object? outcome = const $CopyWithPlaceholder(),
  }) {
    return McpQuestionResolvedEventPayload(
      questionId:
          questionId == const $CopyWithPlaceholder() || questionId == null
          ? _value.questionId
          // ignore: cast_nullable_to_non_nullable
          : questionId as String,
      outcome: outcome == const $CopyWithPlaceholder() || outcome == null
          ? _value.outcome
          // ignore: cast_nullable_to_non_nullable
          : outcome as McpQuestionResolvedEventPayloadOutcomeEnum,
    );
  }
}

extension $McpQuestionResolvedEventPayloadCopyWith
    on McpQuestionResolvedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpQuestionResolvedEventPayload.copyWith(...)` or `instanceOfMcpQuestionResolvedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpQuestionResolvedEventPayloadCWProxy get copyWith =>
      _$McpQuestionResolvedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpQuestionResolvedEventPayload _$McpQuestionResolvedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('McpQuestionResolvedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['question_id', 'outcome']);
  final val = McpQuestionResolvedEventPayload(
    questionId: $checkedConvert('question_id', (v) => v as String),
    outcome: $checkedConvert(
      'outcome',
      (v) =>
          $enumDecode(_$McpQuestionResolvedEventPayloadOutcomeEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'questionId': 'question_id'});

Map<String, dynamic> _$McpQuestionResolvedEventPayloadToJson(
  McpQuestionResolvedEventPayload instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'outcome':
      _$McpQuestionResolvedEventPayloadOutcomeEnumEnumMap[instance.outcome]!,
};

const _$McpQuestionResolvedEventPayloadOutcomeEnumEnumMap = {
  McpQuestionResolvedEventPayloadOutcomeEnum.accepted: 'accepted',
  McpQuestionResolvedEventPayloadOutcomeEnum.declined: 'declined',
  McpQuestionResolvedEventPayloadOutcomeEnum.cancelled: 'cancelled',
  McpQuestionResolvedEventPayloadOutcomeEnum.expired: 'expired',
};
