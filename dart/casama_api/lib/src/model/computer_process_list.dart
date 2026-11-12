//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/computer_process.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_process_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerProcessList {
  /// Returns a new [ComputerProcessList] instance.
  ComputerProcessList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ComputerProcess> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerProcessList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ComputerProcessList.fromJson(Map<String, dynamic> json) => _$ComputerProcessListFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerProcessListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

