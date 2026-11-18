//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'for_you_brief.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForYouBrief {
  /// Returns a new [ForYouBrief] instance.
  ForYouBrief({

    required  this.botId,

    required  this.conversationId,

    required  this.text,

    required  this.createdAt,
  });

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
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ForYouBrief &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.text == text &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        botId.hashCode +
        conversationId.hashCode +
        text.hashCode +
        createdAt.hashCode;

  factory ForYouBrief.fromJson(Map<String, dynamic> json) => _$ForYouBriefFromJson(json);

  Map<String, dynamic> toJson() => _$ForYouBriefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

