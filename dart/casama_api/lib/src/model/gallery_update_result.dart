//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_update_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryUpdateResult {
  /// Returns a new [GalleryUpdateResult] instance.
  GalleryUpdateResult({

    required  this.updated,

    required  this.version,
  });

  @JsonKey(
    
    name: r'updated',
    required: true,
    includeIfNull: false,
  )


  final int updated;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryUpdateResult &&
      other.updated == updated &&
      other.version == version;

    @override
    int get hashCode =>
        updated.hashCode +
        version.hashCode;

  factory GalleryUpdateResult.fromJson(Map<String, dynamic> json) => _$GalleryUpdateResultFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryUpdateResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

