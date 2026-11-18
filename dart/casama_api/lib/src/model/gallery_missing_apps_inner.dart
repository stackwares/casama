//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_missing_apps_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryMissingAppsInner {
  /// Returns a new [GalleryMissingAppsInner] instance.
  GalleryMissingAppsInner({

    required  this.id,

    required  this.name,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryMissingAppsInner &&
      other.id == id &&
      other.name == name;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode;

  factory GalleryMissingAppsInner.fromJson(Map<String, dynamic> json) => _$GalleryMissingAppsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryMissingAppsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

