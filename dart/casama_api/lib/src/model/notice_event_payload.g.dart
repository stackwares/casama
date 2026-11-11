// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$NoticeEventPayloadCWProxy {
  NoticeEventPayload code(String code);

  NoticeEventPayload message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NoticeEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NoticeEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  NoticeEventPayload call({String code, String message});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfNoticeEventPayload.copyWith(...)` or call `instanceOfNoticeEventPayload.copyWith.fieldName(value)` for a single field.
class _$NoticeEventPayloadCWProxyImpl implements _$NoticeEventPayloadCWProxy {
  const _$NoticeEventPayloadCWProxyImpl(this._value);

  final NoticeEventPayload _value;

  @override
  NoticeEventPayload code(String code) => call(code: code);

  @override
  NoticeEventPayload message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `NoticeEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// NoticeEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  NoticeEventPayload call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return NoticeEventPayload(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $NoticeEventPayloadCopyWith on NoticeEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfNoticeEventPayload.copyWith(...)` or `instanceOfNoticeEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$NoticeEventPayloadCWProxy get copyWith =>
      _$NoticeEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoticeEventPayload _$NoticeEventPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NoticeEventPayload', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'message']);
      final val = NoticeEventPayload(
        code: $checkedConvert('code', (v) => v as String),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$NoticeEventPayloadToJson(NoticeEventPayload instance) =>
    <String, dynamic>{'code': instance.code, 'message': instance.message};
