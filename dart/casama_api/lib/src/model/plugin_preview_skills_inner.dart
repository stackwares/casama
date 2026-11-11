//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_preview_skills_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginPreviewSkillsInner {
  /// Returns a new [PluginPreviewSkillsInner] instance.
  PluginPreviewSkillsInner({

    required  this.name,

    required  this.description,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginPreviewSkillsInner &&
      other.name == name &&
      other.description == description;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode;

  factory PluginPreviewSkillsInner.fromJson(Map<String, dynamic> json) => _$PluginPreviewSkillsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PluginPreviewSkillsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

