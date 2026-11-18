//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_kind_diff_changed_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackKindDiffChangedInner {
  /// Returns a new [PackKindDiffChangedInner] instance.
  PackKindDiffChangedInner({

    required  this.id,

    required  this.diff,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'diff',
    required: true,
    includeIfNull: false,
  )


  final List<String> diff;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackKindDiffChangedInner &&
      other.id == id &&
      other.diff == diff;

    @override
    int get hashCode =>
        id.hashCode +
        diff.hashCode;

  factory PackKindDiffChangedInner.fromJson(Map<String, dynamic> json) => _$PackKindDiffChangedInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PackKindDiffChangedInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

