//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_needs.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryNeeds {
  /// Returns a new [GalleryNeeds] instance.
  GalleryNeeds({

     this.apps,

     this.skills,
  });

  @JsonKey(
    
    name: r'apps',
    required: false,
    includeIfNull: false,
  )


  final List<String>? apps;



  @JsonKey(
    
    name: r'skills',
    required: false,
    includeIfNull: false,
  )


  final List<String>? skills;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryNeeds &&
      other.apps == apps &&
      other.skills == skills;

    @override
    int get hashCode =>
        apps.hashCode +
        skills.hashCode;

  factory GalleryNeeds.fromJson(Map<String, dynamic> json) => _$GalleryNeedsFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryNeedsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

