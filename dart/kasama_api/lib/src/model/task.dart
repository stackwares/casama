//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Task {
  /// Returns a new [Task] instance.
  Task({

    required  this.id,

    required  this.title,

    required  this.detailsMd,

    required  this.status,

    required  this.assigneeBotId,

    required  this.createdByBotId,

    required  this.resultMd,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'details_md',
    required: true,
    includeIfNull: false,
  )


  final String detailsMd;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final TaskStatusEnum status;



  @JsonKey(
    
    name: r'assignee_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? assigneeBotId;



  @JsonKey(
    
    name: r'created_by_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? createdByBotId;



  @JsonKey(
    
    name: r'result_md',
    required: true,
    includeIfNull: true,
  )


  final String? resultMd;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Task &&
      other.id == id &&
      other.title == title &&
      other.detailsMd == detailsMd &&
      other.status == status &&
      other.assigneeBotId == assigneeBotId &&
      other.createdByBotId == createdByBotId &&
      other.resultMd == resultMd &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        detailsMd.hashCode +
        status.hashCode +
        (assigneeBotId == null ? 0 : assigneeBotId.hashCode) +
        (createdByBotId == null ? 0 : createdByBotId.hashCode) +
        (resultMd == null ? 0 : resultMd.hashCode) +
        updatedAt.hashCode;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TaskStatusEnum {
@JsonValue(r'todo')
todo(r'todo'),
@JsonValue(r'doing')
doing(r'doing'),
@JsonValue(r'done')
done(r'done'),
@JsonValue(r'blocked')
blocked(r'blocked');

const TaskStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


