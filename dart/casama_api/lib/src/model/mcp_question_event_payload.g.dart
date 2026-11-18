// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_question_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpQuestionEventPayloadCWProxy {
  McpQuestionEventPayload questionId(String questionId);

  McpQuestionEventPayload connection(String connection);

  McpQuestionEventPayload message(String message);

  McpQuestionEventPayload schema(Map<String, Object?> schema);

  McpQuestionEventPayload expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestionEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestionEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  McpQuestionEventPayload call({
    String questionId,
    String connection,
    String message,
    Map<String, Object?> schema,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpQuestionEventPayload.copyWith(...)` or call `instanceOfMcpQuestionEventPayload.copyWith.fieldName(value)` for a single field.
class _$McpQuestionEventPayloadCWProxyImpl
    implements _$McpQuestionEventPayloadCWProxy {
  const _$McpQuestionEventPayloadCWProxyImpl(this._value);

  final McpQuestionEventPayload _value;

  @override
  McpQuestionEventPayload questionId(String questionId) =>
      call(questionId: questionId);

  @override
  McpQuestionEventPayload connection(String connection) =>
      call(connection: connection);

  @override
  McpQuestionEventPayload message(String message) => call(message: message);

  @override
  McpQuestionEventPayload schema(Map<String, Object?> schema) =>
      call(schema: schema);

  @override
  McpQuestionEventPayload expiresAt(DateTime expiresAt) =>
      call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestionEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestionEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpQuestionEventPayload call({
    Object? questionId = const $CopyWithPlaceholder(),
    Object? connection = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? schema = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return McpQuestionEventPayload(
      questionId:
          questionId == const $CopyWithPlaceholder() || questionId == null
          ? _value.questionId
          // ignore: cast_nullable_to_non_nullable
          : questionId as String,
      connection:
          connection == const $CopyWithPlaceholder() || connection == null
          ? _value.connection
          // ignore: cast_nullable_to_non_nullable
          : connection as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      schema: schema == const $CopyWithPlaceholder() || schema == null
          ? _value.schema
          // ignore: cast_nullable_to_non_nullable
          : schema as Map<String, Object?>,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $McpQuestionEventPayloadCopyWith on McpQuestionEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpQuestionEventPayload.copyWith(...)` or `instanceOfMcpQuestionEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpQuestionEventPayloadCWProxy get copyWith =>
      _$McpQuestionEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpQuestionEventPayload _$McpQuestionEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('McpQuestionEventPayload', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'question_id',
      'connection',
      'message',
      'schema',
      'expires_at',
    ],
  );
  final val = McpQuestionEventPayload(
    questionId: $checkedConvert('question_id', (v) => v as String),
    connection: $checkedConvert('connection', (v) => v as String),
    message: $checkedConvert('message', (v) => v as String),
    schema: $checkedConvert('schema', (v) => v as Map<String, dynamic>),
    expiresAt: $checkedConvert(
      'expires_at',
      (v) => DateTime.parse(v as String),
    ),
  );
  return val;
}, fieldKeyMap: const {'questionId': 'question_id', 'expiresAt': 'expires_at'});

Map<String, dynamic> _$McpQuestionEventPayloadToJson(
  McpQuestionEventPayload instance,
) => <String, dynamic>{
  'question_id': instance.questionId,
  'connection': instance.connection,
  'message': instance.message,
  'schema': instance.schema,
  'expires_at': instance.expiresAt.toIso8601String(),
};
