//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'install_catalog_skill_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallCatalogSkillRequest {
  /// Returns a new [InstallCatalogSkillRequest] instance.
  InstallCatalogSkillRequest({

    required  this.orgId,

     this.botId,

     this.catalogId,

     this.galleryId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



      /// Install for one bot; default the whole workspace
  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;



  @JsonKey(
    
    name: r'catalog_id',
    required: false,
    includeIfNull: false,
  )


  final String? catalogId;



      /// Install a skill from the gallery instead of the bundled catalog
  @JsonKey(
    
    name: r'gallery_id',
    required: false,
    includeIfNull: false,
  )


  final String? galleryId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstallCatalogSkillRequest &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.catalogId == catalogId &&
      other.galleryId == galleryId;

    @override
    int get hashCode =>
        orgId.hashCode +
        botId.hashCode +
        catalogId.hashCode +
        galleryId.hashCode;

  factory InstallCatalogSkillRequest.fromJson(Map<String, dynamic> json) => _$InstallCatalogSkillRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InstallCatalogSkillRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

