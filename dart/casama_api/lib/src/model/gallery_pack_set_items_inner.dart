//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_pack_set_items_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryPackSetItemsInner {
  /// Returns a new [GalleryPackSetItemsInner] instance.
  GalleryPackSetItemsInner({

    required  this.type,

    required  this.id,
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
    includeIfNull: false,
  )


  final String id;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryPackSetItemsInner &&
      other.type == type &&
      other.id == id;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode;

  factory GalleryPackSetItemsInner.fromJson(Map<String, dynamic> json) => _$GalleryPackSetItemsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPackSetItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

