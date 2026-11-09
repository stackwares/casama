//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/voice_transcript_request_turns_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_transcript_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceTranscriptRequest {
  /// Returns a new [VoiceTranscriptRequest] instance.
  VoiceTranscriptRequest({

    required  this.conversationId,

    required  this.turns,

    required  this.seconds,
  });

  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'turns',
    required: true,
    includeIfNull: false,
  )


  final List<VoiceTranscriptRequestTurnsInner> turns;



          // minimum: 0
          // maximum: 86400
  @JsonKey(
    
    name: r'seconds',
    required: true,
    includeIfNull: false,
  )


  final int seconds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTranscriptRequest &&
      other.conversationId == conversationId &&
      other.turns == turns &&
      other.seconds == seconds;

    @override
    int get hashCode =>
        conversationId.hashCode +
        turns.hashCode +
        seconds.hashCode;

  factory VoiceTranscriptRequest.fromJson(Map<String, dynamic> json) => _$VoiceTranscriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTranscriptRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

