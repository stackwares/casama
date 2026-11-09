//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Conversation {
  /// Returns a new [Conversation] instance.
  Conversation({

    required  this.id,

    required  this.botId,

    required  this.title,

    required  this.lastMessageAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: true,
  )


  final String? title;



  @JsonKey(
    
    name: r'last_message_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastMessageAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Conversation &&
      other.id == id &&
      other.botId == botId &&
      other.title == title &&
      other.lastMessageAt == lastMessageAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        (title == null ? 0 : title.hashCode) +
        (lastMessageAt == null ? 0 : lastMessageAt.hashCode) +
        createdAt.hashCode;

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

