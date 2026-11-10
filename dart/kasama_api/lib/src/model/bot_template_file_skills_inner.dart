//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/bot_template_file_skills_inner_files_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_template_file_skills_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotTemplateFileSkillsInner {
  /// Returns a new [BotTemplateFileSkillsInner] instance.
  BotTemplateFileSkillsInner({

    required  this.name,

    required  this.description,

    required  this.bodyMd,

     this.files,
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
    
    name: r'body_md',
    required: true,
    includeIfNull: false,
  )


  final String bodyMd;



  @JsonKey(
    
    name: r'files',
    required: false,
    includeIfNull: false,
  )


  final List<BotTemplateFileSkillsInnerFilesInner>? files;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotTemplateFileSkillsInner &&
      other.name == name &&
      other.description == description &&
      other.bodyMd == bodyMd &&
      other.files == files;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        bodyMd.hashCode +
        files.hashCode;

  factory BotTemplateFileSkillsInner.fromJson(Map<String, dynamic> json) => _$BotTemplateFileSkillsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$BotTemplateFileSkillsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

