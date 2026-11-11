//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_output_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ToolOutputEventPayload {
  /// Returns a new [ToolOutputEventPayload] instance.
  ToolOutputEventPayload({

    required  this.callId,

    required  this.chunk,
  });

  @JsonKey(
    
    name: r'call_id',
    required: true,
    includeIfNull: false,
  )


  final String callId;



  @JsonKey(
    
    name: r'chunk',
    required: true,
    includeIfNull: false,
  )


  final String chunk;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ToolOutputEventPayload &&
      other.callId == callId &&
      other.chunk == chunk;

    @override
    int get hashCode =>
        callId.hashCode +
        chunk.hashCode;

  factory ToolOutputEventPayload.fromJson(Map<String, dynamic> json) => _$ToolOutputEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ToolOutputEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

