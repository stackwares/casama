// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_shown_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UiShownEventCWProxy {
  UiShownEvent v(int v);

  UiShownEvent runId(String runId);

  UiShownEvent seq(int seq);

  UiShownEvent ts(DateTime ts);

  UiShownEvent botId(String botId);

  UiShownEvent type(UiShownEventTypeEnum type);

  UiShownEvent payload(UiShownEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UiShownEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UiShownEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  UiShownEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    UiShownEventTypeEnum type,
    UiShownEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUiShownEvent.copyWith(...)` or call `instanceOfUiShownEvent.copyWith.fieldName(value)` for a single field.
class _$UiShownEventCWProxyImpl implements _$UiShownEventCWProxy {
  const _$UiShownEventCWProxyImpl(this._value);

  final UiShownEvent _value;

  @override
  UiShownEvent v(int v) => call(v: v);

  @override
  UiShownEvent runId(String runId) => call(runId: runId);

  @override
  UiShownEvent seq(int seq) => call(seq: seq);

  @override
  UiShownEvent ts(DateTime ts) => call(ts: ts);

  @override
  UiShownEvent botId(String botId) => call(botId: botId);

  @override
  UiShownEvent type(UiShownEventTypeEnum type) => call(type: type);

  @override
  UiShownEvent payload(UiShownEventPayload payload) => call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UiShownEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UiShownEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UiShownEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return UiShownEvent(
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
          : type as UiShownEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as UiShownEventPayload,
    );
  }
}

extension $UiShownEventCopyWith on UiShownEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUiShownEvent.copyWith(...)` or `instanceOfUiShownEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UiShownEventCWProxy get copyWith => _$UiShownEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UiShownEvent _$UiShownEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UiShownEvent', json, ($checkedConvert) {
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
      final val = UiShownEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$UiShownEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => UiShownEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$UiShownEventToJson(UiShownEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$UiShownEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$UiShownEventTypeEnumEnumMap = {
  UiShownEventTypeEnum.uiPeriodShown: 'ui.shown',
};
