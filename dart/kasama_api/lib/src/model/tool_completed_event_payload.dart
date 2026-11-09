//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_completed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ToolCompletedEventPayload {
  /// Returns a new [ToolCompletedEventPayload] instance.
  ToolCompletedEventPayload({

    required  this.callId,

    required  this.resultPreview,

    required  this.artifactPath,

    required  this.durationMs,
  });

  @JsonKey(
    
    name: r'call_id',
    required: true,
    includeIfNull: false,
  )


  final String callId;



  @JsonKey(
    
    name: r'result_preview',
    required: true,
    includeIfNull: false,
  )


  final String resultPreview;



  @JsonKey(
    
    name: r'artifact_path',
    required: true,
    includeIfNull: true,
  )


  final String? artifactPath;



          // minimum: 0
  @JsonKey(
    
    name: r'duration_ms',
    required: true,
    includeIfNull: false,
  )


  final int durationMs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ToolCompletedEventPayload &&
      other.callId == callId &&
      other.resultPreview == resultPreview &&
      other.artifactPath == artifactPath &&
      other.durationMs == durationMs;

    @override
    int get hashCode =>
        callId.hashCode +
        resultPreview.hashCode +
        (artifactPath == null ? 0 : artifactPath.hashCode) +
        durationMs.hashCode;

  factory ToolCompletedEventPayload.fromJson(Map<String, dynamic> json) => _$ToolCompletedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ToolCompletedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

