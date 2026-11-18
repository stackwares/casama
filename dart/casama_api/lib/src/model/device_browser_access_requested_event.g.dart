// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_browser_access_requested_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceBrowserAccessRequestedEventCWProxy {
  DeviceBrowserAccessRequestedEvent v(int v);

  DeviceBrowserAccessRequestedEvent runId(String runId);

  DeviceBrowserAccessRequestedEvent seq(int seq);

  DeviceBrowserAccessRequestedEvent ts(DateTime ts);

  DeviceBrowserAccessRequestedEvent botId(String botId);

  DeviceBrowserAccessRequestedEvent type(
    DeviceBrowserAccessRequestedEventTypeEnum type,
  );

  DeviceBrowserAccessRequestedEvent payload(
    DeviceBrowserAccessRequestedEventPayload payload,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceBrowserAccessRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceBrowserAccessRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceBrowserAccessRequestedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    DeviceBrowserAccessRequestedEventTypeEnum type,
    DeviceBrowserAccessRequestedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceBrowserAccessRequestedEvent.copyWith(...)` or call `instanceOfDeviceBrowserAccessRequestedEvent.copyWith.fieldName(value)` for a single field.
class _$DeviceBrowserAccessRequestedEventCWProxyImpl
    implements _$DeviceBrowserAccessRequestedEventCWProxy {
  const _$DeviceBrowserAccessRequestedEventCWProxyImpl(this._value);

  final DeviceBrowserAccessRequestedEvent _value;

  @override
  DeviceBrowserAccessRequestedEvent v(int v) => call(v: v);

  @override
  DeviceBrowserAccessRequestedEvent runId(String runId) => call(runId: runId);

  @override
  DeviceBrowserAccessRequestedEvent seq(int seq) => call(seq: seq);

  @override
  DeviceBrowserAccessRequestedEvent ts(DateTime ts) => call(ts: ts);

  @override
  DeviceBrowserAccessRequestedEvent botId(String botId) => call(botId: botId);

  @override
  DeviceBrowserAccessRequestedEvent type(
    DeviceBrowserAccessRequestedEventTypeEnum type,
  ) => call(type: type);

  @override
  DeviceBrowserAccessRequestedEvent payload(
    DeviceBrowserAccessRequestedEventPayload payload,
  ) => call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceBrowserAccessRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceBrowserAccessRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceBrowserAccessRequestedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return DeviceBrowserAccessRequestedEvent(
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
          : type as DeviceBrowserAccessRequestedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as DeviceBrowserAccessRequestedEventPayload,
    );
  }
}

extension $DeviceBrowserAccessRequestedEventCopyWith
    on DeviceBrowserAccessRequestedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceBrowserAccessRequestedEvent.copyWith(...)` or `instanceOfDeviceBrowserAccessRequestedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceBrowserAccessRequestedEventCWProxy get copyWith =>
      _$DeviceBrowserAccessRequestedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceBrowserAccessRequestedEvent _$DeviceBrowserAccessRequestedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeviceBrowserAccessRequestedEvent', json, (
  $checkedConvert,
) {
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
  final val = DeviceBrowserAccessRequestedEvent(
    v: $checkedConvert('v', (v) => (v as num).toInt()),
    runId: $checkedConvert('run_id', (v) => v as String),
    seq: $checkedConvert('seq', (v) => (v as num).toInt()),
    ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
    botId: $checkedConvert('bot_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$DeviceBrowserAccessRequestedEventTypeEnumEnumMap, v),
    ),
    payload: $checkedConvert(
      'payload',
      (v) => DeviceBrowserAccessRequestedEventPayload.fromJson(
        v as Map<String, dynamic>,
      ),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$DeviceBrowserAccessRequestedEventToJson(
  DeviceBrowserAccessRequestedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$DeviceBrowserAccessRequestedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$DeviceBrowserAccessRequestedEventTypeEnumEnumMap = {
  DeviceBrowserAccessRequestedEventTypeEnum.devicePeriodBrowserAccessRequested:
      'device.browser_access_requested',
};
