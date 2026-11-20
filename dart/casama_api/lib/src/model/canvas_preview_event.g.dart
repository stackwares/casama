// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_preview_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasPreviewEventCWProxy {
  CanvasPreviewEvent v(int v);

  CanvasPreviewEvent runId(String runId);

  CanvasPreviewEvent seq(int seq);

  CanvasPreviewEvent ts(DateTime ts);

  CanvasPreviewEvent botId(String botId);

  CanvasPreviewEvent type(CanvasPreviewEventTypeEnum type);

  CanvasPreviewEvent payload(CanvasPreviewEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasPreviewEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasPreviewEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasPreviewEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    CanvasPreviewEventTypeEnum type,
    CanvasPreviewEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasPreviewEvent.copyWith(...)` or call `instanceOfCanvasPreviewEvent.copyWith.fieldName(value)` for a single field.
class _$CanvasPreviewEventCWProxyImpl implements _$CanvasPreviewEventCWProxy {
  const _$CanvasPreviewEventCWProxyImpl(this._value);

  final CanvasPreviewEvent _value;

  @override
  CanvasPreviewEvent v(int v) => call(v: v);

  @override
  CanvasPreviewEvent runId(String runId) => call(runId: runId);

  @override
  CanvasPreviewEvent seq(int seq) => call(seq: seq);

  @override
  CanvasPreviewEvent ts(DateTime ts) => call(ts: ts);

  @override
  CanvasPreviewEvent botId(String botId) => call(botId: botId);

  @override
  CanvasPreviewEvent type(CanvasPreviewEventTypeEnum type) => call(type: type);

  @override
  CanvasPreviewEvent payload(CanvasPreviewEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasPreviewEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasPreviewEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasPreviewEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return CanvasPreviewEvent(
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
          : type as CanvasPreviewEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as CanvasPreviewEventPayload,
    );
  }
}

extension $CanvasPreviewEventCopyWith on CanvasPreviewEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasPreviewEvent.copyWith(...)` or `instanceOfCanvasPreviewEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasPreviewEventCWProxy get copyWith =>
      _$CanvasPreviewEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasPreviewEvent _$CanvasPreviewEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CanvasPreviewEvent', json, ($checkedConvert) {
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
      final val = CanvasPreviewEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$CanvasPreviewEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => CanvasPreviewEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$CanvasPreviewEventToJson(CanvasPreviewEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$CanvasPreviewEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$CanvasPreviewEventTypeEnumEnumMap = {
  CanvasPreviewEventTypeEnum.canvasPeriodPreview: 'canvas.preview',
};
