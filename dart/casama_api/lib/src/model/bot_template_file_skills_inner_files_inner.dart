//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_template_file_skills_inner_files_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotTemplateFileSkillsInnerFilesInner {
  /// Returns a new [BotTemplateFileSkillsInnerFilesInner] instance.
  BotTemplateFileSkillsInnerFilesInner({

    required  this.path,

    required  this.contentBase64,

     this.executable,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'content_base64',
    required: true,
    includeIfNull: false,
  )


  final String contentBase64;



  @JsonKey(
    
    name: r'executable',
    required: false,
    includeIfNull: false,
  )


  final bool? executable;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotTemplateFileSkillsInnerFilesInner &&
      other.path == path &&
      other.contentBase64 == contentBase64 &&
      other.executable == executable;

    @override
    int get hashCode =>
        path.hashCode +
        contentBase64.hashCode +
        executable.hashCode;

  factory BotTemplateFileSkillsInnerFilesInner.fromJson(Map<String, dynamic> json) => _$BotTemplateFileSkillsInnerFilesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$BotTemplateFileSkillsInnerFilesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

