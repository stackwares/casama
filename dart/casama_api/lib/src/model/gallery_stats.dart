//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_stats.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryStats {
  /// Returns a new [GalleryStats] instance.
  GalleryStats({

     this.installers,

     this.trending,

     this.active,

     this.success,
  });

  @JsonKey(
    
    name: r'installers',
    required: false,
    includeIfNull: false,
  )


  final int? installers;



      /// New installers this week
  @JsonKey(
    
    name: r'trending',
    required: false,
    includeIfNull: false,
  )


  final int? trending;



      /// People who used it in 14 days
  @JsonKey(
    
    name: r'active',
    required: false,
    includeIfNull: false,
  )


  final int? active;



      /// Share of runs that finished, 0 to 1 (last 30 days)
  @JsonKey(
    
    name: r'success',
    required: false,
    includeIfNull: false,
  )


  final num? success;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryStats &&
      other.installers == installers &&
      other.trending == trending &&
      other.active == active &&
      other.success == success;

    @override
    int get hashCode =>
        installers.hashCode +
        trending.hashCode +
        active.hashCode +
        success.hashCode;

  factory GalleryStats.fromJson(Map<String, dynamic> json) => _$GalleryStatsFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

