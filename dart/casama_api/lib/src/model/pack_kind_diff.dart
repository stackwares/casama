//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_kind_diff_changed_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_kind_diff.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackKindDiff {
  /// Returns a new [PackKindDiff] instance.
  PackKindDiff({

    required  this.added,

    required  this.removed,

    required  this.changed,
  });

  @JsonKey(
    
    name: r'added',
    required: true,
    includeIfNull: false,
  )


  final List<String> added;



  @JsonKey(
    
    name: r'removed',
    required: true,
    includeIfNull: false,
  )


  final List<String> removed;



  @JsonKey(
    
    name: r'changed',
    required: true,
    includeIfNull: false,
  )


  final List<PackKindDiffChangedInner> changed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackKindDiff &&
      other.added == added &&
      other.removed == removed &&
      other.changed == changed;

    @override
    int get hashCode =>
        added.hashCode +
        removed.hashCode +
        changed.hashCode;

  factory PackKindDiff.fromJson(Map<String, dynamic> json) => _$PackKindDiffFromJson(json);

  Map<String, dynamic> toJson() => _$PackKindDiffToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

