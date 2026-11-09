//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/routine.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoutineList {
  /// Returns a new [RoutineList] instance.
  RoutineList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Routine> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RoutineList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory RoutineList.fromJson(Map<String, dynamic> json) => _$RoutineListFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

