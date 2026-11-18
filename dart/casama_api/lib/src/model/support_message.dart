//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_message.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportMessage {
  /// Returns a new [SupportMessage] instance.
  SupportMessage({

    required  this.role,

    required  this.content,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final SupportMessageRoleEnum role;



  @JsonKey(
    
    name: r'content',
    required: true,
    includeIfNull: false,
  )


  final String content;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportMessage &&
      other.role == role &&
      other.content == content;

    @override
    int get hashCode =>
        role.hashCode +
        content.hashCode;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SupportMessageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SupportMessageRoleEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'assistant')
assistant(r'assistant');

const SupportMessageRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


