//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'welcome_chat.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WelcomeChat {
  /// Returns a new [WelcomeChat] instance.
  WelcomeChat({

    required  this.orgId,

    required  this.botId,

    required  this.conversationId,

    required  this.created,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: false,
  )


  final String conversationId;



  @JsonKey(
    
    name: r'created',
    required: true,
    includeIfNull: false,
  )


  final bool created;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WelcomeChat &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.created == created;

    @override
    int get hashCode =>
        orgId.hashCode +
        botId.hashCode +
        conversationId.hashCode +
        created.hashCode;

  factory WelcomeChat.fromJson(Map<String, dynamic> json) => _$WelcomeChatFromJson(json);

  Map<String, dynamic> toJson() => _$WelcomeChatToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

