// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_loaded_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillLoadedEventCWProxy {
  SkillLoadedEvent v(int v);

  SkillLoadedEvent runId(String runId);

  SkillLoadedEvent seq(int seq);

  SkillLoadedEvent ts(DateTime ts);

  SkillLoadedEvent botId(String botId);

  SkillLoadedEvent type(SkillLoadedEventTypeEnum type);

  SkillLoadedEvent payload(SkillLoadedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkillLoadedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkillLoadedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  SkillLoadedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    SkillLoadedEventTypeEnum type,
    SkillLoadedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSkillLoadedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSkillLoadedEvent.copyWith.fieldName(...)`
class _$SkillLoadedEventCWProxyImpl implements _$SkillLoadedEventCWProxy {
  const _$SkillLoadedEventCWProxyImpl(this._value);

  final SkillLoadedEvent _value;

  @override
  SkillLoadedEvent v(int v) => this(v: v);

  @override
  SkillLoadedEvent runId(String runId) => this(runId: runId);

  @override
  SkillLoadedEvent seq(int seq) => this(seq: seq);

  @override
  SkillLoadedEvent ts(DateTime ts) => this(ts: ts);

  @override
  SkillLoadedEvent botId(String botId) => this(botId: botId);

  @override
  SkillLoadedEvent type(SkillLoadedEventTypeEnum type) => this(type: type);

  @override
  SkillLoadedEvent payload(SkillLoadedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SkillLoadedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SkillLoadedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  SkillLoadedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return SkillLoadedEvent(
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
          : type as SkillLoadedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as SkillLoadedEventPayload,
    );
  }
}

extension $SkillLoadedEventCopyWith on SkillLoadedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfSkillLoadedEvent.copyWith(...)` or like so:`instanceOfSkillLoadedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillLoadedEventCWProxy get copyWith => _$SkillLoadedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillLoadedEvent _$SkillLoadedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkillLoadedEvent', json, ($checkedConvert) {
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
      final val = SkillLoadedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$SkillLoadedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => SkillLoadedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$SkillLoadedEventToJson(SkillLoadedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$SkillLoadedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$SkillLoadedEventTypeEnumEnumMap = {
  SkillLoadedEventTypeEnum.skillPeriodLoaded: 'skill.loaded',
};
