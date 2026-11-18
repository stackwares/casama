//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_badge.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceBadge {
  /// Returns a new [WorkspaceBadge] instance.
  WorkspaceBadge({

    required  this.orgId,

    required  this.approvals,

    required  this.unread,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'approvals',
    required: true,
    includeIfNull: false,
  )


  final int approvals;



  @JsonKey(
    
    name: r'unread',
    required: true,
    includeIfNull: false,
  )


  final int unread;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceBadge &&
      other.orgId == orgId &&
      other.approvals == approvals &&
      other.unread == unread;

    @override
    int get hashCode =>
        orgId.hashCode +
        approvals.hashCode +
        unread.hashCode;

  factory WorkspaceBadge.fromJson(Map<String, dynamic> json) => _$WorkspaceBadgeFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceBadgeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

