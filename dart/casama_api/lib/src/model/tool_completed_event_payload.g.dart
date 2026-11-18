// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_completed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolCompletedEventPayloadCWProxy {
  ToolCompletedEventPayload callId(String callId);

  ToolCompletedEventPayload resultPreview(String resultPreview);

  ToolCompletedEventPayload artifactPath(String? artifactPath);

  ToolCompletedEventPayload durationMs(int durationMs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolCompletedEventPayload call({
    String callId,
    String resultPreview,
    String? artifactPath,
    int durationMs,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolCompletedEventPayload.copyWith(...)` or call `instanceOfToolCompletedEventPayload.copyWith.fieldName(value)` for a single field.
class _$ToolCompletedEventPayloadCWProxyImpl
    implements _$ToolCompletedEventPayloadCWProxy {
  const _$ToolCompletedEventPayloadCWProxyImpl(this._value);

  final ToolCompletedEventPayload _value;

  @override
  ToolCompletedEventPayload callId(String callId) => call(callId: callId);

  @override
  ToolCompletedEventPayload resultPreview(String resultPreview) =>
      call(resultPreview: resultPreview);

  @override
  ToolCompletedEventPayload artifactPath(String? artifactPath) =>
      call(artifactPath: artifactPath);

  @override
  ToolCompletedEventPayload durationMs(int durationMs) =>
      call(durationMs: durationMs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolCompletedEventPayload call({
    Object? callId = const $CopyWithPlaceholder(),
    Object? resultPreview = const $CopyWithPlaceholder(),
    Object? artifactPath = const $CopyWithPlaceholder(),
    Object? durationMs = const $CopyWithPlaceholder(),
  }) {
    return ToolCompletedEventPayload(
      callId: callId == const $CopyWithPlaceholder() || callId == null
          ? _value.callId
          // ignore: cast_nullable_to_non_nullable
          : callId as String,
      resultPreview:
          resultPreview == const $CopyWithPlaceholder() || resultPreview == null
          ? _value.resultPreview
          // ignore: cast_nullable_to_non_nullable
          : resultPreview as String,
      artifactPath: artifactPath == const $CopyWithPlaceholder()
          ? _value.artifactPath
          // ignore: cast_nullable_to_non_nullable
          : artifactPath as String?,
      durationMs:
          durationMs == const $CopyWithPlaceholder() || durationMs == null
          ? _value.durationMs
          // ignore: cast_nullable_to_non_nullable
          : durationMs as int,
    );
  }
}

extension $ToolCompletedEventPayloadCopyWith on ToolCompletedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolCompletedEventPayload.copyWith(...)` or `instanceOfToolCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolCompletedEventPayloadCWProxy get copyWith =>
      _$ToolCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCompletedEventPayload _$ToolCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ToolCompletedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'call_id',
        'result_preview',
        'artifact_path',
        'duration_ms',
      ],
    );
    final val = ToolCompletedEventPayload(
      callId: $checkedConvert('call_id', (v) => v as String),
      resultPreview: $checkedConvert('result_preview', (v) => v as String),
      artifactPath: $checkedConvert('artifact_path', (v) => v as String?),
      durationMs: $checkedConvert('duration_ms', (v) => (v as num).toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'callId': 'call_id',
    'resultPreview': 'result_preview',
    'artifactPath': 'artifact_path',
    'durationMs': 'duration_ms',
  },
);

Map<String, dynamic> _$ToolCompletedEventPayloadToJson(
  ToolCompletedEventPayload instance,
) => <String, dynamic>{
  'call_id': instance.callId,
  'result_preview': instance.resultPreview,
  'artifact_path': instance.artifactPath,
  'duration_ms': instance.durationMs,
};
