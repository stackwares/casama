//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/project.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectList {
  /// Returns a new [ProjectList] instance.
  ProjectList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Project> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProjectList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ProjectList.fromJson(Map<String, dynamic> json) => _$ProjectListFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

