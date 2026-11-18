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

     this.id,
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



      /// The app's id for the turn; a turn sent twice with the same id is saved once
  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false,
  )


  final String? id;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTranscriptRequestTurnsInner &&
      other.role == role &&
      other.text == text &&
      other.id == id;

    @override
    int get hashCode =>
        role.hashCode +
        text.hashCode +
        id.hashCode;

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


