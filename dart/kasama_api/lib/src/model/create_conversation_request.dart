//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_conversation_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateConversationRequest {
  /// Returns a new [CreateConversationRequest] instance.
  CreateConversationRequest({

    required  this.botId,

     this.title,

     this.botIds,
  });

      /// The bot, or a group chat's lead
  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



      /// A group chat (D-118): the other bots (the lead may be listed too); 2 to 10 bots in all
  @JsonKey(
    
    name: r'bot_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? botIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateConversationRequest &&
      other.botId == botId &&
      other.title == title &&
      other.botIds == botIds;

    @override
    int get hashCode =>
        botId.hashCode +
        title.hashCode +
        botIds.hashCode;

  factory CreateConversationRequest.fromJson(Map<String, dynamic> json) => _$CreateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateConversationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

