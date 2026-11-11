//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/joinable_workspace.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'joinable_workspace_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinableWorkspaceList {
  /// Returns a new [JoinableWorkspaceList] instance.
  JoinableWorkspaceList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<JoinableWorkspace> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinableWorkspaceList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory JoinableWorkspaceList.fromJson(Map<String, dynamic> json) => _$JoinableWorkspaceListFromJson(json);

  Map<String, dynamic> toJson() => _$JoinableWorkspaceListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

