//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_reaction.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageReaction {
  /// Returns a new [MessageReaction] instance.
  MessageReaction({

    required  this.emoji,

    required  this.userId,

    required  this.botId,

    required  this.name,

    required  this.avatarUrl,

    required  this.source_,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'emoji',
    required: true,
    includeIfNull: false,
  )


  final String emoji;



  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: true,
  )


  final String? userId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



      /// The person's or bot's name
  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'avatar_url',
    required: true,
    includeIfNull: true,
  )


  final String? avatarUrl;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final MessageReactionSource_Enum source_;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageReaction &&
      other.emoji == emoji &&
      other.userId == userId &&
      other.botId == botId &&
      other.name == name &&
      other.avatarUrl == avatarUrl &&
      other.source_ == source_ &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        emoji.hashCode +
        (userId == null ? 0 : userId.hashCode) +
        (botId == null ? 0 : botId.hashCode) +
        name.hashCode +
        (avatarUrl == null ? 0 : avatarUrl.hashCode) +
        source_.hashCode +
        createdAt.hashCode;

  factory MessageReaction.fromJson(Map<String, dynamic> json) => _$MessageReactionFromJson(json);

  Map<String, dynamic> toJson() => _$MessageReactionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MessageReactionSource_Enum {
@JsonValue(r'app')
app(r'app'),
@JsonValue(r'api')
api(r'api'),
@JsonValue(r'channel')
channel(r'channel'),
@JsonValue(r'bot')
bot(r'bot');

const MessageReactionSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


