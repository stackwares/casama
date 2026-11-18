//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/workspace_member.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_member_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceMemberList {
  /// Returns a new [WorkspaceMemberList] instance.
  WorkspaceMemberList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<WorkspaceMember> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceMemberList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory WorkspaceMemberList.fromJson(Map<String, dynamic> json) => _$WorkspaceMemberListFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceMemberListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

