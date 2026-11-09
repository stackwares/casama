//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_transcript_request_turns_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceTranscriptRequestTurnsInner {
  /// Returns a new [VoiceTranscriptRequestTurnsInner] instance.
  VoiceTranscriptRequestTurnsInner({

    required  this.role,

    required  this.text,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final VoiceTranscriptRequestTurnsInnerRoleEnum role;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTranscriptRequestTurnsInner &&
      other.role == role &&
      other.text == text;

    @override
    int get hashCode =>
        role.hashCode +
        text.hashCode;

  factory VoiceTranscriptRequestTurnsInner.fromJson(Map<String, dynamic> json) => _$VoiceTranscriptRequestTurnsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTranscriptRequestTurnsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum VoiceTranscriptRequestTurnsInnerRoleEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'assistant')
assistant(r'assistant');

const VoiceTranscriptRequestTurnsInnerRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


