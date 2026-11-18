// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_started_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolStartedEventPayloadCWProxy {
  ToolStartedEventPayload callId(String callId);

  ToolStartedEventPayload tool(String tool);

  ToolStartedEventPayload argsRedacted(Map<String, Object?> argsRedacted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolStartedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolStartedEventPayload call({
    String callId,
    String tool,
    Map<String, Object?> argsRedacted,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolStartedEventPayload.copyWith(...)` or call `instanceOfToolStartedEventPayload.copyWith.fieldName(value)` for a single field.
class _$ToolStartedEventPayloadCWProxyImpl
    implements _$ToolStartedEventPayloadCWProxy {
  const _$ToolStartedEventPayloadCWProxyImpl(this._value);

  final ToolStartedEventPayload _value;

  @override
  ToolStartedEventPayload callId(String callId) => call(callId: callId);

  @override
  ToolStartedEventPayload tool(String tool) => call(tool: tool);

  @override
  ToolStartedEventPayload argsRedacted(Map<String, Object?> argsRedacted) =>
      call(argsRedacted: argsRedacted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolStartedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolStartedEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? tool = const $CopyWithPlaceholder(),
    Object? argsRedacted = const $CopyWithPlaceholder(),
  }) {
    return ToolStartedEventPayload(
      callId: callId == const $CopyWithPlaceholder() || callId == null
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      tool: tool == const $CopyWithPlaceholder() || tool == null
          ? _value.tool
          // ignore: cast_nullable_to_non_nullable
          : tool as String,
      argsRedacted:
          argsRedacted == const $CopyWithPlaceholder() || argsRedacted == null
          ? _value.argsRedacted
          // ignore: cast_nullable_to_non_nullable
          : argsRedacted as Map<String, Object?>,
    );
  }
}

extension $ToolStartedEventPayloadCopyWith on ToolStartedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolStartedEventPayload.copyWith(...)` or `instanceOfToolStartedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolStartedEventPayloadCWProxy get copyWith =>
      _$ToolStartedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolStartedEventPayload _$ToolStartedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ToolStartedEventPayload', json, ($checkedConvert) {
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
}, fieldKeyMap: const {'callId': 'call_id', 'argsRedacted': 'args_redacted'});

Map<String, dynamic> _$ToolStartedEventPayloadToJson(
  ToolStartedEventPayload instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'tool': instance.tool,
  'args_redacted': instance.argsRedacted,
};
