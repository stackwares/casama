//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/task_comment.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_comment_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskCommentList {
  /// Returns a new [TaskCommentList] instance.
  TaskCommentList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<TaskComment> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskCommentList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory TaskCommentList.fromJson(Map<String, dynamic> json) => _$TaskCommentListFromJson(json);

  Map<String, dynamic> toJson() => _$TaskCommentListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

