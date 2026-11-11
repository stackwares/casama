// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_shown_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UiShownEventPayloadCWProxy {
  UiShownEventPayload surfaceId(String surfaceId);

  UiShownEventPayload messages(List<Map<String, Object?>> messages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UiShownEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UiShownEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  UiShownEventPayload call({
    String surfaceId,
    List<Map<String, Object?>> messages,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUiShownEventPayload.copyWith(...)` or call `instanceOfUiShownEventPayload.copyWith.fieldName(value)` for a single field.
class _$UiShownEventPayloadCWProxyImpl implements _$UiShownEventPayloadCWProxy {
  const _$UiShownEventPayloadCWProxyImpl(this._value);

  final UiShownEventPayload _value;

  @override
  UiShownEventPayload surfaceId(String surfaceId) => call(surfaceId: surfaceId);

  @override
  UiShownEventPayload messages(List<Map<String, Object?>> messages) =>
      call(messages: messages);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UiShownEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UiShownEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UiShownEventPayload call({
    Object? surfaceId = const $CopyWithPlaceholder(),
    Object? messages = const $CopyWithPlaceholder(),
  }) {
    return UiShownEventPayload(
      surfaceId: surfaceId == const $CopyWithPlaceholder() || surfaceId == null
          ? _value.surfaceId
          // ignore: cast_nullable_to_non_nullable
          : surfaceId as String,
      messages: messages == const $CopyWithPlaceholder() || messages == null
          ? _value.messages
          // ignore: cast_nullable_to_non_nullable
          : messages as List<Map<String, Object?>>,
    );
  }
}

extension $UiShownEventPayloadCopyWith on UiShownEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUiShownEventPayload.copyWith(...)` or `instanceOfUiShownEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UiShownEventPayloadCWProxy get copyWith =>
      _$UiShownEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UiShownEventPayload _$UiShownEventPayloadFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UiShownEventPayload', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['surface_id', 'messages']);
      final val = UiShownEventPayload(
        surfaceId: $checkedConvert('surface_id', (v) => v as String),
        messages: $checkedConvert(
          'messages',
          (v) => (v as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'surfaceId': 'surface_id'});

Map<String, dynamic> _$UiShownEventPayloadToJson(
  UiShownEventPayload instance,
) => <String, dynamic>{
  'surface_id': instance.surfaceId,
  'messages': instance.messages,
};
