//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/wallpaper_photo.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallpaper_photo_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WallpaperPhotoList {
  /// Returns a new [WallpaperPhotoList] instance.
  WallpaperPhotoList({

    required  this.items,

    required  this.source_,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<WallpaperPhoto> items;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final WallpaperPhotoListSource_Enum source_;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WallpaperPhotoList &&
      other.items == items &&
      other.source_ == source_;

    @override
    int get hashCode =>
        items.hashCode +
        source_.hashCode;

  factory WallpaperPhotoList.fromJson(Map<String, dynamic> json) => _$WallpaperPhotoListFromJson(json);

  Map<String, dynamic> toJson() => _$WallpaperPhotoListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WallpaperPhotoListSource_Enum {
@JsonValue(r'unsplash')
unsplash(r'unsplash');

const WallpaperPhotoListSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


