//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_item_tested.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryItemTested {
  /// Returns a new [GalleryItemTested] instance.
  GalleryItemTested({

    required  this.version,

    required  this.date,
  });

  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final String date;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryItemTested &&
      other.version == version &&
      other.date == date;

    @override
    int get hashCode =>
        version.hashCode +
        date.hashCode;

  factory GalleryItemTested.fromJson(Map<String, dynamic> json) => _$GalleryItemTestedFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryItemTestedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

