//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/own_coding_agent_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'own_coding_agent_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OwnCodingAgentList {
  /// Returns a new [OwnCodingAgentList] instance.
  OwnCodingAgentList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<OwnCodingAgentEntry> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OwnCodingAgentList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory OwnCodingAgentList.fromJson(Map<String, dynamic> json) => _$OwnCodingAgentListFromJson(json);

  Map<String, dynamic> toJson() => _$OwnCodingAgentListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

