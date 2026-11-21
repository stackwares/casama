//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/workspace_model_default.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Organization {
  /// Returns a new [Organization] instance.
  Organization({

    required  this.id,

    required  this.name,

    required  this.slug,

    required  this.plan,

    required  this.region,

     this.icon,

     this.color,

     this.avatarUrl,

     this.modelDefault,

    required  this.createdAt,
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
    
    name: r'slug',
    required: true,
    includeIfNull: false,
  )


  final String slug;



  @JsonKey(
    
    name: r'plan',
    required: true,
    includeIfNull: false,
  )


  final String plan;



  @JsonKey(
    
    name: r'region',
    required: true,
    includeIfNull: false,
  )


  final String region;



  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



  @JsonKey(
    
    name: r'color',
    required: false,
    includeIfNull: false,
  )


  final String? color;



  @JsonKey(
    
    name: r'avatar_url',
    required: false,
    includeIfNull: false,
  )


  final String? avatarUrl;



  @JsonKey(
    
    name: r'model_default',
    required: false,
    includeIfNull: false,
  )


  final WorkspaceModelDefault? modelDefault;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Organization &&
      other.id == id &&
      other.name == name &&
      other.slug == slug &&
      other.plan == plan &&
      other.region == region &&
      other.icon == icon &&
      other.color == color &&
      other.avatarUrl == avatarUrl &&
      other.modelDefault == modelDefault &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        slug.hashCode +
        plan.hashCode +
        region.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        (color == null ? 0 : color.hashCode) +
        (avatarUrl == null ? 0 : avatarUrl.hashCode) +
        (modelDefault == null ? 0 : modelDefault.hashCode) +
        createdAt.hashCode;

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

