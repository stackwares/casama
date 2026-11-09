// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_started_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunStartedEventPayloadCWProxy {
  RunStartedEventPayload trigger(String trigger);

  RunStartedEventPayload model(String model);

  RunStartedEventPayload computerId(String? computerId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunStartedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunStartedEventPayload call({
    String trigger,
    String model,
    String? computerId,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunStartedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunStartedEventPayload.copyWith.fieldName(...)`
class _$RunStartedEventPayloadCWProxyImpl
    implements _$RunStartedEventPayloadCWProxy {
  const _$RunStartedEventPayloadCWProxyImpl(this._value);

  final RunStartedEventPayload _value;

  @override
  RunStartedEventPayload trigger(String trigger) => this(trigger: trigger);

  @override
  RunStartedEventPayload model(String model) => this(model: model);

  @override
  RunStartedEventPayload computerId(String? computerId) =>
      this(computerId: computerId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunStartedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunStartedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunStartedEventPayload call({
    Object? trigger = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? computerId = const $CopyWithPlaceholder(),
  }) {
    return RunStartedEventPayload(
      trigger: trigger == const $CopyWithPlaceholder()
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as String,
      model: model == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfRunStartedEventPayload.copyWith(...)` or like so:`instanceOfRunStartedEventPayload.copyWith.fieldName(...)`.
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
