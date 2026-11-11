//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'catalog_skill.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogSkill {
  /// Returns a new [CatalogSkill] instance.
  CatalogSkill({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.category,

     this.icon,

    required  this.files,

     this.skillMd,
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
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'category',
    required: true,
    includeIfNull: false,
  )


  final String category;



      /// A Lucide icon name (kebab-case); apps fall back to the category's icon
  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<String> files;



      /// The raw SKILL.md, for a preview
  @JsonKey(
    
    name: r'skill_md',
    required: false,
    includeIfNull: false,
  )


  final String? skillMd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CatalogSkill &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.icon == icon &&
      other.files == files &&
      other.skillMd == skillMd;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        category.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        files.hashCode +
        skillMd.hashCode;

  factory CatalogSkill.fromJson(Map<String, dynamic> json) => _$CatalogSkillFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogSkillToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

