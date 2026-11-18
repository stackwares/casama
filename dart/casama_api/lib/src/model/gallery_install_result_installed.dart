//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_workspace_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_install_result_installed.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInstallResultInstalled {
  /// Returns a new [GalleryInstallResultInstalled] instance.
  GalleryInstallResultInstalled({

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
    bool operator ==(Object other) => identical(this, other) || other is GalleryInstallResultInstalled &&
      other.kind == kind &&
      other.id == id;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode;

  factory GalleryInstallResultInstalled.fromJson(Map<String, dynamic> json) => _$GalleryInstallResultInstalledFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInstallResultInstalledToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

