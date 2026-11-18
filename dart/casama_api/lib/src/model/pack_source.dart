//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_source.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackSource {
  /// Returns a new [PackSource] instance.
  PackSource({

    required  this.kind,

    required  this.repo,

    required  this.path,

    required  this.url,

    required  this.galleryId,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PackSourceKindEnum kind;



  @JsonKey(
    
    name: r'repo',
    required: true,
    includeIfNull: true,
  )


  final String? repo;



  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: true,
  )


  final String? path;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;



  @JsonKey(
    
    name: r'gallery_id',
    required: true,
    includeIfNull: true,
  )


  final String? galleryId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackSource &&
      other.kind == kind &&
      other.repo == repo &&
      other.path == path &&
      other.url == url &&
      other.galleryId == galleryId;

    @override
    int get hashCode =>
        kind.hashCode +
        (repo == null ? 0 : repo.hashCode) +
        (path == null ? 0 : path.hashCode) +
        (url == null ? 0 : url.hashCode) +
        (galleryId == null ? 0 : galleryId.hashCode);

  factory PackSource.fromJson(Map<String, dynamic> json) => _$PackSourceFromJson(json);

  Map<String, dynamic> toJson() => _$PackSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackSourceKindEnum {
@JsonValue(r'github')
github(r'github'),
@JsonValue(r'gallery')
gallery(r'gallery'),
@JsonValue(r'share')
share(r'share'),
@JsonValue(r'upload')
upload(r'upload');

const PackSourceKindEnum(this.value);

final String value;

@override
String toString() => value;
}


