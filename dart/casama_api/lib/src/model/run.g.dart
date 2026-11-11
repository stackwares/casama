// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCWProxy {
  Run id(String id);

  Run botId(String botId);

  Run conversationId(String? conversationId);

  Run parentRunId(String? parentRunId);

  Run trigger(String trigger);

  Run status(RunStatus status);

  Run tokensIn(int tokensIn);

  Run tokensOut(int tokensOut);

  Run costUsd(num costUsd);

  Run lastSeq(int lastSeq);

  Run startedAt(DateTime? startedAt);

  Run endedAt(DateTime? endedAt);

  Run error(RunError? error);

  Run traceId(String? traceId);

  Run createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Run(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Run(...).copyWith(id: 12, name: "My name")
  /// ```
  Run call({
    String id,
    String botId,
    String? conversationId,
    String? parentRunId,
    String trigger,
    RunStatus status,
    int tokensIn,
    int tokensOut,
    num costUsd,
    int lastSeq,
    DateTime? startedAt,
    DateTime? endedAt,
    RunError? error,
    String? traceId,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRun.copyWith(...)` or call `instanceOfRun.copyWith.fieldName(value)` for a single field.
class _$RunCWProxyImpl implements _$RunCWProxy {
  const _$RunCWProxyImpl(this._value);

  final Run _value;

  @override
  Run id(String id) => call(id: id);

  @override
  Run botId(String botId) => call(botId: botId);

  @override
  Run conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  Run parentRunId(String? parentRunId) => call(parentRunId: parentRunId);

  @override
  Run trigger(String trigger) => call(trigger: trigger);

  @override
  Run status(RunStatus status) => call(status: status);

  @override
  Run tokensIn(int tokensIn) => call(tokensIn: tokensIn);

  @override
  Run tokensOut(int tokensOut) => call(tokensOut: tokensOut);

  @override
  Run costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  Run lastSeq(int lastSeq) => call(lastSeq: lastSeq);

  @override
  Run startedAt(DateTime? startedAt) => call(startedAt: startedAt);

  @override
  Run endedAt(DateTime? endedAt) => call(endedAt: endedAt);

  @override
  Run error(RunError? error) => call(error: error);

  @override
  Run traceId(String? traceId) => call(traceId: traceId);

  @override
  Run createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Run(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Run(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Run call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? parentRunId = const $CopyWithPlaceholder(),
    Object? trigger = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? lastSeq = const $CopyWithPlaceholder(),
    Object? startedAt = const $CopyWithPlaceholder(),
    Object? endedAt = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? traceId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Run(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      parentRunId: parentRunId == const $CopyWithPlaceholder()
          ? _value.parentRunId
          // ignore: cast_nullable_to_non_nullable
          : parentRunId as String?,
      trigger: trigger == const $CopyWithPlaceholder() || trigger == null
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RunStatus,
      tokensIn: tokensIn == const $CopyWithPlaceholder() || tokensIn == null
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder() || tokensOut == null
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      lastSeq: lastSeq == const $CopyWithPlaceholder() || lastSeq == null
          ? _value.lastSeq
          // ignore: cast_nullable_to_non_nullable
          : lastSeq as int,
      startedAt: startedAt == const $CopyWithPlaceholder()
          ? _value.startedAt
          // ignore: cast_nullable_to_non_nullable
          : startedAt as DateTime?,
      endedAt: endedAt == const $CopyWithPlaceholder()
          ? _value.endedAt
          // ignore: cast_nullable_to_non_nullable
          : endedAt as DateTime?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as RunError?,
      traceId: traceId == const $CopyWithPlaceholder()
          ? _value.traceId
          // ignore: cast_nullable_to_non_nullable
          : traceId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $RunCopyWith on Run {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRun.copyWith(...)` or `instanceOfRun.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCWProxy get copyWith => _$RunCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Run _$RunFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Run',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'conversation_id',
        'parent_run_id',
        'trigger',
        'status',
        'tokens_in',
        'tokens_out',
        'cost_usd',
        'last_seq',
        'started_at',
        'ended_at',
        'error',
        'trace_id',
        'created_at',
      ],
    );
    final val = Run(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      parentRunId: $checkedConvert('parent_run_id', (v) => v as String?),
      trigger: $checkedConvert('trigger', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$RunStatusEnumMap, v),
      ),
      tokensIn: $checkedConvert('tokens_in', (v) => (v as num).toInt()),
      tokensOut: $checkedConvert('tokens_out', (v) => (v as num).toInt()),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      lastSeq: $checkedConvert('last_seq', (v) => (v as num).toInt()),
      startedAt: $checkedConvert(
        'started_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      endedAt: $checkedConvert(
        'ended_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      error: $checkedConvert(
        'error',
        (v) => v == null ? null : RunError.fromJson(v as Map<String, dynamic>),
      ),
      traceId: $checkedConvert('trace_id', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'conversationId': 'conversation_id',
    'parentRunId': 'parent_run_id',
    'tokensIn': 'tokens_in',
    'tokensOut': 'tokens_out',
    'costUsd': 'cost_usd',
    'lastSeq': 'last_seq',
    'startedAt': 'started_at',
    'endedAt': 'ended_at',
    'traceId': 'trace_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$RunToJson(Run instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'conversation_id': instance.conversationId,
  'parent_run_id': instance.parentRunId,
  'trigger': instance.trigger,
  'status': _$RunStatusEnumMap[instance.status]!,
  'tokens_in': instance.tokensIn,
  'tokens_out': instance.tokensOut,
  'cost_usd': instance.costUsd,
  'last_seq': instance.lastSeq,
  'started_at': instance.startedAt?.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'error': instance.error?.toJson(),
  'trace_id': instance.traceId,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$RunStatusEnumMap = {
  RunStatus.queued: 'queued',
  RunStatus.running: 'running',
  RunStatus.waitingApproval: 'waiting_approval',
  RunStatus.waitingTakeover: 'waiting_takeover',
  RunStatus.completed: 'completed',
  RunStatus.failed: 'failed',
  RunStatus.cancelled: 'cancelled',
};
