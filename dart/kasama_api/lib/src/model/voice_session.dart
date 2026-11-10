//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
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

    required  this.conversationId,

    required  this.tools,

    required  this.speakFirst,
  });

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



      /// Ephemeral key, valid for about 10 minutes
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



      /// POST the WebRTC offer SDP here with the ephemeral key
  @JsonKey(
    
    name: r'connect_url',
    required: true,
    includeIfNull: false,
  )


  final String connectUrl;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceSession &&
      other.provider == provider &&
      other.model == model &&
      other.clientSecret == clientSecret &&
      other.expiresAt == expiresAt &&
      other.connectUrl == connectUrl &&
      other.conversationId == conversationId &&
      other.tools == tools &&
      other.speakFirst == speakFirst;

    @override
    int get hashCode =>
        provider.hashCode +
        model.hashCode +
        clientSecret.hashCode +
        expiresAt.hashCode +
        connectUrl.hashCode +
        conversationId.hashCode +
        tools.hashCode +
        speakFirst.hashCode;

  factory VoiceSession.fromJson(Map<String, dynamic> json) => _$VoiceSessionFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum VoiceSessionProviderEnum {
@JsonValue(r'openai')
openai(r'openai');

const VoiceSessionProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


