// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_completed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCompletedEventPayloadCWProxy {
  RunCompletedEventPayload finalMessageId(String? finalMessageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  RunCompletedEventPayload call({String? finalMessageId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunCompletedEventPayload.copyWith(...)` or call `instanceOfRunCompletedEventPayload.copyWith.fieldName(value)` for a single field.
class _$RunCompletedEventPayloadCWProxyImpl
    implements _$RunCompletedEventPayloadCWProxy {
  const _$RunCompletedEventPayloadCWProxyImpl(this._value);

  final RunCompletedEventPayload _value;

  @override
  RunCompletedEventPayload finalMessageId(String? finalMessageId) =>
      call(finalMessageId: finalMessageId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunCompletedEventPayload.copyWith(...)` or `instanceOfRunCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCompletedEventPayloadCWProxy get copyWith =>
      _$RunCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunCompletedEventPayload _$RunCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RunCompletedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['final_message_id']);
  final val = RunCompletedEventPayload(
    finalMessageId: $checkedConvert('final_message_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'finalMessageId': 'final_message_id'});

Map<String, dynamic> _$RunCompletedEventPayloadToJson(
  RunCompletedEventPayload instance,
) => <String, dynamic>{'final_message_id': instance.finalMessageId};
