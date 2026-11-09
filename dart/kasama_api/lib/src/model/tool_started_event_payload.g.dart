// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_started_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolStartedEventPayloadCWProxy {
  ToolStartedEventPayload callId(String callId);

  ToolStartedEventPayload tool(String tool);

  ToolStartedEventPayload argsRedacted(Map<String, Object?> argsRedacted);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolStartedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolStartedEventPayload call({
    String callId,
    String tool,
    Map<String, Object?> argsRedacted,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfToolStartedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfToolStartedEventPayload.copyWith.fieldName(...)`
class _$ToolStartedEventPayloadCWProxyImpl
    implements _$ToolStartedEventPayloadCWProxy {
  const _$ToolStartedEventPayloadCWProxyImpl(this._value);

  final ToolStartedEventPayload _value;

  @override
  ToolStartedEventPayload callId(String callId) => this(callId: callId);

  @override
  ToolStartedEventPayload tool(String tool) => this(tool: tool);

  @override
  ToolStartedEventPayload argsRedacted(Map<String, Object?> argsRedacted) =>
      this(argsRedacted: argsRedacted);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolStartedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolStartedEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? tool = const $CopyWithPlaceholder(),
    Object? argsRedacted = const $CopyWithPlaceholder(),
  }) {
    return ToolStartedEventPayload(
      callId: callId == const $CopyWithPlaceholder()
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      tool: tool == const $CopyWithPlaceholder()
          ? _value.tool
          // ignore: cast_nullable_to_non_nullable
          : tool as String,
      argsRedacted: argsRedacted == const $CopyWithPlaceholder()
          ? _value.argsRedacted
          // ignore: cast_nullable_to_non_nullable
          : argsRedacted as Map<String, Object?>,
    );
  }
}

extension $ToolStartedEventPayloadCopyWith on ToolStartedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfToolStartedEventPayload.copyWith(...)` or like so:`instanceOfToolStartedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolStartedEventPayloadCWProxy get copyWith =>
      _$ToolStartedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolStartedEventPayload _$ToolStartedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ToolStartedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['call_id', 'tool', 'args_redacted']);
    final val = ToolStartedEventPayload(
      callId: $checkedConvert('call_id', (v) => v as String),
      tool: $checkedConvert('tool', (v) => v as String),
      argsRedacted: $checkedConvert(
        'args_redacted',
        (v) => v as Map<String, dynamic>,
      ),
    );
    return val;
  },
  fieldKeyMap: const {'callId': 'call_id', 'argsRedacted': 'args_redacted'},
);

Map<String, dynamic> _$ToolStartedEventPayloadToJson(
  ToolStartedEventPayload instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'tool': instance.tool,
  'args_redacted': instance.argsRedacted,
};
