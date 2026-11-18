//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'joinable_workspace.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinableWorkspace {
  /// Returns a new [JoinableWorkspace] instance.
  JoinableWorkspace({

    required  this.id,

    required  this.name,

    required  this.icon,

    required  this.color,

    required  this.memberCount,

    required  this.domain,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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



  @JsonKey(
    
    name: r'domain',
    required: true,
    includeIfNull: false,
  )


  final String domain;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinableWorkspace &&
      other.id == id &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.memberCount == memberCount &&
      other.domain == domain;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        (color == null ? 0 : color.hashCode) +
        memberCount.hashCode +
        domain.hashCode;

  factory JoinableWorkspace.fromJson(Map<String, dynamic> json) => _$JoinableWorkspaceFromJson(json);

  Map<String, dynamic> toJson() => _$JoinableWorkspaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

