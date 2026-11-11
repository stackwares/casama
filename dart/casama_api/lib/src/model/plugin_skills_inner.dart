//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_skills_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginSkillsInner {
  /// Returns a new [PluginSkillsInner] instance.
  PluginSkillsInner({

    required  this.id,

    required  this.name,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginSkillsInner &&
      other.id == id &&
      other.name == name;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode;

  factory PluginSkillsInner.fromJson(Map<String, dynamic> json) => _$PluginSkillsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PluginSkillsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

