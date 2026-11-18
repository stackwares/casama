// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_data_used_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceDataUsedEventCWProxy {
  DeviceDataUsedEvent v(int v);

  DeviceDataUsedEvent runId(String runId);

  DeviceDataUsedEvent seq(int seq);

  DeviceDataUsedEvent ts(DateTime ts);

  DeviceDataUsedEvent botId(String botId);

  DeviceDataUsedEvent type(DeviceDataUsedEventTypeEnum type);

  DeviceDataUsedEvent payload(DeviceDataUsedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceDataUsedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceDataUsedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceDataUsedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    DeviceDataUsedEventTypeEnum type,
    DeviceDataUsedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceDataUsedEvent.copyWith(...)` or call `instanceOfDeviceDataUsedEvent.copyWith.fieldName(value)` for a single field.
class _$DeviceDataUsedEventCWProxyImpl implements _$DeviceDataUsedEventCWProxy {
  const _$DeviceDataUsedEventCWProxyImpl(this._value);

  final DeviceDataUsedEvent _value;

  @override
  DeviceDataUsedEvent v(int v) => call(v: v);

  @override
  DeviceDataUsedEvent runId(String runId) => call(runId: runId);

  @override
  DeviceDataUsedEvent seq(int seq) => call(seq: seq);

  @override
  DeviceDataUsedEvent ts(DateTime ts) => call(ts: ts);

  @override
  DeviceDataUsedEvent botId(String botId) => call(botId: botId);

  @override
  DeviceDataUsedEvent type(DeviceDataUsedEventTypeEnum type) =>
      call(type: type);

  @override
  DeviceDataUsedEvent payload(DeviceDataUsedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceDataUsedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceDataUsedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceDataUsedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return DeviceDataUsedEvent(
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
          : type as DeviceDataUsedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as DeviceDataUsedEventPayload,
    );
  }
}

extension $DeviceDataUsedEventCopyWith on DeviceDataUsedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceDataUsedEvent.copyWith(...)` or `instanceOfDeviceDataUsedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceDataUsedEventCWProxy get copyWith =>
      _$DeviceDataUsedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDataUsedEvent _$DeviceDataUsedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceDataUsedEvent', json, ($checkedConvert) {
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
      final val = DeviceDataUsedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$DeviceDataUsedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => DeviceDataUsedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$DeviceDataUsedEventToJson(
  DeviceDataUsedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$DeviceDataUsedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$DeviceDataUsedEventTypeEnumEnumMap = {
  DeviceDataUsedEventTypeEnum.devicePeriodDataUsed: 'device.data_used',
};
