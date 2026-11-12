//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/computer_bot_use.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_bot_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerBotList {
  /// Returns a new [ComputerBotList] instance.
  ComputerBotList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ComputerBotUse> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerBotList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ComputerBotList.fromJson(Map<String, dynamic> json) => _$ComputerBotListFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerBotListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

