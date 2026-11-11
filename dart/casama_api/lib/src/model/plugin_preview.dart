//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/plugin_server_info.dart';
import 'package:casama_api/src/model/plugin_preview_skills_inner.dart';
import 'package:casama_api/src/model/plugin_secret_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginPreview {
  /// Returns a new [PluginPreview] instance.
  PluginPreview({

    required  this.name,

    required  this.version,

    required  this.description,

    required  this.repo,

    required  this.path,

    required  this.commit,

    required  this.skills,

    required  this.servers,

    required  this.secrets,

    required  this.hosts,

    required  this.warnings,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: true,
  )


  final String? version;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



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
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;



  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final List<PluginPreviewSkillsInner> skills;



  @JsonKey(
    
    name: r'servers',
    required: true,
    includeIfNull: false,
  )


  final List<PluginServerInfo> servers;



  @JsonKey(
    
    name: r'secrets',
    required: true,
    includeIfNull: false,
  )


  final List<PluginSecretInfo> secrets;



  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> hosts;



  @JsonKey(
    
    name: r'warnings',
    required: true,
    includeIfNull: false,
  )


  final List<String> warnings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginPreview &&
      other.name == name &&
      other.version == version &&
      other.description == description &&
      other.repo == repo &&
      other.path == path &&
      other.commit == commit &&
      other.skills == skills &&
      other.servers == servers &&
      other.secrets == secrets &&
      other.hosts == hosts &&
      other.warnings == warnings;

    @override
    int get hashCode =>
        name.hashCode +
        (version == null ? 0 : version.hashCode) +
        description.hashCode +
        repo.hashCode +
        path.hashCode +
        commit.hashCode +
        skills.hashCode +
        servers.hashCode +
        secrets.hashCode +
        hosts.hashCode +
        warnings.hashCode;

  factory PluginPreview.fromJson(Map<String, dynamic> json) => _$PluginPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PluginPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

