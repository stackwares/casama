//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/glance_task.dart';
import 'package:casama_api/src/model/glance_tasks_counts.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_tasks.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceTasks {
  /// Returns a new [GlanceTasks] instance.
  GlanceTasks({

    required  this.counts,

    required  this.items,
  });

  @JsonKey(
    
    name: r'counts',
    required: true,
    includeIfNull: false,
  )


  final GlanceTasksCounts counts;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceTask> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceTasks &&
      other.counts == counts &&
      other.items == items;

    @override
    int get hashCode =>
        counts.hashCode +
        items.hashCode;

  factory GlanceTasks.fromJson(Map<String, dynamic> json) => _$GlanceTasksFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceTasksToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

