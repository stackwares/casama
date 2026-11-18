//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_missing.dart';
import 'package:casama_api/src/model/gallery_set_install_result_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_set_install_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GallerySetInstallResult {
  /// Returns a new [GallerySetInstallResult] instance.
  GallerySetInstallResult({

    required  this.items,

    required  this.missing,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GallerySetInstallResultItemsInner> items;



  @JsonKey(
    
    name: r'missing',
    required: true,
    includeIfNull: false,
  )


  final GalleryMissing missing;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GallerySetInstallResult &&
      other.items == items &&
      other.missing == missing;

    @override
    int get hashCode =>
        items.hashCode +
        missing.hashCode;

  factory GallerySetInstallResult.fromJson(Map<String, dynamic> json) => _$GallerySetInstallResultFromJson(json);

  Map<String, dynamic> toJson() => _$GallerySetInstallResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

