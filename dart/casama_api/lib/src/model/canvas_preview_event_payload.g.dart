// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_preview_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CanvasPreviewEventPayloadCWProxy {
  CanvasPreviewEventPayload canvasId(String canvasId);

  CanvasPreviewEventPayload botId(String botId);

  CanvasPreviewEventPayload state(CanvasPreviewEventPayloadStateEnum state);

  CanvasPreviewEventPayload canvas(Canvas canvas);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasPreviewEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasPreviewEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  CanvasPreviewEventPayload call({
    String canvasId,
    String botId,
    CanvasPreviewEventPayloadStateEnum state,
    Canvas canvas,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCanvasPreviewEventPayload.copyWith(...)` or call `instanceOfCanvasPreviewEventPayload.copyWith.fieldName(value)` for a single field.
class _$CanvasPreviewEventPayloadCWProxyImpl
    implements _$CanvasPreviewEventPayloadCWProxy {
  const _$CanvasPreviewEventPayloadCWProxyImpl(this._value);

  final CanvasPreviewEventPayload _value;

  @override
  CanvasPreviewEventPayload canvasId(String canvasId) =>
      call(canvasId: canvasId);

  @override
  CanvasPreviewEventPayload botId(String botId) => call(botId: botId);

  @override
  CanvasPreviewEventPayload state(CanvasPreviewEventPayloadStateEnum state) =>
      call(state: state);

  @override
  CanvasPreviewEventPayload canvas(Canvas canvas) => call(canvas: canvas);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CanvasPreviewEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CanvasPreviewEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CanvasPreviewEventPayload call({
    Object? canvasId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? canvas = const $CopyWithPlaceholder(),
  }) {
    return CanvasPreviewEventPayload(
      canvasId: canvasId == const $CopyWithPlaceholder() || canvasId == null
          ? _value.canvasId
          // ignore: cast_nullable_to_non_nullable
          : canvasId as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as CanvasPreviewEventPayloadStateEnum,
      canvas: canvas == const $CopyWithPlaceholder() || canvas == null
          ? _value.canvas
          // ignore: cast_nullable_to_non_nullable
          : canvas as Canvas,
    );
  }
}

extension $CanvasPreviewEventPayloadCopyWith on CanvasPreviewEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCanvasPreviewEventPayload.copyWith(...)` or `instanceOfCanvasPreviewEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CanvasPreviewEventPayloadCWProxy get copyWith =>
      _$CanvasPreviewEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasPreviewEventPayload _$CanvasPreviewEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CanvasPreviewEventPayload', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['canvas_id', 'bot_id', 'state', 'canvas'],
  );
  final val = CanvasPreviewEventPayload(
    canvasId: $checkedConvert('canvas_id', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String),
    state: $checkedConvert(
      'state',
      (v) => $enumDecode(_$CanvasPreviewEventPayloadStateEnumEnumMap, v),
    ),
    canvas: $checkedConvert(
      'canvas',
      (v) => Canvas.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'canvasId': 'canvas_id', 'botId': 'bot_id'});

Map<String, dynamic> _$CanvasPreviewEventPayloadToJson(
  CanvasPreviewEventPayload instance,
) => <String, dynamic>{
  'canvas_id': instance.canvasId,
  'bot_id': instance.botId,
  'state': _$CanvasPreviewEventPayloadStateEnumEnumMap[instance.state]!,
  'canvas': instance.canvas.toJson(),
};

const _$CanvasPreviewEventPayloadStateEnumEnumMap = {
  CanvasPreviewEventPayloadStateEnum.waiting: 'waiting',
  CanvasPreviewEventPayloadStateEnum.shown: 'shown',
  CanvasPreviewEventPayloadStateEnum.notPlaced: 'not_placed',
};
