// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_event_envelope.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunEventEnvelopeCWProxy {
  RunEventEnvelope v(int v);

  RunEventEnvelope runId(String runId);

  RunEventEnvelope seq(int seq);

  RunEventEnvelope ts(DateTime ts);

  RunEventEnvelope botId(String botId);

  RunEventEnvelope type(String type);

  RunEventEnvelope payload(Map<String, Object?> payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunEventEnvelope(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunEventEnvelope(...).copyWith(id: 12, name: "My name")
  /// ````
  RunEventEnvelope call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    String type,
    Map<String, Object?> payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunEventEnvelope.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunEventEnvelope.copyWith.fieldName(...)`
class _$RunEventEnvelopeCWProxyImpl implements _$RunEventEnvelopeCWProxy {
  const _$RunEventEnvelopeCWProxyImpl(this._value);

  final RunEventEnvelope _value;

  @override
  RunEventEnvelope v(int v) => this(v: v);

  @override
  RunEventEnvelope runId(String runId) => this(runId: runId);

  @override
  RunEventEnvelope seq(int seq) => this(seq: seq);

  @override
  RunEventEnvelope ts(DateTime ts) => this(ts: ts);

  @override
  RunEventEnvelope botId(String botId) => this(botId: botId);

  @override
  RunEventEnvelope type(String type) => this(type: type);

  @override
  RunEventEnvelope payload(Map<String, Object?> payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunEventEnvelope(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunEventEnvelope(...).copyWith(id: 12, name: "My name")
  /// ````
  RunEventEnvelope call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return RunEventEnvelope(
      v: v == const $CopyWithPlaceholder()
          ? _value.v
          // ignore: cast_nullable_to_non_nullable
          : v as int,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      seq: seq == const $CopyWithPlaceholder()
          ? _value.seq
          // ignore: cast_nullable_to_non_nullable
          : seq as int,
      ts: ts == const $CopyWithPlaceholder()
          ? _value.ts
          // ignore: cast_nullable_to_non_nullable
          : ts as DateTime,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as String,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as Map<String, Object?>,
    );
  }
}

extension $RunEventEnvelopeCopyWith on RunEventEnvelope {
  /// Returns a callable class that can be used as follows: `instanceOfRunEventEnvelope.copyWith(...)` or like so:`instanceOfRunEventEnvelope.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunEventEnvelopeCWProxy get copyWith => _$RunEventEnvelopeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunEventEnvelope _$RunEventEnvelopeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunEventEnvelope', json, ($checkedConvert) {
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
      final val = RunEventEnvelope(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert('type', (v) => v as String),
        payload: $checkedConvert('payload', (v) => v as Map<String, dynamic>),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$RunEventEnvelopeToJson(RunEventEnvelope instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': instance.type,
      'payload': instance.payload,
    };
