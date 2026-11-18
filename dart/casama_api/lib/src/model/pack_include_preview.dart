//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_include_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackIncludePreview {
  /// Returns a new [PackIncludePreview] instance.
  PackIncludePreview({

    required  this.type,

    required  this.id,

    required  this.url,

    required  this.commit,

    required  this.name,

    required  this.found,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: true,
  )


  final String? id;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: true,
  )


  final String? commit;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// Whether it was found in the gallery
  @JsonKey(
    
    name: r'found',
    required: true,
    includeIfNull: false,
  )


  final bool found;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackIncludePreview &&
      other.type == type &&
      other.id == id &&
      other.url == url &&
      other.commit == commit &&
      other.name == name &&
      other.found == found;

    @override
    int get hashCode =>
        type.hashCode +
        (id == null ? 0 : id.hashCode) +
        (url == null ? 0 : url.hashCode) +
        (commit == null ? 0 : commit.hashCode) +
        name.hashCode +
        found.hashCode;

  factory PackIncludePreview.fromJson(Map<String, dynamic> json) => _$PackIncludePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackIncludePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

