// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_failed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunFailedEventPayloadCWProxy {
  RunFailedEventPayload errorCode(String errorCode);

  RunFailedEventPayload message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunFailedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  RunFailedEventPayload call({String errorCode, String message});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunFailedEventPayload.copyWith(...)` or call `instanceOfRunFailedEventPayload.copyWith.fieldName(value)` for a single field.
class _$RunFailedEventPayloadCWProxyImpl
    implements _$RunFailedEventPayloadCWProxy {
  const _$RunFailedEventPayloadCWProxyImpl(this._value);

  final RunFailedEventPayload _value;

  @override
  RunFailedEventPayload errorCode(String errorCode) =>
      call(errorCode: errorCode);

  @override
  RunFailedEventPayload message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunFailedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunFailedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunFailedEventPayload call({
    Object? errorCode = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return RunFailedEventPayload(
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

extension $RunFailedEventPayloadCopyWith on RunFailedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunFailedEventPayload.copyWith(...)` or `instanceOfRunFailedEventPayload.copyWith.fieldName(...)`.
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
