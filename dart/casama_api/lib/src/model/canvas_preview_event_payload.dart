//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/canvas.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_preview_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasPreviewEventPayload {
  /// Returns a new [CanvasPreviewEventPayload] instance.
  CanvasPreviewEventPayload({

    required  this.canvasId,

    required  this.botId,

    required  this.state,

    required  this.canvas,
  });

  @JsonKey(
    
    name: r'canvas_id',
    required: true,
    includeIfNull: false,
  )


  final String canvasId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final CanvasPreviewEventPayloadStateEnum state;



  @JsonKey(
    
    name: r'canvas',
    required: true,
    includeIfNull: false,
  )


  final Canvas canvas;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasPreviewEventPayload &&
      other.canvasId == canvasId &&
      other.botId == botId &&
      other.state == state &&
      other.canvas == canvas;

    @override
    int get hashCode =>
        canvasId.hashCode +
        botId.hashCode +
        state.hashCode +
        canvas.hashCode;

  factory CanvasPreviewEventPayload.fromJson(Map<String, dynamic> json) => _$CanvasPreviewEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasPreviewEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasPreviewEventPayloadStateEnum {
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'shown')
shown(r'shown'),
@JsonValue(r'not_placed')
notPlaced(r'not_placed');

const CanvasPreviewEventPayloadStateEnum(this.value);

final String value;

@override
String toString() => value;
}


