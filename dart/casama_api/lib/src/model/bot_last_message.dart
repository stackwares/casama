//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_last_message.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotLastMessage {
  /// Returns a new [BotLastMessage] instance.
  BotLastMessage({

    required  this.text,

    required  this.from,

    required  this.fileName,

    required  this.fileMime,

    required  this.conversationId,

    required  this.at,
  });

      /// Plain text, one line, cut to 160 characters
  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



      /// you = the caller; someone = another person in the workspace
  @JsonKey(
    
    name: r'from',
    required: true,
    includeIfNull: false,
  )


  final BotLastMessageFromEnum from;



      /// The first attached file, if any
  @JsonKey(
    
    name: r'file_name',
    required: true,
    includeIfNull: true,
  )


  final String? fileName;



  @JsonKey(
    
    name: r'file_mime',
    required: true,
    includeIfNull: true,
  )


  final String? fileMime;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotLastMessage &&
      other.text == text &&
      other.from == from &&
      other.fileName == fileName &&
      other.fileMime == fileMime &&
      other.conversationId == conversationId &&
      other.at == at;

    @override
    int get hashCode =>
        text.hashCode +
        from.hashCode +
        (fileName == null ? 0 : fileName.hashCode) +
        (fileMime == null ? 0 : fileMime.hashCode) +
        conversationId.hashCode +
        at.hashCode;

  factory BotLastMessage.fromJson(Map<String, dynamic> json) => _$BotLastMessageFromJson(json);

  Map<String, dynamic> toJson() => _$BotLastMessageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// you = the caller; someone = another person in the workspace
enum BotLastMessageFromEnum {
    /// you = the caller; someone = another person in the workspace
@JsonValue(r'you')
you(r'you'),
    /// you = the caller; someone = another person in the workspace
@JsonValue(r'bot')
bot(r'bot'),
    /// you = the caller; someone = another person in the workspace
@JsonValue(r'someone')
someone(r'someone');

const BotLastMessageFromEnum(this.value);

final String value;

@override
String toString() => value;
}


