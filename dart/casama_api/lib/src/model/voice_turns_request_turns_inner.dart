//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_turns_request_turns_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceTurnsRequestTurnsInner {
  /// Returns a new [VoiceTurnsRequestTurnsInner] instance.
  VoiceTurnsRequestTurnsInner({

    required  this.id,

    required  this.role,

    required  this.text,
  });

      /// The app's id for the turn; a turn sent twice with the same id is saved once
  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final VoiceTurnsRequestTurnsInnerRoleEnum role;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTurnsRequestTurnsInner &&
      other.id == id &&
      other.role == role &&
      other.text == text;

    @override
    int get hashCode =>
        id.hashCode +
        role.hashCode +
        text.hashCode;

  factory VoiceTurnsRequestTurnsInner.fromJson(Map<String, dynamic> json) => _$VoiceTurnsRequestTurnsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTurnsRequestTurnsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum VoiceTurnsRequestTurnsInnerRoleEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'assistant')
assistant(r'assistant');

const VoiceTurnsRequestTurnsInnerRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


