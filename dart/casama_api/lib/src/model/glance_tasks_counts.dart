//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_tasks_counts.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceTasksCounts {
  /// Returns a new [GlanceTasksCounts] instance.
  GlanceTasksCounts({

    required  this.todo,

    required  this.inProgress,

    required  this.inReview,

    required  this.blocked,
  });

  @JsonKey(
    
    name: r'todo',
    required: true,
    includeIfNull: false,
  )


  final int todo;



  @JsonKey(
    
    name: r'in_progress',
    required: true,
    includeIfNull: false,
  )


  final int inProgress;



  @JsonKey(
    
    name: r'in_review',
    required: true,
    includeIfNull: false,
  )


  final int inReview;



  @JsonKey(
    
    name: r'blocked',
    required: true,
    includeIfNull: false,
  )


  final int blocked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceTasksCounts &&
      other.todo == todo &&
      other.inProgress == inProgress &&
      other.inReview == inReview &&
      other.blocked == blocked;

    @override
    int get hashCode =>
        todo.hashCode +
        inProgress.hashCode +
        inReview.hashCode +
        blocked.hashCode;

  factory GlanceTasksCounts.fromJson(Map<String, dynamic> json) => _$GlanceTasksCountsFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceTasksCountsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

