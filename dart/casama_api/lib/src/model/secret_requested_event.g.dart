// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_requested_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretRequestedEventCWProxy {
  SecretRequestedEvent v(int v);

  SecretRequestedEvent runId(String runId);

  SecretRequestedEvent seq(int seq);

  SecretRequestedEvent ts(DateTime ts);

  SecretRequestedEvent botId(String botId);

  SecretRequestedEvent type(SecretRequestedEventTypeEnum type);

  SecretRequestedEvent payload(SecretRequestedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  SecretRequestedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    SecretRequestedEventTypeEnum type,
    SecretRequestedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecretRequestedEvent.copyWith(...)` or call `instanceOfSecretRequestedEvent.copyWith.fieldName(value)` for a single field.
class _$SecretRequestedEventCWProxyImpl
    implements _$SecretRequestedEventCWProxy {
  const _$SecretRequestedEventCWProxyImpl(this._value);

  final SecretRequestedEvent _value;

  @override
  SecretRequestedEvent v(int v) => call(v: v);

  @override
  SecretRequestedEvent runId(String runId) => call(runId: runId);

  @override
  SecretRequestedEvent seq(int seq) => call(seq: seq);

  @override
  SecretRequestedEvent ts(DateTime ts) => call(ts: ts);

  @override
  SecretRequestedEvent botId(String botId) => call(botId: botId);

  @override
  SecretRequestedEvent type(SecretRequestedEventTypeEnum type) =>
      call(type: type);

  @override
  SecretRequestedEvent payload(SecretRequestedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SecretRequestedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return SecretRequestedEvent(
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
          : type as SecretRequestedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as SecretRequestedEventPayload,
    );
  }
}

extension $SecretRequestedEventCopyWith on SecretRequestedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecretRequestedEvent.copyWith(...)` or `instanceOfSecretRequestedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretRequestedEventCWProxy get copyWith =>
      _$SecretRequestedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretRequestedEvent _$SecretRequestedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SecretRequestedEvent', json, ($checkedConvert) {
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
  final val = SecretRequestedEvent(
    v: $checkedConvert('v', (v) => (v as num).toInt()),
    runId: $checkedConvert('run_id', (v) => v as String),
    seq: $checkedConvert('seq', (v) => (v as num).toInt()),
    ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
    botId: $checkedConvert('bot_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$SecretRequestedEventTypeEnumEnumMap, v),
    ),
    payload: $checkedConvert(
      'payload',
      (v) => SecretRequestedEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$SecretRequestedEventToJson(
  SecretRequestedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$SecretRequestedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$SecretRequestedEventTypeEnumEnumMap = {
  SecretRequestedEventTypeEnum.secretPeriodRequested: 'secret.requested',
};
