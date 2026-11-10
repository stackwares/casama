//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/skill_preview_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'git_hub_skill_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GitHubSkillPreview {
  /// Returns a new [GitHubSkillPreview] instance.
  GitHubSkillPreview({

    required  this.repo,

    required  this.path,

    required  this.ref,

    required  this.commit,

    required  this.name,

    required  this.description,

    required  this.skillMd,

    required  this.files,
  });

  @JsonKey(
    
    name: r'repo',
    required: true,
    includeIfNull: false,
  )


  final String repo;



  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'ref',
    required: true,
    includeIfNull: true,
  )


  final String? ref;



      /// The pinned commit installs and updates use
  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;



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
    
    name: r'skill_md',
    required: true,
    includeIfNull: false,
  )


  final String skillMd;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<SkillPreviewFile> files;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GitHubSkillPreview &&
      other.repo == repo &&
      other.path == path &&
      other.ref == ref &&
      other.commit == commit &&
      other.name == name &&
      other.description == description &&
      other.skillMd == skillMd &&
      other.files == files;

    @override
    int get hashCode =>
        repo.hashCode +
        path.hashCode +
        (ref == null ? 0 : ref.hashCode) +
        commit.hashCode +
        name.hashCode +
        description.hashCode +
        skillMd.hashCode +
        files.hashCode;

  factory GitHubSkillPreview.fromJson(Map<String, dynamic> json) => _$GitHubSkillPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$GitHubSkillPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

