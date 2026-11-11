// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_started_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunStartedEventPayloadCWProxy {
  RunStartedEventPayload trigger(String trigger);

  RunStartedEventPayload model(String model);

  RunStartedEventPayload computerId(String? computerId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunStartedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  RunStartedEventPayload call({
    String trigger,
    String model,
    String? computerId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunStartedEventPayload.copyWith(...)` or call `instanceOfRunStartedEventPayload.copyWith.fieldName(value)` for a single field.
class _$RunStartedEventPayloadCWProxyImpl
    implements _$RunStartedEventPayloadCWProxy {
  const _$RunStartedEventPayloadCWProxyImpl(this._value);

  final RunStartedEventPayload _value;

  @override
  RunStartedEventPayload trigger(String trigger) => call(trigger: trigger);

  @override
  RunStartedEventPayload model(String model) => call(model: model);

  @override
  RunStartedEventPayload computerId(String? computerId) =>
      call(computerId: computerId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunStartedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunStartedEventPayload call({
    Object? trigger = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
  }) {
    return RunStartedEventPayload(
      trigger: trigger == const $CopyWithPlaceholder() || trigger == null
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as String,
      model: model == const $CopyWithPlaceholder() || model == null
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String,
      computerId: computerId == const $CopyWithPlaceholder()
          ? _value.computerId
          // ignore: cast_nullable_to_non_nullable
          : computerId as String?,
    );
  }
}

extension $RunStartedEventPayloadCopyWith on RunStartedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunStartedEventPayload.copyWith(...)` or `instanceOfRunStartedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunStartedEventPayloadCWProxy get copyWith =>
      _$RunStartedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunStartedEventPayload _$RunStartedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RunStartedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['trigger', 'model', 'computer_id']);
  final val = RunStartedEventPayload(
    trigger: $checkedConvert('trigger', (v) => v as String),
    model: $checkedConvert('model', (v) => v as String),
    computerId: $checkedConvert('computer_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'computerId': 'computer_id'});

Map<String, dynamic> _$RunStartedEventPayloadToJson(
  RunStartedEventPayload instance,
) => <String, dynamic>{
  'trigger': instance.trigger,
  'model': instance.model,
  'computer_id': instance.computerId,
};
