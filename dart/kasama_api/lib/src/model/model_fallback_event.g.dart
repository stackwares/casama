// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_fallback_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelFallbackEventCWProxy {
  ModelFallbackEvent v(int v);

  ModelFallbackEvent runId(String runId);

  ModelFallbackEvent seq(int seq);

  ModelFallbackEvent ts(DateTime ts);

  ModelFallbackEvent botId(String botId);

  ModelFallbackEvent type(ModelFallbackEventTypeEnum type);

  ModelFallbackEvent payload(ModelFallbackEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelFallbackEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelFallbackEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ModelFallbackEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ModelFallbackEventTypeEnum type,
    ModelFallbackEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfModelFallbackEvent.copyWith(...)` or call `instanceOfModelFallbackEvent.copyWith.fieldName(value)` for a single field.
class _$ModelFallbackEventCWProxyImpl implements _$ModelFallbackEventCWProxy {
  const _$ModelFallbackEventCWProxyImpl(this._value);

  final ModelFallbackEvent _value;

  @override
  ModelFallbackEvent v(int v) => call(v: v);

  @override
  ModelFallbackEvent runId(String runId) => call(runId: runId);

  @override
  ModelFallbackEvent seq(int seq) => call(seq: seq);

  @override
  ModelFallbackEvent ts(DateTime ts) => call(ts: ts);

  @override
  ModelFallbackEvent botId(String botId) => call(botId: botId);

  @override
  ModelFallbackEvent type(ModelFallbackEventTypeEnum type) => call(type: type);

  @override
  ModelFallbackEvent payload(ModelFallbackEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelFallbackEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelFallbackEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ModelFallbackEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ModelFallbackEvent(
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
          : type as ModelFallbackEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ModelFallbackEventPayload,
    );
  }
}

extension $ModelFallbackEventCopyWith on ModelFallbackEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfModelFallbackEvent.copyWith(...)` or `instanceOfModelFallbackEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelFallbackEventCWProxy get copyWith =>
      _$ModelFallbackEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelFallbackEvent _$ModelFallbackEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ModelFallbackEvent', json, ($checkedConvert) {
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
      final val = ModelFallbackEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ModelFallbackEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ModelFallbackEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ModelFallbackEventToJson(ModelFallbackEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ModelFallbackEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ModelFallbackEventTypeEnumEnumMap = {
  ModelFallbackEventTypeEnum.modelPeriodFallback: 'model.fallback',
};
