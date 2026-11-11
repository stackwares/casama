// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subrun_completed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubrunCompletedEventPayloadCWProxy {
  SubrunCompletedEventPayload childRunId(String childRunId);

  SubrunCompletedEventPayload status(
    SubrunCompletedEventPayloadStatusEnum status,
  );

  SubrunCompletedEventPayload summary(String summary);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  SubrunCompletedEventPayload call({
    String childRunId,
    SubrunCompletedEventPayloadStatusEnum status,
    String summary,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubrunCompletedEventPayload.copyWith(...)` or call `instanceOfSubrunCompletedEventPayload.copyWith.fieldName(value)` for a single field.
class _$SubrunCompletedEventPayloadCWProxyImpl
    implements _$SubrunCompletedEventPayloadCWProxy {
  const _$SubrunCompletedEventPayloadCWProxyImpl(this._value);

  final SubrunCompletedEventPayload _value;

  @override
  SubrunCompletedEventPayload childRunId(String childRunId) =>
      call(childRunId: childRunId);

  @override
  SubrunCompletedEventPayload status(
    SubrunCompletedEventPayloadStatusEnum status,
  ) => call(status: status);

  @override
  SubrunCompletedEventPayload summary(String summary) => call(summary: summary);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubrunCompletedEventPayload call({
    Object? childRunId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
  }) {
    return SubrunCompletedEventPayload(
      childRunId:
          childRunId == const $CopyWithPlaceholder() || childRunId == null
          ? _value.childRunId
          // ignore: cast_nullable_to_non_nullable
          : childRunId as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SubrunCompletedEventPayloadStatusEnum,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
    );
  }
}

extension $SubrunCompletedEventPayloadCopyWith on SubrunCompletedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubrunCompletedEventPayload.copyWith(...)` or `instanceOfSubrunCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubrunCompletedEventPayloadCWProxy get copyWith =>
      _$SubrunCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubrunCompletedEventPayload _$SubrunCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SubrunCompletedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['child_run_id', 'status', 'summary']);
  final val = SubrunCompletedEventPayload(
    childRunId: $checkedConvert('child_run_id', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$SubrunCompletedEventPayloadStatusEnumEnumMap, v),
    ),
    summary: $checkedConvert('summary', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'childRunId': 'child_run_id'});

Map<String, dynamic> _$SubrunCompletedEventPayloadToJson(
  SubrunCompletedEventPayload instance,
) => <String, dynamic>{
  'child_run_id': instance.childRunId,
  'status': _$SubrunCompletedEventPayloadStatusEnumEnumMap[instance.status]!,
  'summary': instance.summary,
};

const _$SubrunCompletedEventPayloadStatusEnumEnumMap = {
  SubrunCompletedEventPayloadStatusEnum.completed: 'completed',
  SubrunCompletedEventPayloadStatusEnum.failed: 'failed',
  SubrunCompletedEventPayloadStatusEnum.cancelled: 'cancelled',
};
