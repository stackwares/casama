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

  Run createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Run(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Run(...).copyWith(id: 12, name: "My name")
  /// ````
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
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRun.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRun.copyWith.fieldName(...)`
class _$RunCWProxyImpl implements _$RunCWProxy {
  const _$RunCWProxyImpl(this._value);

  final Run _value;

  @override
  Run id(String id) => this(id: id);

  @override
  Run botId(String botId) => this(botId: botId);

  @override
  Run conversationId(String? conversationId) =>
      this(conversationId: conversationId);

  @override
  Run parentRunId(String? parentRunId) => this(parentRunId: parentRunId);

  @override
  Run trigger(String trigger) => this(trigger: trigger);

  @override
  Run status(RunStatus status) => this(status: status);

  @override
  Run tokensIn(int tokensIn) => this(tokensIn: tokensIn);

  @override
  Run tokensOut(int tokensOut) => this(tokensOut: tokensOut);

  @override
  Run costUsd(num costUsd) => this(costUsd: costUsd);

  @override
  Run lastSeq(int lastSeq) => this(lastSeq: lastSeq);

  @override
  Run startedAt(DateTime? startedAt) => this(startedAt: startedAt);

  @override
  Run endedAt(DateTime? endedAt) => this(endedAt: endedAt);

  @override
  Run error(RunError? error) => this(error: error);

  @override
  Run createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Run(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Run(...).copyWith(id: 12, name: "My name")
  /// ````
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
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Run(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder()
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
      trigger: trigger == const $CopyWithPlaceholder()
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RunStatus,
      tokensIn: tokensIn == const $CopyWithPlaceholder()
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder()
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
      costUsd: costUsd == const $CopyWithPlaceholder()
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      lastSeq: lastSeq == const $CopyWithPlaceholder()
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
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $RunCopyWith on Run {
  /// Returns a callable class that can be used as follows: `instanceOfRun.copyWith(...)` or like so:`instanceOfRun.copyWith.fieldName(...)`.
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
