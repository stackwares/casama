//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_look_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackLookPreview {
  /// Returns a new [PackLookPreview] instance.
  PackLookPreview({

    required  this.type,

    required  this.id,

    required  this.name,

    required  this.document,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final PackLookPreviewTypeEnum type;



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



  @JsonKey(
    
    name: r'document',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> document;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackLookPreview &&
      other.type == type &&
      other.id == id &&
      other.name == name &&
      other.document == document;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode +
        name.hashCode +
        document.hashCode;

  factory PackLookPreview.fromJson(Map<String, dynamic> json) => _$PackLookPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackLookPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackLookPreviewTypeEnum {
@JsonValue(r'theme')
theme(r'theme'),
@JsonValue(r'scheme')
scheme(r'scheme'),
@JsonValue(r'wallpaper')
wallpaper(r'wallpaper');

const PackLookPreviewTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


