// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_usage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunUsageCWProxy {
  RunUsage runId(String runId);

  RunUsage status(RunStatus status);

  RunUsage costUsd(num costUsd);

  RunUsage chargedUsd(num chargedUsd);

  RunUsage upstreamCostUsd(num? upstreamCostUsd);

  RunUsage tokensIn(int tokensIn);

  RunUsage tokensOut(int tokensOut);

  RunUsage durationMs(int? durationMs);

  RunUsage toolCalls(int toolCalls);

  RunUsage subruns(int subruns);

  RunUsage items(List<RunUsageItemsInner> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  RunUsage call({
    String runId,
    RunStatus status,
    num costUsd,
    num chargedUsd,
    num? upstreamCostUsd,
    int tokensIn,
    int tokensOut,
    int? durationMs,
    int toolCalls,
    int subruns,
    List<RunUsageItemsInner> items,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunUsage.copyWith(...)` or call `instanceOfRunUsage.copyWith.fieldName(value)` for a single field.
class _$RunUsageCWProxyImpl implements _$RunUsageCWProxy {
  const _$RunUsageCWProxyImpl(this._value);

  final RunUsage _value;

  @override
  RunUsage runId(String runId) => call(runId: runId);

  @override
  RunUsage status(RunStatus status) => call(status: status);

  @override
  RunUsage costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  RunUsage chargedUsd(num chargedUsd) => call(chargedUsd: chargedUsd);

  @override
  RunUsage upstreamCostUsd(num? upstreamCostUsd) =>
      call(upstreamCostUsd: upstreamCostUsd);

  @override
  RunUsage tokensIn(int tokensIn) => call(tokensIn: tokensIn);

  @override
  RunUsage tokensOut(int tokensOut) => call(tokensOut: tokensOut);

  @override
  RunUsage durationMs(int? durationMs) => call(durationMs: durationMs);

  @override
  RunUsage toolCalls(int toolCalls) => call(toolCalls: toolCalls);

  @override
  RunUsage subruns(int subruns) => call(subruns: subruns);

  @override
  RunUsage items(List<RunUsageItemsInner> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunUsage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunUsage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunUsage call({
    Object? runId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? chargedUsd = const $CopyWithPlaceholder(),
    Object? upstreamCostUsd = const $CopyWithPlaceholder(),
    Object? tokensIn = const $CopyWithPlaceholder(),
    Object? tokensOut = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
    Object? toolCalls = const $CopyWithPlaceholder(),
    Object? subruns = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return RunUsage(
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as RunStatus,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      chargedUsd:
          chargedUsd == const $CopyWithPlaceholder() || chargedUsd == null
          ? _value.chargedUsd
          // ignore: cast_nullable_to_non_nullable
          : chargedUsd as num,
      upstreamCostUsd: upstreamCostUsd == const $CopyWithPlaceholder()
          ? _value.upstreamCostUsd
          // ignore: cast_nullable_to_non_nullable
          : upstreamCostUsd as num?,
      tokensIn: tokensIn == const $CopyWithPlaceholder() || tokensIn == null
          ? _value.tokensIn
          // ignore: cast_nullable_to_non_nullable
          : tokensIn as int,
      tokensOut: tokensOut == const $CopyWithPlaceholder() || tokensOut == null
          ? _value.tokensOut
          // ignore: cast_nullable_to_non_nullable
          : tokensOut as int,
      durationMs: durationMs == const $CopyWithPlaceholder()
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int?,
      toolCalls: toolCalls == const $CopyWithPlaceholder() || toolCalls == null
          ? _value.toolCalls
          // ignore: cast_nullable_to_non_nullable
          : toolCalls as int,
      subruns: subruns == const $CopyWithPlaceholder() || subruns == null
          ? _value.subruns
          // ignore: cast_nullable_to_non_nullable
          : subruns as int,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<RunUsageItemsInner>,
    );
  }
}

extension $RunUsageCopyWith on RunUsage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunUsage.copyWith(...)` or `instanceOfRunUsage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunUsageCWProxy get copyWith => _$RunUsageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunUsage _$RunUsageFromJson(Map<String, dynamic> json) => $checkedCreate(
  'RunUsage',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'run_id',
        'status',
        'cost_usd',
        'charged_usd',
        'tokens_in',
        'tokens_out',
        'duration_ms',
        'tool_calls',
        'subruns',
        'items',
      ],
    );
    final val = RunUsage(
      runId: $checkedConvert('run_id', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$RunStatusEnumMap, v),
      ),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      chargedUsd: $checkedConvert('charged_usd', (v) => v as num),
      upstreamCostUsd: $checkedConvert('upstream_cost_usd', (v) => v as num?),
      tokensIn: $checkedConvert('tokens_in', (v) => (v as num).toInt()),
      tokensOut: $checkedConvert('tokens_out', (v) => (v as num).toInt()),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num?)?.toInt()),
      toolCalls: $checkedConvert('tool_calls', (v) => (v as num).toInt()),
      subruns: $checkedConvert('subruns', (v) => (v as num).toInt()),
      items: $checkedConvert(
        'items',
        (v) => (v as List<dynamic>)
            .map((e) => RunUsageItemsInner.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'runId': 'run_id',
    'costUsd': 'cost_usd',
    'chargedUsd': 'charged_usd',
    'upstreamCostUsd': 'upstream_cost_usd',
    'tokensIn': 'tokens_in',
    'tokensOut': 'tokens_out',
    'durationMs': 'duration_ms',
    'toolCalls': 'tool_calls',
  },
);

Map<String, dynamic> _$RunUsageToJson(RunUsage instance) => <String, dynamic>{
  'run_id': instance.runId,
  'status': _$RunStatusEnumMap[instance.status]!,
  'cost_usd': instance.costUsd,
  'charged_usd': instance.chargedUsd,
  'upstream_cost_usd': ?instance.upstreamCostUsd,
  'tokens_in': instance.tokensIn,
  'tokens_out': instance.tokensOut,
  'duration_ms': instance.durationMs,
  'tool_calls': instance.toolCalls,
  'subruns': instance.subruns,
  'items': instance.items.map((e) => e.toJson()).toList(),
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
