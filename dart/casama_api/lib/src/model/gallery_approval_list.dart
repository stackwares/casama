//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_approval.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_approval_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryApprovalList {
  /// Returns a new [GalleryApprovalList] instance.
  GalleryApprovalList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryApproval> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryApprovalList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GalleryApprovalList.fromJson(Map<String, dynamic> json) => _$GalleryApprovalListFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryApprovalListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

