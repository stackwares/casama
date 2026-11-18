//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_workspace_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_installed_item_target.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInstalledItemTarget {
  /// Returns a new [GalleryInstalledItemTarget] instance.
  GalleryInstalledItemTarget({

    required  this.kind,

    required  this.id,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final GalleryWorkspaceKind kind;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryInstalledItemTarget &&
      other.kind == kind &&
      other.id == id;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode;

  factory GalleryInstalledItemTarget.fromJson(Map<String, dynamic> json) => _$GalleryInstalledItemTargetFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInstalledItemTargetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

