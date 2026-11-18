//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_skill_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackSkillPreview {
  /// Returns a new [PackSkillPreview] instance.
  PackSkillPreview({

    required  this.name,

    required  this.description,

    required  this.scope,

    required  this.bots,

    required  this.runsScripts,
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



  @JsonKey(
    
    name: r'scope',
    required: true,
    includeIfNull: false,
  )


  final PackSkillPreviewScopeEnum scope;



  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final List<String> bots;



  @JsonKey(
    
    name: r'runs_scripts',
    required: true,
    includeIfNull: false,
  )


  final bool runsScripts;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackSkillPreview &&
      other.name == name &&
      other.description == description &&
      other.scope == scope &&
      other.bots == bots &&
      other.runsScripts == runsScripts;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        scope.hashCode +
        bots.hashCode +
        runsScripts.hashCode;

  factory PackSkillPreview.fromJson(Map<String, dynamic> json) => _$PackSkillPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackSkillPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackSkillPreviewScopeEnum {
@JsonValue(r'workspace')
workspace(r'workspace'),
@JsonValue(r'bot')
bot(r'bot');

const PackSkillPreviewScopeEnum(this.value);

final String value;

@override
String toString() => value;
}


