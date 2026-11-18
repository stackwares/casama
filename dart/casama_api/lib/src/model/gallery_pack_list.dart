//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_pack.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_pack_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryPackList {
  /// Returns a new [GalleryPackList] instance.
  GalleryPackList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryPack> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryPackList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GalleryPackList.fromJson(Map<String, dynamic> json) => _$GalleryPackListFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPackListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

