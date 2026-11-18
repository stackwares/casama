//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_chat_request_messages_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebChatRequestMessagesInner {
  /// Returns a new [SupportWebChatRequestMessagesInner] instance.
  SupportWebChatRequestMessagesInner({

    required  this.role,

    required  this.content,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final SupportWebChatRequestMessagesInnerRoleEnum role;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebChatRequestMessagesInner &&
      other.role == role &&
      other.content == content;

    @override
    int get hashCode =>
        role.hashCode +
        content.hashCode;

  factory SupportWebChatRequestMessagesInner.fromJson(Map<String, dynamic> json) => _$SupportWebChatRequestMessagesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebChatRequestMessagesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SupportWebChatRequestMessagesInnerRoleEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'assistant')
assistant(r'assistant');

const SupportWebChatRequestMessagesInnerRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


