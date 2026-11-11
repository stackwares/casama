//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallpaper_photo.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WallpaperPhoto {
  /// Returns a new [WallpaperPhoto] instance.
  WallpaperPhoto({

    required  this.id,

    required  this.thumbUrl,

    required  this.url,

    required  this.color,

    required  this.width,

    required  this.height,

    required  this.author,

    required  this.authorUrl,

    required  this.sourceUrl,

    required  this.downloadLocation,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'thumb_url',
    required: true,
    includeIfNull: false,
  )


  final String thumbUrl;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'color',
    required: true,
    includeIfNull: true,
  )


  final String? color;



  @JsonKey(
    
    name: r'width',
    required: true,
    includeIfNull: false,
  )


  final int width;



  @JsonKey(
    
    name: r'height',
    required: true,
    includeIfNull: false,
  )


  final int height;



  @JsonKey(
    
    name: r'author',
    required: true,
    includeIfNull: false,
  )


  final String author;



  @JsonKey(
    
    name: r'author_url',
    required: true,
    includeIfNull: false,
  )


  final String authorUrl;



  @JsonKey(
    
    name: r'source_url',
    required: true,
    includeIfNull: false,
  )


  final String sourceUrl;



  @JsonKey(
    
    name: r'download_location',
    required: true,
    includeIfNull: false,
  )


  final String downloadLocation;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WallpaperPhoto &&
      other.id == id &&
      other.thumbUrl == thumbUrl &&
      other.url == url &&
      other.color == color &&
      other.width == width &&
      other.height == height &&
      other.author == author &&
      other.authorUrl == authorUrl &&
      other.sourceUrl == sourceUrl &&
      other.downloadLocation == downloadLocation;

    @override
    int get hashCode =>
        id.hashCode +
        thumbUrl.hashCode +
        url.hashCode +
        (color == null ? 0 : color.hashCode) +
        width.hashCode +
        height.hashCode +
        author.hashCode +
        authorUrl.hashCode +
        sourceUrl.hashCode +
        downloadLocation.hashCode;

  factory WallpaperPhoto.fromJson(Map<String, dynamic> json) => _$WallpaperPhotoFromJson(json);

  Map<String, dynamic> toJson() => _$WallpaperPhotoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

