//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/blocked_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'blocked_person_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BlockedPersonList {
  /// Returns a new [BlockedPersonList] instance.
  BlockedPersonList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<BlockedPerson> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BlockedPersonList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory BlockedPersonList.fromJson(Map<String, dynamic> json) => _$BlockedPersonListFromJson(json);

  Map<String, dynamic> toJson() => _$BlockedPersonListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

