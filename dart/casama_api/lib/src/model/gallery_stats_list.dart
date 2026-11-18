//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_stats.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_stats_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryStatsList {
  /// Returns a new [GalleryStatsList] instance.
  GalleryStatsList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final Map<String, GalleryStats> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryStatsList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GalleryStatsList.fromJson(Map<String, dynamic> json) => _$GalleryStatsListFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryStatsListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

