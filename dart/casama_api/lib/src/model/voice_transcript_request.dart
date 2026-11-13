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

    required  this.turns,

    required  this.seconds,

     this.provider,

     this.usage,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTranscriptRequest &&
      other.conversationId == conversationId &&
      other.turns == turns &&
      other.seconds == seconds &&
      other.provider == provider &&
      other.usage == usage;

    @override
    int get hashCode =>
        conversationId.hashCode +
        turns.hashCode +
        seconds.hashCode +
        provider.hashCode +
        usage.hashCode;

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


