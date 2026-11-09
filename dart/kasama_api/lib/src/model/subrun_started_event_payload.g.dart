// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subrun_started_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubrunStartedEventPayloadCWProxy {
  SubrunStartedEventPayload childRunId(String childRunId);

  SubrunStartedEventPayload botId(String botId);

  SubrunStartedEventPayload task(String task);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubrunStartedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubrunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  SubrunStartedEventPayload call({
    String childRunId,
    String botId,
    String task,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubrunStartedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubrunStartedEventPayload.copyWith.fieldName(...)`
class _$SubrunStartedEventPayloadCWProxyImpl
    implements _$SubrunStartedEventPayloadCWProxy {
  const _$SubrunStartedEventPayloadCWProxyImpl(this._value);

  final SubrunStartedEventPayload _value;

  @override
  SubrunStartedEventPayload childRunId(String childRunId) =>
      this(childRunId: childRunId);

  @override
  SubrunStartedEventPayload botId(String botId) => this(botId: botId);

  @override
  SubrunStartedEventPayload task(String task) => this(task: task);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubrunStartedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubrunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  SubrunStartedEventPayload call({
    Object? childRunId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? task = const $CopyWithPlaceholder(),
  }) {
    return SubrunStartedEventPayload(
      childRunId: childRunId == const $CopyWithPlaceholder()
          ? _value.childRunId
          // ignore: cast_nullable_to_non_nullable
          : childRunId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      task: task == const $CopyWithPlaceholder()
          ? _value.task
          // ignore: cast_nullable_to_non_nullable
          : task as String,
    );
  }
}

extension $SubrunStartedEventPayloadCopyWith on SubrunStartedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfSubrunStartedEventPayload.copyWith(...)` or like so:`instanceOfSubrunStartedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubrunStartedEventPayloadCWProxy get copyWith =>
      _$SubrunStartedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubrunStartedEventPayload _$SubrunStartedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SubrunStartedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['child_run_id', 'bot_id', 'task']);
    final val = SubrunStartedEventPayload(
      childRunId: $checkedConvert('child_run_id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      task: $checkedConvert('task', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'childRunId': 'child_run_id', 'botId': 'bot_id'},
);

Map<String, dynamic> _$SubrunStartedEventPayloadToJson(
  SubrunStartedEventPayload instance,
) => <String, dynamic>{
  'child_run_id': instance.childRunId,
  'bot_id': instance.botId,
  'task': instance.task,
};
