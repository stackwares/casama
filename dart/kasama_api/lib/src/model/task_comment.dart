//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_comment.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskComment {
  /// Returns a new [TaskComment] instance.
  TaskComment({

    required  this.id,

    required  this.taskId,

    required  this.authorType,

    required  this.authorUserId,

    required  this.authorBotId,

    required  this.bodyMd,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'task_id',
    required: true,
    includeIfNull: false,
  )


  final String taskId;



  @JsonKey(
    
    name: r'author_type',
    required: true,
    includeIfNull: false,
  )


  final TaskCommentAuthorTypeEnum authorType;



  @JsonKey(
    
    name: r'author_user_id',
    required: true,
    includeIfNull: true,
  )


  final String? authorUserId;



  @JsonKey(
    
    name: r'author_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? authorBotId;



  @JsonKey(
    
    name: r'body_md',
    required: true,
    includeIfNull: false,
  )


  final String bodyMd;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskComment &&
      other.id == id &&
      other.taskId == taskId &&
      other.authorType == authorType &&
      other.authorUserId == authorUserId &&
      other.authorBotId == authorBotId &&
      other.bodyMd == bodyMd &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        taskId.hashCode +
        authorType.hashCode +
        (authorUserId == null ? 0 : authorUserId.hashCode) +
        (authorBotId == null ? 0 : authorBotId.hashCode) +
        bodyMd.hashCode +
        createdAt.hashCode;

  factory TaskComment.fromJson(Map<String, dynamic> json) => _$TaskCommentFromJson(json);

  Map<String, dynamic> toJson() => _$TaskCommentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TaskCommentAuthorTypeEnum {
@JsonValue(r'user')
user(r'user'),
@JsonValue(r'bot')
bot(r'bot');

const TaskCommentAuthorTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


