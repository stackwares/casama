//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_installed_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_installed_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryInstalledList {
  /// Returns a new [GalleryInstalledList] instance.
  GalleryInstalledList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryInstalledItem> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryInstalledList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GalleryInstalledList.fromJson(Map<String, dynamic> json) => _$GalleryInstalledListFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInstalledListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

