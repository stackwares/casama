//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/computer.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerList {
  /// Returns a new [ComputerList] instance.
  ComputerList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Computer> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ComputerList.fromJson(Map<String, dynamic> json) => _$ComputerListFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

