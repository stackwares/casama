// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_output_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolOutputEventPayloadCWProxy {
  ToolOutputEventPayload callId(String callId);

  ToolOutputEventPayload chunk(String chunk);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolOutputEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolOutputEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolOutputEventPayload call({String callId, String chunk});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolOutputEventPayload.copyWith(...)` or call `instanceOfToolOutputEventPayload.copyWith.fieldName(value)` for a single field.
class _$ToolOutputEventPayloadCWProxyImpl
    implements _$ToolOutputEventPayloadCWProxy {
  const _$ToolOutputEventPayloadCWProxyImpl(this._value);

  final ToolOutputEventPayload _value;

  @override
  ToolOutputEventPayload callId(String callId) => call(callId: callId);

  @override
  ToolOutputEventPayload chunk(String chunk) => call(chunk: chunk);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolOutputEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolOutputEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolOutputEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? chunk = const $CopyWithPlaceholder(),
  }) {
    return ToolOutputEventPayload(
      callId: callId == const $CopyWithPlaceholder() || callId == null
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      chunk: chunk == const $CopyWithPlaceholder() || chunk == null
          ? _value.chunk
          // ignore: cast_nullable_to_non_nullable
          : chunk as String,
    );
  }
}

extension $ToolOutputEventPayloadCopyWith on ToolOutputEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolOutputEventPayload.copyWith(...)` or `instanceOfToolOutputEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolOutputEventPayloadCWProxy get copyWith =>
      _$ToolOutputEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolOutputEventPayload _$ToolOutputEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ToolOutputEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['call_id', 'chunk']);
  final val = ToolOutputEventPayload(
    callId: $checkedConvert('call_id', (v) => v as String),
    chunk: $checkedConvert('chunk', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'callId': 'call_id'});

Map<String, dynamic> _$ToolOutputEventPayloadToJson(
  ToolOutputEventPayload instance,
) => <String, dynamic>{'call_id': instance.callId, 'chunk': instance.chunk};
