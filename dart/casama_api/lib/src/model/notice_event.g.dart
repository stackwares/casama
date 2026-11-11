// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NoticeEventCWProxy {
  NoticeEvent v(int v);

  NoticeEvent runId(String runId);

  NoticeEvent seq(int seq);

  NoticeEvent ts(DateTime ts);

  NoticeEvent botId(String botId);

  NoticeEvent type(NoticeEventTypeEnum type);

  NoticeEvent payload(NoticeEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NoticeEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NoticeEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  NoticeEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    NoticeEventTypeEnum type,
    NoticeEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNoticeEvent.copyWith(...)` or call `instanceOfNoticeEvent.copyWith.fieldName(value)` for a single field.
class _$NoticeEventCWProxyImpl implements _$NoticeEventCWProxy {
  const _$NoticeEventCWProxyImpl(this._value);

  final NoticeEvent _value;

  @override
  NoticeEvent v(int v) => call(v: v);

  @override
  NoticeEvent runId(String runId) => call(runId: runId);

  @override
  NoticeEvent seq(int seq) => call(seq: seq);

  @override
  NoticeEvent ts(DateTime ts) => call(ts: ts);

  @override
  NoticeEvent botId(String botId) => call(botId: botId);

  @override
  NoticeEvent type(NoticeEventTypeEnum type) => call(type: type);

  @override
  NoticeEvent payload(NoticeEventPayload payload) => call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NoticeEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NoticeEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NoticeEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return NoticeEvent(
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
          : type as NoticeEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as NoticeEventPayload,
    );
  }
}

extension $NoticeEventCopyWith on NoticeEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNoticeEvent.copyWith(...)` or `instanceOfNoticeEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NoticeEventCWProxy get copyWith => _$NoticeEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoticeEvent _$NoticeEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NoticeEvent', json, ($checkedConvert) {
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
      final val = NoticeEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$NoticeEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => NoticeEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$NoticeEventToJson(NoticeEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$NoticeEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$NoticeEventTypeEnumEnumMap = {NoticeEventTypeEnum.notice: 'notice'};
