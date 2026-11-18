//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_access_diff.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAccessDiff {
  /// Returns a new [GalleryAccessDiff] instance.
  GalleryAccessDiff({

    required  this.reads,

    required  this.writes,

    required  this.runsCode,

    required  this.computer,
  });

  @JsonKey(
    
    name: r'reads',
    required: true,
    includeIfNull: false,
  )


  final List<String> reads;



  @JsonKey(
    
    name: r'writes',
    required: true,
    includeIfNull: false,
  )


  final List<String> writes;



  @JsonKey(
    
    name: r'runs_code',
    required: true,
    includeIfNull: false,
  )


  final bool runsCode;



  @JsonKey(
    
    name: r'computer',
    required: true,
    includeIfNull: false,
  )


  final bool computer;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAccessDiff &&
      other.reads == reads &&
      other.writes == writes &&
      other.runsCode == runsCode &&
      other.computer == computer;

    @override
    int get hashCode =>
        reads.hashCode +
        writes.hashCode +
        runsCode.hashCode +
        computer.hashCode;

  factory GalleryAccessDiff.fromJson(Map<String, dynamic> json) => _$GalleryAccessDiffFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAccessDiffToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

