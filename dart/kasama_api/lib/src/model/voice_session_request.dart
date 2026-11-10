//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_session_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceSessionRequest {
  /// Returns a new [VoiceSessionRequest] instance.
  VoiceSessionRequest({

    required  this.botId,

     this.conversationId,

     this.callId,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'conversation_id',
    required: false,
    includeIfNull: false,
  )


  final String? conversationId;



      /// An answered phone call (D-135): the session uses its conversation and the bot speaks first
  @JsonKey(
    
    name: r'call_id',
    required: false,
    includeIfNull: false,
  )


  final String? callId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceSessionRequest &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.callId == callId;

    @override
    int get hashCode =>
        botId.hashCode +
        conversationId.hashCode +
        callId.hashCode;

  factory VoiceSessionRequest.fromJson(Map<String, dynamic> json) => _$VoiceSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSessionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

