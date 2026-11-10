//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/workspace_badge.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_badge_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceBadgeList {
  /// Returns a new [WorkspaceBadgeList] instance.
  WorkspaceBadgeList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<WorkspaceBadge> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceBadgeList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory WorkspaceBadgeList.fromJson(Map<String, dynamic> json) => _$WorkspaceBadgeListFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceBadgeListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

