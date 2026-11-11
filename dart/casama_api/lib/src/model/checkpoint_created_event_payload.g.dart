// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_created_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckpointCreatedEventPayloadCWProxy {
  CheckpointCreatedEventPayload checkpointId(String checkpointId);

  CheckpointCreatedEventPayload label(String label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckpointCreatedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckpointCreatedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  CheckpointCreatedEventPayload call({String checkpointId, String label});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCheckpointCreatedEventPayload.copyWith(...)` or call `instanceOfCheckpointCreatedEventPayload.copyWith.fieldName(value)` for a single field.
class _$CheckpointCreatedEventPayloadCWProxyImpl
    implements _$CheckpointCreatedEventPayloadCWProxy {
  const _$CheckpointCreatedEventPayloadCWProxyImpl(this._value);

  final CheckpointCreatedEventPayload _value;

  @override
  CheckpointCreatedEventPayload checkpointId(String checkpointId) =>
      call(checkpointId: checkpointId);

  @override
  CheckpointCreatedEventPayload label(String label) => call(label: label);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckpointCreatedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckpointCreatedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CheckpointCreatedEventPayload call({
    Object? checkpointId = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return CheckpointCreatedEventPayload(
      checkpointId:
          checkpointId == const $CopyWithPlaceholder() || checkpointId == null
          ? _value.checkpointId
          // ignore: cast_nullable_to_non_nullable
          : checkpointId as String,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $CheckpointCreatedEventPayloadCopyWith
    on CheckpointCreatedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCheckpointCreatedEventPayload.copyWith(...)` or `instanceOfCheckpointCreatedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckpointCreatedEventPayloadCWProxy get copyWith =>
      _$CheckpointCreatedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointCreatedEventPayload _$CheckpointCreatedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CheckpointCreatedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['checkpoint_id', 'label']);
  final val = CheckpointCreatedEventPayload(
    checkpointId: $checkedConvert('checkpoint_id', (v) => v as String),
    label: $checkedConvert('label', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'checkpointId': 'checkpoint_id'});

Map<String, dynamic> _$CheckpointCreatedEventPayloadToJson(
  CheckpointCreatedEventPayload instance,
) => <String, dynamic>{
  'checkpoint_id': instance.checkpointId,
  'label': instance.label,
};
