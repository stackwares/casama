// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_question.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpQuestionCWProxy {
  McpQuestion id(String id);

  McpQuestion orgId(String orgId);

  McpQuestion botId(String botId);

  McpQuestion runId(String runId);

  McpQuestion connection(String connection);

  McpQuestion message(String message);

  McpQuestion schema(Map<String, Object?> schema);

  McpQuestion status(McpQuestionStatusEnum status);

  McpQuestion expiresAt(DateTime expiresAt);

  McpQuestion createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestion(...).copyWith(id: 12, name: "My name")
  /// ```
  McpQuestion call({
    String id,
    String orgId,
    String botId,
    String runId,
    String connection,
    String message,
    Map<String, Object?> schema,
    McpQuestionStatusEnum status,
    DateTime expiresAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpQuestion.copyWith(...)` or call `instanceOfMcpQuestion.copyWith.fieldName(value)` for a single field.
class _$McpQuestionCWProxyImpl implements _$McpQuestionCWProxy {
  const _$McpQuestionCWProxyImpl(this._value);

  final McpQuestion _value;

  @override
  McpQuestion id(String id) => call(id: id);

  @override
  McpQuestion orgId(String orgId) => call(orgId: orgId);

  @override
  McpQuestion botId(String botId) => call(botId: botId);

  @override
  McpQuestion runId(String runId) => call(runId: runId);

  @override
  McpQuestion connection(String connection) => call(connection: connection);

  @override
  McpQuestion message(String message) => call(message: message);

  @override
  McpQuestion schema(Map<String, Object?> schema) => call(schema: schema);

  @override
  McpQuestion status(McpQuestionStatusEnum status) => call(status: status);

  @override
  McpQuestion expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  @override
  McpQuestion createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestion(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestion(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpQuestion call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? connection = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? schema = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return McpQuestion(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
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
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as McpQuestionStatusEnum,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $McpQuestionCopyWith on McpQuestion {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpQuestion.copyWith(...)` or `instanceOfMcpQuestion.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpQuestionCWProxy get copyWith => _$McpQuestionCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpQuestion _$McpQuestionFromJson(Map<String, dynamic> json) => $checkedCreate(
  'McpQuestion',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'org_id',
        'bot_id',
        'run_id',
        'connection',
        'message',
        'schema',
        'status',
        'expires_at',
        'created_at',
      ],
    );
    final val = McpQuestion(
      id: $checkedConvert('id', (v) => v as String),
      orgId: $checkedConvert('org_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      runId: $checkedConvert('run_id', (v) => v as String),
      connection: $checkedConvert('connection', (v) => v as String),
      message: $checkedConvert('message', (v) => v as String),
      schema: $checkedConvert('schema', (v) => v as Map<String, dynamic>),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$McpQuestionStatusEnumEnumMap, v),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'botId': 'bot_id',
    'runId': 'run_id',
    'expiresAt': 'expires_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$McpQuestionToJson(McpQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'bot_id': instance.botId,
      'run_id': instance.runId,
      'connection': instance.connection,
      'message': instance.message,
      'schema': instance.schema,
      'status': _$McpQuestionStatusEnumEnumMap[instance.status]!,
      'expires_at': instance.expiresAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$McpQuestionStatusEnumEnumMap = {
  McpQuestionStatusEnum.pending: 'pending',
  McpQuestionStatusEnum.accepted: 'accepted',
  McpQuestionStatusEnum.declined: 'declined',
  McpQuestionStatusEnum.cancelled: 'cancelled',
  McpQuestionStatusEnum.expired: 'expired',
};
