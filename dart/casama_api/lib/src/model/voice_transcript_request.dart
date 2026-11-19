//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/voice_transcript_request_usage.dart';
import 'package:casama_api/src/model/voice_transcript_request_turns_inner.dart';
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

     this.liveCallId,

    required  this.turns,

    required  this.seconds,

     this.provider,

     this.usage,

     this.ended,
  });

  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



      /// The call (D-327): ends its server record. Turns already sent with /v1/voice/transcript/turns aren't sent again
  @JsonKey(
    
    name: r'live_call_id',
    required: false,
    includeIfNull: false,
  )


  final String? liveCallId;



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



      /// Which live-call provider the call used. Every call is Gemini Live now (D-260); openai is still accepted from older apps.
  @JsonKey(
    
    name: r'provider',
    required: false,
    includeIfNull: false,
  )


  final VoiceTranscriptRequestProviderEnum? provider;



  @JsonKey(
    
    name: r'usage',
    required: false,
    includeIfNull: false,
  )


  final VoiceTranscriptRequestUsage? usage;



      /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
  @JsonKey(
    
    name: r'ended',
    required: false,
    includeIfNull: false,
  )


  final VoiceTranscriptRequestEndedEnum? ended;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTranscriptRequest &&
      other.conversationId == conversationId &&
      other.liveCallId == liveCallId &&
      other.turns == turns &&
      other.seconds == seconds &&
      other.provider == provider &&
      other.usage == usage &&
      other.ended == ended;

    @override
    int get hashCode =>
        conversationId.hashCode +
        liveCallId.hashCode +
        turns.hashCode +
        seconds.hashCode +
        provider.hashCode +
        usage.hashCode +
        ended.hashCode;

  factory VoiceTranscriptRequest.fromJson(Map<String, dynamic> json) => _$VoiceTranscriptRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTranscriptRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Which live-call provider the call used. Every call is Gemini Live now (D-260); openai is still accepted from older apps.
enum VoiceTranscriptRequestProviderEnum {
    /// Which live-call provider the call used. Every call is Gemini Live now (D-260); openai is still accepted from older apps.
@JsonValue(r'gemini')
gemini(r'gemini'),
    /// Which live-call provider the call used. Every call is Gemini Live now (D-260); openai is still accepted from older apps.
@JsonValue(r'openai')
openai(r'openai');

const VoiceTranscriptRequestProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


/// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
enum VoiceTranscriptRequestEndedEnum {
    /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
@JsonValue(r'person')
person(r'person'),
    /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
@JsonValue(r'bot')
bot(r'bot'),
    /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
@JsonValue(r'dropped')
dropped(r'dropped'),
    /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
@JsonValue(r'idle')
idle(r'idle'),
    /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
@JsonValue(r'limit')
limit(r'limit'),
    /// How the call ended, for its card: the person hung up, the bot did (end_call), it dropped, it went quiet, a limit ended it, or another call took its place
@JsonValue(r'replaced')
replaced(r'replaced');

const VoiceTranscriptRequestEndedEnum(this.value);

final String value;

@override
String toString() => value;
}


