//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_bot_header.dart';
import 'package:casama_api/src/model/watch_message.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_chat.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchChat {
  /// Returns a new [WatchChat] instance.
  WatchChat({

    required  this.bot,

    required  this.conversationId,

    required  this.messages,

    required  this.runId,

    required  this.link,
  });

  @JsonKey(
    
    name: r'bot',
    required: true,
    includeIfNull: false,
  )


  final WatchBotHeader bot;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'messages',
    required: true,
    includeIfNull: false,
  )


  final List<WatchMessage> messages;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: true,
  )


  final String? runId;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchChat &&
      other.bot == bot &&
      other.conversationId == conversationId &&
      other.messages == messages &&
      other.runId == runId &&
      other.link == link;

    @override
    int get hashCode =>
        bot.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        messages.hashCode +
        (runId == null ? 0 : runId.hashCode) +
        link.hashCode;

  factory WatchChat.fromJson(Map<String, dynamic> json) => _$WatchChatFromJson(json);

  Map<String, dynamic> toJson() => _$WatchChatToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

