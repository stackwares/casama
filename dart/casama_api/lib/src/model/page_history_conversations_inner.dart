//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_history_conversations_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageHistoryConversationsInner {
  /// Returns a new [PageHistoryConversationsInner] instance.
  PageHistoryConversationsInner({

    required  this.id,

    required  this.botId,

    required  this.title,

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
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageHistoryConversationsInner &&
      other.id == id &&
      other.botId == botId &&
      other.title == title &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        (title == null ? 0 : title.hashCode) +
        createdAt.hashCode;

  factory PageHistoryConversationsInner.fromJson(Map<String, dynamic> json) => _$PageHistoryConversationsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PageHistoryConversationsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

