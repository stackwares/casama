//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_loaded_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillLoadedEventPayload {
  /// Returns a new [SkillLoadedEventPayload] instance.
  SkillLoadedEventPayload({

    required  this.skillId,

    required  this.name,
  });

  @JsonKey(
    
    name: r'skill_id',
    required: true,
    includeIfNull: false,
  )


  final String skillId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillLoadedEventPayload &&
      other.skillId == skillId &&
      other.name == name;

    @override
    int get hashCode =>
        skillId.hashCode +
        name.hashCode;

  factory SkillLoadedEventPayload.fromJson(Map<String, dynamic> json) => _$SkillLoadedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SkillLoadedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

