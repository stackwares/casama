//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/voice_session_limits.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_session.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceSession {
  /// Returns a new [VoiceSession] instance.
  VoiceSession({

    required  this.provider,

    required  this.model,

    required  this.clientSecret,

    required  this.expiresAt,

    required  this.connectUrl,

    required  this.setup,

    required  this.conversationId,

    required  this.tools,

    required  this.speakFirst,

    required  this.liveCallId,

     this.limits,
  });

      /// Gemini Live over a WebSocket, the only live-call provider (D-260)
  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final VoiceSessionProviderEnum provider;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;



      /// Gemini's single-use token (the access_token query parameter)
  @JsonKey(
    
    name: r'client_secret',
    required: true,
    includeIfNull: false,
  )


  final String clientSecret;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



      /// Open a WebSocket here with ?access_token=<client_secret>
  @JsonKey(
    
    name: r'connect_url',
    required: true,
    includeIfNull: false,
  )


  final String connectUrl;



      /// Send {setup: <this>} as the first message (add sessionResumption to reconnect)
  @JsonKey(
    
    name: r'setup',
    required: true,
    includeIfNull: true,
  )


  final Map<String, Object?>? setup;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'tools',
    required: true,
    includeIfNull: false,
  )


  final int tools;



  @JsonKey(
    
    name: r'speak_first',
    required: true,
    includeIfNull: false,
  )


  final bool speakFirst;



      /// The server's record of this call (D-327): send turns, heartbeats and the final transcript with it
  @JsonKey(
    
    name: r'live_call_id',
    required: true,
    includeIfNull: false,
  )


  final String liveCallId;



  @JsonKey(
    
    name: r'limits',
    required: false,
    includeIfNull: false,
  )


  final VoiceSessionLimits? limits;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceSession &&
      other.provider == provider &&
      other.model == model &&
      other.clientSecret == clientSecret &&
      other.expiresAt == expiresAt &&
      other.connectUrl == connectUrl &&
      other.setup == setup &&
      other.conversationId == conversationId &&
      other.tools == tools &&
      other.speakFirst == speakFirst &&
      other.liveCallId == liveCallId &&
      other.limits == limits;

    @override
    int get hashCode =>
        provider.hashCode +
        model.hashCode +
        clientSecret.hashCode +
        expiresAt.hashCode +
        connectUrl.hashCode +
        (setup == null ? 0 : setup.hashCode) +
        conversationId.hashCode +
        tools.hashCode +
        speakFirst.hashCode +
        liveCallId.hashCode +
        limits.hashCode;

  factory VoiceSession.fromJson(Map<String, dynamic> json) => _$VoiceSessionFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Gemini Live over a WebSocket, the only live-call provider (D-260)
enum VoiceSessionProviderEnum {
    /// Gemini Live over a WebSocket, the only live-call provider (D-260)
@JsonValue(r'gemini')
gemini(r'gemini');

const VoiceSessionProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


