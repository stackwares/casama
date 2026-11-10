//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/catalog_skill.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_catalog.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillCatalog {
  /// Returns a new [SkillCatalog] instance.
  SkillCatalog({

    required  this.categories,

    required  this.items,
  });

  @JsonKey(
    
    name: r'categories',
    required: true,
    includeIfNull: false,
  )


  final List<String> categories;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<CatalogSkill> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillCatalog &&
      other.categories == categories &&
      other.items == items;

    @override
    int get hashCode =>
        categories.hashCode +
        items.hashCode;

  factory SkillCatalog.fromJson(Map<String, dynamic> json) => _$SkillCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$SkillCatalogToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

