//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_author_item_stats.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAuthorItemStats {
  /// Returns a new [GalleryAuthorItemStats] instance.
  GalleryAuthorItemStats({

    required  this.installers,

    required  this.installers7d,

    required  this.active,

    required  this.runsOk,

    required  this.runsTotal,
  });

  @JsonKey(
    
    name: r'installers',
    required: true,
    includeIfNull: false,
  )


  final int installers;



  @JsonKey(
    
    name: r'installers_7d',
    required: true,
    includeIfNull: false,
  )


  final int installers7d;



  @JsonKey(
    
    name: r'active',
    required: true,
    includeIfNull: false,
  )


  final int active;



  @JsonKey(
    
    name: r'runs_ok',
    required: true,
    includeIfNull: false,
  )


  final int runsOk;



  @JsonKey(
    
    name: r'runs_total',
    required: true,
    includeIfNull: false,
  )


  final int runsTotal;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAuthorItemStats &&
      other.installers == installers &&
      other.installers7d == installers7d &&
      other.active == active &&
      other.runsOk == runsOk &&
      other.runsTotal == runsTotal;

    @override
    int get hashCode =>
        installers.hashCode +
        installers7d.hashCode +
        active.hashCode +
        runsOk.hashCode +
        runsTotal.hashCode;

  factory GalleryAuthorItemStats.fromJson(Map<String, dynamic> json) => _$GalleryAuthorItemStatsFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAuthorItemStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

