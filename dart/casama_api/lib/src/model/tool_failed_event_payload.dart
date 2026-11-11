//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tool_failed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ToolFailedEventPayload {
  /// Returns a new [ToolFailedEventPayload] instance.
  ToolFailedEventPayload({

    required  this.callId,

    required  this.errorCode,

    required  this.message,
  });

  @JsonKey(
    
    name: r'call_id',
    required: true,
    includeIfNull: false,
  )


  final String callId;



  @JsonKey(
    
    name: r'error_code',
    required: true,
    includeIfNull: false,
  )


  final String errorCode;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ToolFailedEventPayload &&
      other.callId == callId &&
      other.errorCode == errorCode &&
      other.message == message;

    @override
    int get hashCode =>
        callId.hashCode +
        errorCode.hashCode +
        message.hashCode;

  factory ToolFailedEventPayload.fromJson(Map<String, dynamic> json) => _$ToolFailedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ToolFailedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

