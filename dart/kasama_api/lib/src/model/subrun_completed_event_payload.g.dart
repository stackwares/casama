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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubrunCompletedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubrunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  SubrunCompletedEventPayload call({
    String childRunId,
    SubrunCompletedEventPayloadStatusEnum status,
    String summary,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubrunCompletedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubrunCompletedEventPayload.copyWith.fieldName(...)`
class _$SubrunCompletedEventPayloadCWProxyImpl
    implements _$SubrunCompletedEventPayloadCWProxy {
  const _$SubrunCompletedEventPayloadCWProxyImpl(this._value);

  final SubrunCompletedEventPayload _value;

  @override
  SubrunCompletedEventPayload childRunId(String childRunId) =>
      this(childRunId: childRunId);

  @override
  SubrunCompletedEventPayload status(
    SubrunCompletedEventPayloadStatusEnum status,
  ) => this(status: status);

  @override
  SubrunCompletedEventPayload summary(String summary) => this(summary: summary);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubrunCompletedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubrunCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  SubrunCompletedEventPayload call({
    Object? childRunId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
  }) {
    return SubrunCompletedEventPayload(
      childRunId: childRunId == const $CopyWithPlaceholder()
          ? _value.childRunId
          // ignore: cast_nullable_to_non_nullable
          : childRunId as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as SubrunCompletedEventPayloadStatusEnum,
      summary: summary == const $CopyWithPlaceholder()
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
    );
  }
}

extension $SubrunCompletedEventPayloadCopyWith on SubrunCompletedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfSubrunCompletedEventPayload.copyWith(...)` or like so:`instanceOfSubrunCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubrunCompletedEventPayloadCWProxy get copyWith =>
      _$SubrunCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubrunCompletedEventPayload _$SubrunCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'SubrunCompletedEventPayload',
  json,
  ($checkedConvert) {
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
  },
  fieldKeyMap: const {'childRunId': 'child_run_id'},
);

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
