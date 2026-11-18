// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_mcp_sign_in_needed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalMcpSignInNeededEventCWProxy {
  LocalMcpSignInNeededEvent v(int v);

  LocalMcpSignInNeededEvent runId(String runId);

  LocalMcpSignInNeededEvent seq(int seq);

  LocalMcpSignInNeededEvent ts(DateTime ts);

  LocalMcpSignInNeededEvent botId(String botId);

  LocalMcpSignInNeededEvent type(LocalMcpSignInNeededEventTypeEnum type);

  LocalMcpSignInNeededEvent payload(LocalMcpSignInNeededEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpSignInNeededEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpSignInNeededEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalMcpSignInNeededEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    LocalMcpSignInNeededEventTypeEnum type,
    LocalMcpSignInNeededEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalMcpSignInNeededEvent.copyWith(...)` or call `instanceOfLocalMcpSignInNeededEvent.copyWith.fieldName(value)` for a single field.
class _$LocalMcpSignInNeededEventCWProxyImpl
    implements _$LocalMcpSignInNeededEventCWProxy {
  const _$LocalMcpSignInNeededEventCWProxyImpl(this._value);

  final LocalMcpSignInNeededEvent _value;

  @override
  LocalMcpSignInNeededEvent v(int v) => call(v: v);

  @override
  LocalMcpSignInNeededEvent runId(String runId) => call(runId: runId);

  @override
  LocalMcpSignInNeededEvent seq(int seq) => call(seq: seq);

  @override
  LocalMcpSignInNeededEvent ts(DateTime ts) => call(ts: ts);

  @override
  LocalMcpSignInNeededEvent botId(String botId) => call(botId: botId);

  @override
  LocalMcpSignInNeededEvent type(LocalMcpSignInNeededEventTypeEnum type) =>
      call(type: type);

  @override
  LocalMcpSignInNeededEvent payload(LocalMcpSignInNeededEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalMcpSignInNeededEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalMcpSignInNeededEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalMcpSignInNeededEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return LocalMcpSignInNeededEvent(
      v: v == const $CopyWithPlaceholder() || v == null
          ? _value.v
          // ignore: cast_nullable_to_non_nullable
          : v as int,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      seq: seq == const $CopyWithPlaceholder() || seq == null
          ? _value.seq
          // ignore: cast_nullable_to_non_nullable
          : seq as int,
      ts: ts == const $CopyWithPlaceholder() || ts == null
          ? _value.ts
          // ignore: cast_nullable_to_non_nullable
          : ts as DateTime,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as LocalMcpSignInNeededEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as LocalMcpSignInNeededEventPayload,
    );
  }
}

extension $LocalMcpSignInNeededEventCopyWith on LocalMcpSignInNeededEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalMcpSignInNeededEvent.copyWith(...)` or `instanceOfLocalMcpSignInNeededEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalMcpSignInNeededEventCWProxy get copyWith =>
      _$LocalMcpSignInNeededEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalMcpSignInNeededEvent _$LocalMcpSignInNeededEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('LocalMcpSignInNeededEvent', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'v',
      'run_id',
      'seq',
      'ts',
      'bot_id',
      'type',
      'payload',
    ],
  );
  final val = LocalMcpSignInNeededEvent(
    v: $checkedConvert('v', (v) => (v as num).toInt()),
    runId: $checkedConvert('run_id', (v) => v as String),
    seq: $checkedConvert('seq', (v) => (v as num).toInt()),
    ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
    botId: $checkedConvert('bot_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$LocalMcpSignInNeededEventTypeEnumEnumMap, v),
    ),
    payload: $checkedConvert(
      'payload',
      (v) =>
          LocalMcpSignInNeededEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$LocalMcpSignInNeededEventToJson(
  LocalMcpSignInNeededEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$LocalMcpSignInNeededEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$LocalMcpSignInNeededEventTypeEnumEnumMap = {
  LocalMcpSignInNeededEventTypeEnum.localMcpPeriodSignInNeeded:
      'local_mcp.sign_in_needed',
};
