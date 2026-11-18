//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryList {
  /// Returns a new [GalleryList] instance.
  GalleryList({

    required  this.available,

    required  this.items,
  });

      /// False when the gallery host could not be read. Built-in looks still apply.
  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryItem> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryList &&
      other.available == available &&
      other.items == items;

    @override
    int get hashCode =>
        available.hashCode +
        items.hashCode;

  factory GalleryList.fromJson(Map<String, dynamic> json) => _$GalleryListFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

