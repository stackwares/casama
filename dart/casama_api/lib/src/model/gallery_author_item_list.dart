//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_author_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_author_item_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAuthorItemList {
  /// Returns a new [GalleryAuthorItemList] instance.
  GalleryAuthorItemList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryAuthorItem> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAuthorItemList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GalleryAuthorItemList.fromJson(Map<String, dynamic> json) => _$GalleryAuthorItemListFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAuthorItemListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

