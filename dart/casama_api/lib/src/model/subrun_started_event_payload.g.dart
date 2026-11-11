// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subrun_started_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubrunStartedEventPayloadCWProxy {
  SubrunStartedEventPayload childRunId(String childRunId);

  SubrunStartedEventPayload botId(String botId);

  SubrunStartedEventPayload task(String task);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunStartedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  SubrunStartedEventPayload call({
    String childRunId,
    String botId,
    String task,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubrunStartedEventPayload.copyWith(...)` or call `instanceOfSubrunStartedEventPayload.copyWith.fieldName(value)` for a single field.
class _$SubrunStartedEventPayloadCWProxyImpl
    implements _$SubrunStartedEventPayloadCWProxy {
  const _$SubrunStartedEventPayloadCWProxyImpl(this._value);

  final SubrunStartedEventPayload _value;

  @override
  SubrunStartedEventPayload childRunId(String childRunId) =>
      call(childRunId: childRunId);

  @override
  SubrunStartedEventPayload botId(String botId) => call(botId: botId);

  @override
  SubrunStartedEventPayload task(String task) => call(task: task);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunStartedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubrunStartedEventPayload call({
    Object? childRunId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? task = const $CopyWithPlaceholder(),
  }) {
    return SubrunStartedEventPayload(
      childRunId:
          childRunId == const $CopyWithPlaceholder() || childRunId == null
          ? _value.childRunId
          // ignore: cast_nullable_to_non_nullable
          : childRunId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      task: task == const $CopyWithPlaceholder() || task == null
          ? _value.task
          // ignore: cast_nullable_to_non_nullable
          : task as String,
    );
  }
}

extension $SubrunStartedEventPayloadCopyWith on SubrunStartedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubrunStartedEventPayload.copyWith(...)` or `instanceOfSubrunStartedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubrunStartedEventPayloadCWProxy get copyWith =>
      _$SubrunStartedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubrunStartedEventPayload _$SubrunStartedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SubrunStartedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['child_run_id', 'bot_id', 'task']);
  final val = SubrunStartedEventPayload(
    childRunId: $checkedConvert('child_run_id', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String),
    task: $checkedConvert('task', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'childRunId': 'child_run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$SubrunStartedEventPayloadToJson(
  SubrunStartedEventPayload instance,
) => <String, dynamic>{
  'child_run_id': instance.childRunId,
  'bot_id': instance.botId,
  'task': instance.task,
};
