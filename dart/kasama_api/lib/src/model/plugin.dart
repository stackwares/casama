//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/plugin_secret_info.dart';
import 'package:kasama_api/src/model/installed_plugin_server.dart';
import 'package:kasama_api/src/model/plugin_skills_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Plugin {
  /// Returns a new [Plugin] instance.
  Plugin({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.version,

    required  this.description,

    required  this.repo,

    required  this.path,

    required  this.commit,

    required  this.skills,

    required  this.servers,

    required  this.hosts,

    required  this.secrets,

    required  this.installedAt,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



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


  final List<PluginSkillsInner> skills;



  @JsonKey(
    
    name: r'servers',
    required: true,
    includeIfNull: false,
  )


  final List<InstalledPluginServer> servers;



  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> hosts;



  @JsonKey(
    
    name: r'secrets',
    required: true,
    includeIfNull: false,
  )


  final List<PluginSecretInfo> secrets;



  @JsonKey(
    
    name: r'installed_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime installedAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Plugin &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.version == version &&
      other.description == description &&
      other.repo == repo &&
      other.path == path &&
      other.commit == commit &&
      other.skills == skills &&
      other.servers == servers &&
      other.hosts == hosts &&
      other.secrets == secrets &&
      other.installedAt == installedAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        (version == null ? 0 : version.hashCode) +
        description.hashCode +
        repo.hashCode +
        path.hashCode +
        commit.hashCode +
        skills.hashCode +
        servers.hashCode +
        hosts.hashCode +
        secrets.hashCode +
        installedAt.hashCode +
        updatedAt.hashCode;

  factory Plugin.fromJson(Map<String, dynamic> json) => _$PluginFromJson(json);

  Map<String, dynamic> toJson() => _$PluginToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

