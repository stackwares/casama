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

    required  this.files,
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



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<String> files;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CatalogSkill &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.files == files;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        category.hashCode +
        files.hashCode;

  factory CatalogSkill.fromJson(Map<String, dynamic> json) => _$CatalogSkillFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogSkillToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

