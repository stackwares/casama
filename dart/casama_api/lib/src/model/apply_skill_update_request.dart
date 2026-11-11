//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'apply_skill_update_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApplySkillUpdateRequest {
  /// Returns a new [ApplySkillUpdateRequest] instance.
  ApplySkillUpdateRequest({

    required  this.commit,
  });

  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApplySkillUpdateRequest &&
      other.commit == commit;

    @override
    int get hashCode =>
        commit.hashCode;

  factory ApplySkillUpdateRequest.fromJson(Map<String, dynamic> json) => _$ApplySkillUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApplySkillUpdateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

