//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teach_target.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachTarget {
  /// Returns a new [TeachTarget] instance.
  TeachTarget({

     this.role,

    required  this.name,
  });

  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  )


  final String? role;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TeachTarget &&
      other.role == role &&
      other.name == name;

    @override
    int get hashCode =>
        role.hashCode +
        name.hashCode;

  factory TeachTarget.fromJson(Map<String, dynamic> json) => _$TeachTargetFromJson(json);

  Map<String, dynamic> toJson() => _$TeachTargetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

