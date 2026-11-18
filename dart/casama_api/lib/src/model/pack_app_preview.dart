//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_app_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackAppPreview {
  /// Returns a new [PackAppPreview] instance.
  PackAppPreview({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.host,

    required  this.url,

    required  this.auth,

    required  this.capabilities,

    required  this.color,
  });

      /// The app's id in the catalog once installed
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
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'host',
    required: true,
    includeIfNull: false,
  )


  final String host;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'auth',
    required: true,
    includeIfNull: false,
  )


  final List<String> auth;



  @JsonKey(
    
    name: r'capabilities',
    required: true,
    includeIfNull: false,
  )


  final List<String> capabilities;



  @JsonKey(
    
    name: r'color',
    required: true,
    includeIfNull: false,
  )


  final String color;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackAppPreview &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.host == host &&
      other.url == url &&
      other.auth == auth &&
      other.capabilities == capabilities &&
      other.color == color;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        host.hashCode +
        url.hashCode +
        auth.hashCode +
        capabilities.hashCode +
        color.hashCode;

  factory PackAppPreview.fromJson(Map<String, dynamic> json) => _$PackAppPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackAppPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

