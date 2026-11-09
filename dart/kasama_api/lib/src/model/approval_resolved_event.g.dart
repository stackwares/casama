// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_resolved_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalResolvedEventCWProxy {
  ApprovalResolvedEvent v(int v);

  ApprovalResolvedEvent runId(String runId);

  ApprovalResolvedEvent seq(int seq);

  ApprovalResolvedEvent ts(DateTime ts);

  ApprovalResolvedEvent botId(String botId);

  ApprovalResolvedEvent type(ApprovalResolvedEventTypeEnum type);

  ApprovalResolvedEvent payload(ApprovalResolvedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalResolvedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ApprovalResolvedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ApprovalResolvedEventTypeEnum type,
    ApprovalResolvedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApprovalResolvedEvent.copyWith(...)` or call `instanceOfApprovalResolvedEvent.copyWith.fieldName(value)` for a single field.
class _$ApprovalResolvedEventCWProxyImpl
    implements _$ApprovalResolvedEventCWProxy {
  const _$ApprovalResolvedEventCWProxyImpl(this._value);

  final ApprovalResolvedEvent _value;

  @override
  ApprovalResolvedEvent v(int v) => call(v: v);

  @override
  ApprovalResolvedEvent runId(String runId) => call(runId: runId);

  @override
  ApprovalResolvedEvent seq(int seq) => call(seq: seq);

  @override
  ApprovalResolvedEvent ts(DateTime ts) => call(ts: ts);

  @override
  ApprovalResolvedEvent botId(String botId) => call(botId: botId);

  @override
  ApprovalResolvedEvent type(ApprovalResolvedEventTypeEnum type) =>
      call(type: type);

  @override
  ApprovalResolvedEvent payload(ApprovalResolvedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalResolvedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApprovalResolvedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ApprovalResolvedEvent(
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
          : type as ApprovalResolvedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ApprovalResolvedEventPayload,
    );
  }
}

extension $ApprovalResolvedEventCopyWith on ApprovalResolvedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApprovalResolvedEvent.copyWith(...)` or `instanceOfApprovalResolvedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalResolvedEventCWProxy get copyWith =>
      _$ApprovalResolvedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalResolvedEvent _$ApprovalResolvedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ApprovalResolvedEvent', json, ($checkedConvert) {
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
  final val = ApprovalResolvedEvent(
    v: $checkedConvert('v', (v) => (v as num).toInt()),
    runId: $checkedConvert('run_id', (v) => v as String),
    seq: $checkedConvert('seq', (v) => (v as num).toInt()),
    ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
    botId: $checkedConvert('bot_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$ApprovalResolvedEventTypeEnumEnumMap, v),
    ),
    payload: $checkedConvert(
      'payload',
      (v) => ApprovalResolvedEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ApprovalResolvedEventToJson(
  ApprovalResolvedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$ApprovalResolvedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$ApprovalResolvedEventTypeEnumEnumMap = {
  ApprovalResolvedEventTypeEnum.approvalPeriodResolved: 'approval.resolved',
};
