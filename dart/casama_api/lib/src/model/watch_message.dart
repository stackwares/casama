//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_attachment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_message.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchMessage {
  /// Returns a new [WatchMessage] instance.
  WatchMessage({

    required  this.id,

    required  this.role,

    required  this.text,

    required  this.cut,

    required  this.attachments,

    required  this.at,

    required  this.canSpeak,
  });

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


  final WatchMessageRoleEnum role;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'cut',
    required: true,
    includeIfNull: false,
  )


  final bool cut;



  @JsonKey(
    
    name: r'attachments',
    required: true,
    includeIfNull: false,
  )


  final List<WatchAttachment> attachments;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;



  @JsonKey(
    
    name: r'can_speak',
    required: true,
    includeIfNull: false,
  )


  final bool canSpeak;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchMessage &&
      other.id == id &&
      other.role == role &&
      other.text == text &&
      other.cut == cut &&
      other.attachments == attachments &&
      other.at == at &&
      other.canSpeak == canSpeak;

    @override
    int get hashCode =>
        id.hashCode +
        role.hashCode +
        text.hashCode +
        cut.hashCode +
        attachments.hashCode +
        at.hashCode +
        canSpeak.hashCode;

  factory WatchMessage.fromJson(Map<String, dynamic> json) => _$WatchMessageFromJson(json);

  Map<String, dynamic> toJson() => _$WatchMessageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WatchMessageRoleEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'assistant')
assistant(r'assistant');

const WatchMessageRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


