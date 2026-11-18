//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_started_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ToolStartedEventPayload {
  /// Returns a new [ToolStartedEventPayload] instance.
  ToolStartedEventPayload({

    required  this.callId,

    required  this.tool,

    required  this.argsRedacted,
  });

  @JsonKey(
    
    name: r'call_id',
    required: true,
    includeIfNull: false,
  )


  final String callId;



  @JsonKey(
    
    name: r'tool',
    required: true,
    includeIfNull: false,
  )


  final String tool;



  @JsonKey(
    
    name: r'args_redacted',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> argsRedacted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ToolStartedEventPayload &&
      other.callId == callId &&
      other.tool == tool &&
      other.argsRedacted == argsRedacted;

    @override
    int get hashCode =>
        callId.hashCode +
        tool.hashCode +
        argsRedacted.hashCode;

  factory ToolStartedEventPayload.fromJson(Map<String, dynamic> json) => _$ToolStartedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ToolStartedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

