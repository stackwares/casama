//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_tool_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceToolRequest {
  /// Returns a new [VoiceToolRequest] instance.
  VoiceToolRequest({

    required  this.botId,

    required  this.conversationId,

    required  this.callId,

    required  this.name,

     this.arguments,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'call_id',
    required: true,
    includeIfNull: false,
  )


  final String callId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'arguments',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? arguments;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceToolRequest &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.callId == callId &&
      other.name == name &&
      other.arguments == arguments;

    @override
    int get hashCode =>
        botId.hashCode +
        conversationId.hashCode +
        callId.hashCode +
        name.hashCode +
        arguments.hashCode;

  factory VoiceToolRequest.fromJson(Map<String, dynamic> json) => _$VoiceToolRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceToolRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

