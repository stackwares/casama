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

    required  this.kind,

    required  this.botIds,

    required  this.createdAt,

     this.canDelete,

     this.isMain,

     this.parentConversationId,

     this.anchorMessageId,

     this.status,
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
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ConversationKindEnum kind;



      /// Group chats: every bot, the lead first
  @JsonKey(
    
    name: r'bot_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> botIds;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



      /// Whether you may delete it: you started it, or you manage its bot
  @JsonKey(
    
    name: r'can_delete',
    required: false,
    includeIfNull: false,
  )


  final bool? canDelete;



      /// The person's General conversation with this bot (D-253): briefs, routine results and proactive messages land here
  @JsonKey(
    
    name: r'is_main',
    required: false,
    includeIfNull: false,
  )


  final bool? isMain;



      /// A topic's General conversation
  @JsonKey(
    
    name: r'parent_conversation_id',
    required: false,
    includeIfNull: false,
  )


  final String? parentConversationId;



      /// The message in General a topic started from (an accepted suggestion)
  @JsonKey(
    
    name: r'anchor_message_id',
    required: false,
    includeIfNull: false,
  )


  final String? anchorMessageId;



      /// needs_you: the bot waits for an approval or a take-over in it; working: a run is going
  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  )


  final ConversationStatusEnum? status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Conversation &&
      other.id == id &&
      other.botId == botId &&
      other.title == title &&
      other.lastMessageAt == lastMessageAt &&
      other.kind == kind &&
      other.botIds == botIds &&
      other.createdAt == createdAt &&
      other.canDelete == canDelete &&
      other.isMain == isMain &&
      other.parentConversationId == parentConversationId &&
      other.anchorMessageId == anchorMessageId &&
      other.status == status;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        (title == null ? 0 : title.hashCode) +
        (lastMessageAt == null ? 0 : lastMessageAt.hashCode) +
        kind.hashCode +
        botIds.hashCode +
        createdAt.hashCode +
        canDelete.hashCode +
        isMain.hashCode +
        (parentConversationId == null ? 0 : parentConversationId.hashCode) +
        (anchorMessageId == null ? 0 : anchorMessageId.hashCode) +
        (status == null ? 0 : status.hashCode);

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ConversationKindEnum {
@JsonValue(r'direct')
direct(r'direct'),
@JsonValue(r'group')
group(r'group');

const ConversationKindEnum(this.value);

final String value;

@override
String toString() => value;
}


/// needs_you: the bot waits for an approval or a take-over in it; working: a run is going
enum ConversationStatusEnum {
    /// needs_you: the bot waits for an approval or a take-over in it; working: a run is going
@JsonValue(r'needs_you')
needsYou(r'needs_you'),
    /// needs_you: the bot waits for an approval or a take-over in it; working: a run is going
@JsonValue(r'working')
working(r'working');

const ConversationStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


