// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_resolved_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretResolvedEventCWProxy {
  SecretResolvedEvent v(int v);

  SecretResolvedEvent runId(String runId);

  SecretResolvedEvent seq(int seq);

  SecretResolvedEvent ts(DateTime ts);

  SecretResolvedEvent botId(String botId);

  SecretResolvedEvent type(SecretResolvedEventTypeEnum type);

  SecretResolvedEvent payload(SecretResolvedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretResolvedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  SecretResolvedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    SecretResolvedEventTypeEnum type,
    SecretResolvedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecretResolvedEvent.copyWith(...)` or call `instanceOfSecretResolvedEvent.copyWith.fieldName(value)` for a single field.
class _$SecretResolvedEventCWProxyImpl implements _$SecretResolvedEventCWProxy {
  const _$SecretResolvedEventCWProxyImpl(this._value);

  final SecretResolvedEvent _value;

  @override
  SecretResolvedEvent v(int v) => call(v: v);

  @override
  SecretResolvedEvent runId(String runId) => call(runId: runId);

  @override
  SecretResolvedEvent seq(int seq) => call(seq: seq);

  @override
  SecretResolvedEvent ts(DateTime ts) => call(ts: ts);

  @override
  SecretResolvedEvent botId(String botId) => call(botId: botId);

  @override
  SecretResolvedEvent type(SecretResolvedEventTypeEnum type) =>
      call(type: type);

  @override
  SecretResolvedEvent payload(SecretResolvedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretResolvedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SecretResolvedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return SecretResolvedEvent(
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
          : type as SecretResolvedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as SecretResolvedEventPayload,
    );
  }
}

extension $SecretResolvedEventCopyWith on SecretResolvedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecretResolvedEvent.copyWith(...)` or `instanceOfSecretResolvedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretResolvedEventCWProxy get copyWith =>
      _$SecretResolvedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretResolvedEvent _$SecretResolvedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SecretResolvedEvent', json, ($checkedConvert) {
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
      final val = SecretResolvedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$SecretResolvedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => SecretResolvedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$SecretResolvedEventToJson(
  SecretResolvedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$SecretResolvedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$SecretResolvedEventTypeEnumEnumMap = {
  SecretResolvedEventTypeEnum.secretPeriodResolved: 'secret.resolved',
};
