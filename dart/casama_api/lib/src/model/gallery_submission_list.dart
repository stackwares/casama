//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_submission.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_submission_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GallerySubmissionList {
  /// Returns a new [GallerySubmissionList] instance.
  GallerySubmissionList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GallerySubmission> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GallerySubmissionList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory GallerySubmissionList.fromJson(Map<String, dynamic> json) => _$GallerySubmissionListFromJson(json);

  Map<String, dynamic> toJson() => _$GallerySubmissionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

