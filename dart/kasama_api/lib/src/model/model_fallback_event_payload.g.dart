// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_fallback_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ModelFallbackEventPayloadCWProxy {
  ModelFallbackEventPayload fromModel(String fromModel);

  ModelFallbackEventPayload reason(String reason);

  ModelFallbackEventPayload message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelFallbackEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelFallbackEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ModelFallbackEventPayload call({
    String fromModel,
    String reason,
    String message,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfModelFallbackEventPayload.copyWith(...)` or call `instanceOfModelFallbackEventPayload.copyWith.fieldName(value)` for a single field.
class _$ModelFallbackEventPayloadCWProxyImpl
    implements _$ModelFallbackEventPayloadCWProxy {
  const _$ModelFallbackEventPayloadCWProxyImpl(this._value);

  final ModelFallbackEventPayload _value;

  @override
  ModelFallbackEventPayload fromModel(String fromModel) =>
      call(fromModel: fromModel);

  @override
  ModelFallbackEventPayload reason(String reason) => call(reason: reason);

  @override
  ModelFallbackEventPayload message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ModelFallbackEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ModelFallbackEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ModelFallbackEventPayload call({
    Object? fromModel = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return ModelFallbackEventPayload(
      fromModel: fromModel == const $CopyWithPlaceholder() || fromModel == null
          ? _value.fromModel
          // ignore: cast_nullable_to_non_nullable
          : fromModel as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $ModelFallbackEventPayloadCopyWith on ModelFallbackEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfModelFallbackEventPayload.copyWith(...)` or `instanceOfModelFallbackEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ModelFallbackEventPayloadCWProxy get copyWith =>
      _$ModelFallbackEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelFallbackEventPayload _$ModelFallbackEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ModelFallbackEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['from_model', 'reason', 'message']);
  final val = ModelFallbackEventPayload(
    fromModel: $checkedConvert('from_model', (v) => v as String),
    reason: $checkedConvert('reason', (v) => v as String),
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'fromModel': 'from_model'});

Map<String, dynamic> _$ModelFallbackEventPayloadToJson(
  ModelFallbackEventPayload instance,
) => <String, dynamic>{
  'from_model': instance.fromModel,
  'reason': instance.reason,
  'message': instance.message,
};
