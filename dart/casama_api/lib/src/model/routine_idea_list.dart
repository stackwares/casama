//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/routine_idea.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine_idea_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoutineIdeaList {
  /// Returns a new [RoutineIdeaList] instance.
  RoutineIdeaList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<RoutineIdea> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RoutineIdeaList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory RoutineIdeaList.fromJson(Map<String, dynamic> json) => _$RoutineIdeaListFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineIdeaListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

