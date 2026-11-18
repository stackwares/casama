// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_failed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolFailedEventPayloadCWProxy {
  ToolFailedEventPayload callId(String callId);

  ToolFailedEventPayload errorCode(String errorCode);

  ToolFailedEventPayload message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolFailedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolFailedEventPayload call({
    String callId,
    String errorCode,
    String message,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolFailedEventPayload.copyWith(...)` or call `instanceOfToolFailedEventPayload.copyWith.fieldName(value)` for a single field.
class _$ToolFailedEventPayloadCWProxyImpl
    implements _$ToolFailedEventPayloadCWProxy {
  const _$ToolFailedEventPayloadCWProxyImpl(this._value);

  final ToolFailedEventPayload _value;

  @override
  ToolFailedEventPayload callId(String callId) => call(callId: callId);

  @override
  ToolFailedEventPayload errorCode(String errorCode) =>
      call(errorCode: errorCode);

  @override
  ToolFailedEventPayload message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolFailedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolFailedEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return ToolFailedEventPayload(
      callId: callId == const $CopyWithPlaceholder() || callId == null
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      errorCode: errorCode == const $CopyWithPlaceholder() || errorCode == null
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $ToolFailedEventPayloadCopyWith on ToolFailedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolFailedEventPayload.copyWith(...)` or `instanceOfToolFailedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolFailedEventPayloadCWProxy get copyWith =>
      _$ToolFailedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolFailedEventPayload _$ToolFailedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ToolFailedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['call_id', 'error_code', 'message']);
  final val = ToolFailedEventPayload(
    callId: $checkedConvert('call_id', (v) => v as String),
    errorCode: $checkedConvert('error_code', (v) => v as String),
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'callId': 'call_id', 'errorCode': 'error_code'});

Map<String, dynamic> _$ToolFailedEventPayloadToJson(
  ToolFailedEventPayload instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'error_code': instance.errorCode,
  'message': instance.message,
};
