//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'outbound_call_transcript_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OutboundCallTranscriptInner {
  /// Returns a new [OutboundCallTranscriptInner] instance.
  OutboundCallTranscriptInner({

    required  this.role,

    required  this.text,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final OutboundCallTranscriptInnerRoleEnum role;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OutboundCallTranscriptInner &&
      other.role == role &&
      other.text == text;

    @override
    int get hashCode =>
        role.hashCode +
        text.hashCode;

  factory OutboundCallTranscriptInner.fromJson(Map<String, dynamic> json) => _$OutboundCallTranscriptInnerFromJson(json);

  Map<String, dynamic> toJson() => _$OutboundCallTranscriptInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum OutboundCallTranscriptInnerRoleEnum {
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'callee')
callee(r'callee');

const OutboundCallTranscriptInnerRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


