// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_output_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolOutputEventPayloadCWProxy {
  ToolOutputEventPayload callId(String callId);

  ToolOutputEventPayload chunk(String chunk);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolOutputEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolOutputEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolOutputEventPayload call({String callId, String chunk});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfToolOutputEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfToolOutputEventPayload.copyWith.fieldName(...)`
class _$ToolOutputEventPayloadCWProxyImpl
    implements _$ToolOutputEventPayloadCWProxy {
  const _$ToolOutputEventPayloadCWProxyImpl(this._value);

  final ToolOutputEventPayload _value;

  @override
  ToolOutputEventPayload callId(String callId) => this(callId: callId);

  @override
  ToolOutputEventPayload chunk(String chunk) => this(chunk: chunk);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolOutputEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolOutputEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolOutputEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? chunk = const $CopyWithPlaceholder(),
  }) {
    return ToolOutputEventPayload(
      callId: callId == const $CopyWithPlaceholder()
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      chunk: chunk == const $CopyWithPlaceholder()
          ? _value.chunk
          // ignore: cast_nullable_to_non_nullable
          : chunk as String,
    );
  }
}

extension $ToolOutputEventPayloadCopyWith on ToolOutputEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfToolOutputEventPayload.copyWith(...)` or like so:`instanceOfToolOutputEventPayload.copyWith.fieldName(...)`.
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
