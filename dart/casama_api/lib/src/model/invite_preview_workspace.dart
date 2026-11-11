//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_preview_workspace.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InvitePreviewWorkspace {
  /// Returns a new [InvitePreviewWorkspace] instance.
  InvitePreviewWorkspace({

    required  this.name,

    required  this.icon,

    required  this.color,

    required  this.memberCount,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: true,
  )


  final String? icon;



  @JsonKey(
    
    name: r'color',
    required: true,
    includeIfNull: true,
  )


  final String? color;



  @JsonKey(
    
    name: r'member_count',
    required: true,
    includeIfNull: false,
  )


  final int memberCount;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InvitePreviewWorkspace &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.memberCount == memberCount;

    @override
    int get hashCode =>
        name.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        (color == null ? 0 : color.hashCode) +
        memberCount.hashCode;

  factory InvitePreviewWorkspace.fromJson(Map<String, dynamic> json) => _$InvitePreviewWorkspaceFromJson(json);

  Map<String, dynamic> toJson() => _$InvitePreviewWorkspaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

