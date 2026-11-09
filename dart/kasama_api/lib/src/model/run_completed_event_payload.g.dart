// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_completed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCompletedEventPayloadCWProxy {
  RunCompletedEventPayload finalMessageId(String? finalMessageId);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunCompletedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunCompletedEventPayload call({String? finalMessageId});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunCompletedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunCompletedEventPayload.copyWith.fieldName(...)`
class _$RunCompletedEventPayloadCWProxyImpl
    implements _$RunCompletedEventPayloadCWProxy {
  const _$RunCompletedEventPayloadCWProxyImpl(this._value);

  final RunCompletedEventPayload _value;

  @override
  RunCompletedEventPayload finalMessageId(String? finalMessageId) =>
      this(finalMessageId: finalMessageId);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunCompletedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  RunCompletedEventPayload call({
    Object? finalMessageId = const $CopyWithPlaceholder(),
  }) {
    return RunCompletedEventPayload(
      finalMessageId: finalMessageId == const $CopyWithPlaceholder()
          ? _value.finalMessageId
          // ignore: cast_nullable_to_non_nullable
          : finalMessageId as String?,
    );
  }
}

extension $RunCompletedEventPayloadCopyWith on RunCompletedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfRunCompletedEventPayload.copyWith(...)` or like so:`instanceOfRunCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCompletedEventPayloadCWProxy get copyWith =>
      _$RunCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunCompletedEventPayload _$RunCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'RunCompletedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['final_message_id']);
    final val = RunCompletedEventPayload(
      finalMessageId: $checkedConvert('final_message_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'finalMessageId': 'final_message_id'},
);

Map<String, dynamic> _$RunCompletedEventPayloadToJson(
  RunCompletedEventPayload instance,
) => <String, dynamic>{'final_message_id': instance.finalMessageId};
