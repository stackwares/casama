//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_missing_apps_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_missing.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryMissing {
  /// Returns a new [GalleryMissing] instance.
  GalleryMissing({

    required  this.apps,

    required  this.skills,
  });

  @JsonKey(
    
    name: r'apps',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryMissingAppsInner> apps;



  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryMissingAppsInner> skills;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryMissing &&
      other.apps == apps &&
      other.skills == skills;

    @override
    int get hashCode =>
        apps.hashCode +
        skills.hashCode;

  factory GalleryMissing.fromJson(Map<String, dynamic> json) => _$GalleryMissingFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryMissingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

