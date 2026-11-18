//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_change.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryChange {
  /// Returns a new [GalleryChange] instance.
  GalleryChange({

    required  this.version,

    required  this.date,

    required  this.note,

     this.breaking,
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



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: false,
  )


  final String note;



  @JsonKey(
    
    name: r'breaking',
    required: false,
    includeIfNull: false,
  )


  final bool? breaking;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryChange &&
      other.version == version &&
      other.date == date &&
      other.note == note &&
      other.breaking == breaking;

    @override
    int get hashCode =>
        version.hashCode +
        date.hashCode +
        note.hashCode +
        breaking.hashCode;

  factory GalleryChange.fromJson(Map<String, dynamic> json) => _$GalleryChangeFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryChangeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

