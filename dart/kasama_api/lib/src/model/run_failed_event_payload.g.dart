// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_failed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunFailedEventPayloadCWProxy {
  RunFailedEventPayload errorCode(String errorCode);

  RunFailedEventPayload message(String message);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunFailedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunFailedEventPayload call({String errorCode, String message});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunFailedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunFailedEventPayload.copyWith.fieldName(...)`
class _$RunFailedEventPayloadCWProxyImpl
    implements _$RunFailedEventPayloadCWProxy {
  const _$RunFailedEventPayloadCWProxyImpl(this._value);

  final RunFailedEventPayload _value;

  @override
  RunFailedEventPayload errorCode(String errorCode) =>
      this(errorCode: errorCode);

  @override
  RunFailedEventPayload message(String message) => this(message: message);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunFailedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunFailedEventPayload call({
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return RunFailedEventPayload(
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

extension $RunFailedEventPayloadCopyWith on RunFailedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfRunFailedEventPayload.copyWith(...)` or like so:`instanceOfRunFailedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunFailedEventPayloadCWProxy get copyWith =>
      _$RunFailedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunFailedEventPayload _$RunFailedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RunFailedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['error_code', 'message']);
  final val = RunFailedEventPayload(
    errorCode: $checkedConvert('error_code', (v) => v as String),
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'errorCode': 'error_code'});

Map<String, dynamic> _$RunFailedEventPayloadToJson(
  RunFailedEventPayload instance,
) => <String, dynamic>{
  'error_code': instance.errorCode,
  'message': instance.message,
};
