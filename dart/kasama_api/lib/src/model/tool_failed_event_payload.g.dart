// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_failed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolFailedEventPayloadCWProxy {
  ToolFailedEventPayload callId(String callId);

  ToolFailedEventPayload errorCode(String errorCode);

  ToolFailedEventPayload message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolFailedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolFailedEventPayload call({
    String callId,
    String errorCode,
    String message,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfToolFailedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfToolFailedEventPayload.copyWith.fieldName(...)`
class _$ToolFailedEventPayloadCWProxyImpl
    implements _$ToolFailedEventPayloadCWProxy {
  const _$ToolFailedEventPayloadCWProxyImpl(this._value);

  final ToolFailedEventPayload _value;

  @override
  ToolFailedEventPayload callId(String callId) => this(callId: callId);

  @override
  ToolFailedEventPayload errorCode(String errorCode) =>
      this(errorCode: errorCode);

  @override
  ToolFailedEventPayload message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolFailedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolFailedEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return ToolFailedEventPayload(
      callId: callId == const $CopyWithPlaceholder()
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      errorCode: errorCode == const $CopyWithPlaceholder()
          ? _value.errorCode
          // ignore: cast_nullable_to_non_nullable
          : errorCode as String,
      message: message == const $CopyWithPlaceholder()
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $ToolFailedEventPayloadCopyWith on ToolFailedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfToolFailedEventPayload.copyWith(...)` or like so:`instanceOfToolFailedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolFailedEventPayloadCWProxy get copyWith =>
      _$ToolFailedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolFailedEventPayload _$ToolFailedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ToolFailedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['call_id', 'error_code', 'message']);
    final val = ToolFailedEventPayload(
      callId: $checkedConvert('call_id', (v) => v as String),
      errorCode: $checkedConvert('error_code', (v) => v as String),
      message: $checkedConvert('message', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'callId': 'call_id', 'errorCode': 'error_code'},
);

Map<String, dynamic> _$ToolFailedEventPayloadToJson(
  ToolFailedEventPayload instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'error_code': instance.errorCode,
  'message': instance.message,
};
