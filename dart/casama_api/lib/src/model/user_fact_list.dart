//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/user_fact.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_fact_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UserFactList {
  /// Returns a new [UserFactList] instance.
  UserFactList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<UserFact> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UserFactList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory UserFactList.fromJson(Map<String, dynamic> json) => _$UserFactListFromJson(json);

  Map<String, dynamic> toJson() => _$UserFactListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

