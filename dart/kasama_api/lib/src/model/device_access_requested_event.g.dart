// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_access_requested_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceAccessRequestedEventCWProxy {
  DeviceAccessRequestedEvent v(int v);

  DeviceAccessRequestedEvent runId(String runId);

  DeviceAccessRequestedEvent seq(int seq);

  DeviceAccessRequestedEvent ts(DateTime ts);

  DeviceAccessRequestedEvent botId(String botId);

  DeviceAccessRequestedEvent type(DeviceAccessRequestedEventTypeEnum type);

  DeviceAccessRequestedEvent payload(DeviceAccessRequestedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceAccessRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceAccessRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceAccessRequestedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    DeviceAccessRequestedEventTypeEnum type,
    DeviceAccessRequestedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceAccessRequestedEvent.copyWith(...)` or call `instanceOfDeviceAccessRequestedEvent.copyWith.fieldName(value)` for a single field.
class _$DeviceAccessRequestedEventCWProxyImpl
    implements _$DeviceAccessRequestedEventCWProxy {
  const _$DeviceAccessRequestedEventCWProxyImpl(this._value);

  final DeviceAccessRequestedEvent _value;

  @override
  DeviceAccessRequestedEvent v(int v) => call(v: v);

  @override
  DeviceAccessRequestedEvent runId(String runId) => call(runId: runId);

  @override
  DeviceAccessRequestedEvent seq(int seq) => call(seq: seq);

  @override
  DeviceAccessRequestedEvent ts(DateTime ts) => call(ts: ts);

  @override
  DeviceAccessRequestedEvent botId(String botId) => call(botId: botId);

  @override
  DeviceAccessRequestedEvent type(DeviceAccessRequestedEventTypeEnum type) =>
      call(type: type);

  @override
  DeviceAccessRequestedEvent payload(
    DeviceAccessRequestedEventPayload payload,
  ) => call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceAccessRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceAccessRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceAccessRequestedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return DeviceAccessRequestedEvent(
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
          : type as DeviceAccessRequestedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as DeviceAccessRequestedEventPayload,
    );
  }
}

extension $DeviceAccessRequestedEventCopyWith on DeviceAccessRequestedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceAccessRequestedEvent.copyWith(...)` or `instanceOfDeviceAccessRequestedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceAccessRequestedEventCWProxy get copyWith =>
      _$DeviceAccessRequestedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceAccessRequestedEvent _$DeviceAccessRequestedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeviceAccessRequestedEvent', json, ($checkedConvert) {
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
  final val = DeviceAccessRequestedEvent(
    v: $checkedConvert('v', (v) => (v as num).toInt()),
    runId: $checkedConvert('run_id', (v) => v as String),
    seq: $checkedConvert('seq', (v) => (v as num).toInt()),
    ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
    botId: $checkedConvert('bot_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$DeviceAccessRequestedEventTypeEnumEnumMap, v),
    ),
    payload: $checkedConvert(
      'payload',
      (v) =>
          DeviceAccessRequestedEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$DeviceAccessRequestedEventToJson(
  DeviceAccessRequestedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$DeviceAccessRequestedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$DeviceAccessRequestedEventTypeEnumEnumMap = {
  DeviceAccessRequestedEventTypeEnum.devicePeriodAccessRequested:
      'device.access_requested',
};
