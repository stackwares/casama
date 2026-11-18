//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/checkpoint.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkpoint_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckpointList {
  /// Returns a new [CheckpointList] instance.
  CheckpointList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Checkpoint> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CheckpointList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory CheckpointList.fromJson(Map<String, dynamic> json) => _$CheckpointListFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

