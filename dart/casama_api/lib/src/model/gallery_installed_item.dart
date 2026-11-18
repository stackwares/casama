//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_installed_item_target.dart';
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:casama_api/src/model/gallery_access_diff.dart';
import 'package:casama_api/src/model/gallery_change.dart';
import 'package:casama_api/src/model/gallery_workspace_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_installed_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInstalledItem {
  /// Returns a new [GalleryInstalledItem] instance.
  GalleryInstalledItem({

    required  this.type,

    required  this.id,

    required  this.name,

    required  this.installedVersion,

    required  this.latestVersion,

    required  this.update,

    required  this.breaking,

    required  this.accessAdded,

    required  this.retired,

     this.replacement,

    required  this.changelog,

    required  this.installedAt,

    required  this.target,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryWorkspaceKind type;



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
    
    name: r'installed_version',
    required: true,
    includeIfNull: false,
  )


  final int installedVersion;



  @JsonKey(
    
    name: r'latest_version',
    required: true,
    includeIfNull: true,
  )


  final int? latestVersion;



  @JsonKey(
    
    name: r'update',
    required: true,
    includeIfNull: false,
  )


  final bool update;



  @JsonKey(
    
    name: r'breaking',
    required: true,
    includeIfNull: false,
  )


  final bool breaking;



  @JsonKey(
    
    name: r'access_added',
    required: true,
    includeIfNull: false,
  )


  final GalleryAccessDiff accessAdded;



  @JsonKey(
    
    name: r'retired',
    required: true,
    includeIfNull: false,
  )


  final bool retired;



  @JsonKey(
    
    name: r'replacement',
    required: false,
    includeIfNull: false,
  )


  final GalleryRef? replacement;



      /// Entries newer than the installed one
  @JsonKey(
    
    name: r'changelog',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryChange> changelog;



  @JsonKey(
    
    name: r'installed_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime installedAt;



  @JsonKey(
    
    name: r'target',
    required: true,
    includeIfNull: false,
  )


  final GalleryInstalledItemTarget target;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryInstalledItem &&
      other.type == type &&
      other.id == id &&
      other.name == name &&
      other.installedVersion == installedVersion &&
      other.latestVersion == latestVersion &&
      other.update == update &&
      other.breaking == breaking &&
      other.accessAdded == accessAdded &&
      other.retired == retired &&
      other.replacement == replacement &&
      other.changelog == changelog &&
      other.installedAt == installedAt &&
      other.target == target;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode +
        name.hashCode +
        installedVersion.hashCode +
        (latestVersion == null ? 0 : latestVersion.hashCode) +
        update.hashCode +
        breaking.hashCode +
        accessAdded.hashCode +
        retired.hashCode +
        replacement.hashCode +
        changelog.hashCode +
        installedAt.hashCode +
        target.hashCode;

  factory GalleryInstalledItem.fromJson(Map<String, dynamic> json) => _$GalleryInstalledItemFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInstalledItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

