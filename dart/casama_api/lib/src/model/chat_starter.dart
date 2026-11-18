//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_starter.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChatStarter {
  /// Returns a new [ChatStarter] instance.
  ChatStarter({

    required  this.emoji,

    required  this.text,
  });

      /// Decoration only; tapping sends the text.
  @JsonKey(
    
    name: r'emoji',
    required: true,
    includeIfNull: false,
  )


  final String emoji;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChatStarter &&
      other.emoji == emoji &&
      other.text == text;

    @override
    int get hashCode =>
        emoji.hashCode +
        text.hashCode;

  factory ChatStarter.fromJson(Map<String, dynamic> json) => _$ChatStarterFromJson(json);

  Map<String, dynamic> toJson() => _$ChatStarterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

