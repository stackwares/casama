// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_created_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckpointCreatedEventPayloadCWProxy {
  CheckpointCreatedEventPayload checkpointId(String checkpointId);

  CheckpointCreatedEventPayload label(String label);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckpointCreatedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckpointCreatedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckpointCreatedEventPayload call({String checkpointId, String label});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCheckpointCreatedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCheckpointCreatedEventPayload.copyWith.fieldName(...)`
class _$CheckpointCreatedEventPayloadCWProxyImpl
    implements _$CheckpointCreatedEventPayloadCWProxy {
  const _$CheckpointCreatedEventPayloadCWProxyImpl(this._value);

  final CheckpointCreatedEventPayload _value;

  @override
  CheckpointCreatedEventPayload checkpointId(String checkpointId) =>
      this(checkpointId: checkpointId);

  @override
  CheckpointCreatedEventPayload label(String label) => this(label: label);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckpointCreatedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckpointCreatedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckpointCreatedEventPayload call({
    Object? checkpointId = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
  }) {
    return CheckpointCreatedEventPayload(
      checkpointId: checkpointId == const $CopyWithPlaceholder()
          ? _value.checkpointId
          // ignore: cast_nullable_to_non_nullable
          : checkpointId as String,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
    );
  }
}

extension $CheckpointCreatedEventPayloadCopyWith
    on CheckpointCreatedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfCheckpointCreatedEventPayload.copyWith(...)` or like so:`instanceOfCheckpointCreatedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckpointCreatedEventPayloadCWProxy get copyWith =>
      _$CheckpointCreatedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointCreatedEventPayload _$CheckpointCreatedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CheckpointCreatedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['checkpoint_id', 'label']);
    final val = CheckpointCreatedEventPayload(
      checkpointId: $checkedConvert('checkpoint_id', (v) => v as String),
      label: $checkedConvert('label', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'checkpointId': 'checkpoint_id'},
);

Map<String, dynamic> _$CheckpointCreatedEventPayloadToJson(
  CheckpointCreatedEventPayload instance,
) => <String, dynamic>{
  'checkpoint_id': instance.checkpointId,
  'label': instance.label,
};
