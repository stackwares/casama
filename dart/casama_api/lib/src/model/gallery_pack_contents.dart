//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_pack_contents.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryPackContents {
  /// Returns a new [GalleryPackContents] instance.
  GalleryPackContents({

    required  this.bots,

    required  this.skills,

    required  this.routines,

    required  this.apps,

    required  this.looks,

    required  this.tools,
  });

  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final int bots;



  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final int skills;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final int routines;



  @JsonKey(
    
    name: r'apps',
    required: true,
    includeIfNull: false,
  )


  final int apps;



  @JsonKey(
    
    name: r'looks',
    required: true,
    includeIfNull: false,
  )


  final int looks;



  @JsonKey(
    
    name: r'tools',
    required: true,
    includeIfNull: false,
  )


  final int tools;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryPackContents &&
      other.bots == bots &&
      other.skills == skills &&
      other.routines == routines &&
      other.apps == apps &&
      other.looks == looks &&
      other.tools == tools;

    @override
    int get hashCode =>
        bots.hashCode +
        skills.hashCode +
        routines.hashCode +
        apps.hashCode +
        looks.hashCode +
        tools.hashCode;

  factory GalleryPackContents.fromJson(Map<String, dynamic> json) => _$GalleryPackContentsFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPackContentsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

