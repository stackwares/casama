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
  });

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





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateConversationRequest &&
      other.botId == botId &&
      other.title == title;

    @override
    int get hashCode =>
        botId.hashCode +
        title.hashCode;

  factory CreateConversationRequest.fromJson(Map<String, dynamic> json) => _$CreateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateConversationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

