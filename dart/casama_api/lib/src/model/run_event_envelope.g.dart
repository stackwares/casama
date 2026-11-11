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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunEventEnvelope(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunEventEnvelope(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunEventEnvelope.copyWith(...)` or call `instanceOfRunEventEnvelope.copyWith.fieldName(value)` for a single field.
class _$RunEventEnvelopeCWProxyImpl implements _$RunEventEnvelopeCWProxy {
  const _$RunEventEnvelopeCWProxyImpl(this._value);

  final RunEventEnvelope _value;

  @override
  RunEventEnvelope v(int v) => call(v: v);

  @override
  RunEventEnvelope runId(String runId) => call(runId: runId);

  @override
  RunEventEnvelope seq(int seq) => call(seq: seq);

  @override
  RunEventEnvelope ts(DateTime ts) => call(ts: ts);

  @override
  RunEventEnvelope botId(String botId) => call(botId: botId);

  @override
  RunEventEnvelope type(String type) => call(type: type);

  @override
  RunEventEnvelope payload(Map<String, Object?> payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunEventEnvelope(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunEventEnvelope(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as String,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as Map<String, Object?>,
    );
  }
}

extension $RunEventEnvelopeCopyWith on RunEventEnvelope {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunEventEnvelope.copyWith(...)` or `instanceOfRunEventEnvelope.copyWith.fieldName(...)`.
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
