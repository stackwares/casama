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





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceSessionRequest &&
      other.botId == botId &&
      other.conversationId == conversationId;

    @override
    int get hashCode =>
        botId.hashCode +
        conversationId.hashCode;

  factory VoiceSessionRequest.fromJson(Map<String, dynamic> json) => _$VoiceSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSessionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

