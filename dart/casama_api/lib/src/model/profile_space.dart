//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile_space.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProfileSpace {
  /// Returns a new [ProfileSpace] instance.
  ProfileSpace({

    required  this.orgId,

    required  this.shared,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'shared',
    required: true,
    includeIfNull: false,
  )


  final bool shared;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProfileSpace &&
      other.orgId == orgId &&
      other.shared == shared;

    @override
    int get hashCode =>
        orgId.hashCode +
        shared.hashCode;

  factory ProfileSpace.fromJson(Map<String, dynamic> json) => _$ProfileSpaceFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileSpaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

