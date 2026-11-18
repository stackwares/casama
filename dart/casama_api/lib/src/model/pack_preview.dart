//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_bot_preview.dart';
import 'package:casama_api/src/model/pack_preview_installed.dart';
import 'package:casama_api/src/model/plugin_secret_info.dart';
import 'package:casama_api/src/model/pack_skill_preview.dart';
import 'package:casama_api/src/model/plugin_setting_info.dart';
import 'package:casama_api/src/model/pack_look_preview.dart';
import 'package:casama_api/src/model/gallery_missing_apps_inner.dart';
import 'package:casama_api/src/model/plugin_server_info.dart';
import 'package:casama_api/src/model/pack_include_preview.dart';
import 'package:casama_api/src/model/pack_reach.dart';
import 'package:casama_api/src/model/gallery_input.dart';
import 'package:casama_api/src/model/pack_source.dart';
import 'package:casama_api/src/model/pack_app_preview.dart';
import 'package:casama_api/src/model/pack_routine_preview.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackPreview {
  /// Returns a new [PackPreview] instance.
  PackPreview({

    required  this.name,

    required  this.title,

    required  this.version,

    required  this.description,

    required  this.summary,

    required  this.icon,

    required  this.author,

    required  this.license,

    required  this.homepage,

    required  this.source_,

    required  this.commit,

    required  this.reviewed,

    required  this.bots,

    required  this.routines,

    required  this.skills,

    required  this.apps,

    required  this.looks,

    required  this.includes,

    required  this.servers,

    required  this.secrets,

    required  this.settings,

    required  this.inputs,

    required  this.needsApps,

    required  this.examples,

    required  this.reach,

    required  this.warnings,

    required  this.installed,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// The name people see; `name` is the pack's identity
  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



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
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: false,
  )


  final String icon;



  @JsonKey(
    
    name: r'author',
    required: true,
    includeIfNull: true,
  )


  final String? author;



  @JsonKey(
    
    name: r'license',
    required: true,
    includeIfNull: true,
  )


  final String? license;



  @JsonKey(
    
    name: r'homepage',
    required: true,
    includeIfNull: true,
  )


  final String? homepage;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final PackSource source_;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: true,
  )


  final String? commit;



  @JsonKey(
    
    name: r'reviewed',
    required: true,
    includeIfNull: false,
  )


  final bool reviewed;



  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final List<PackBotPreview> bots;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final List<PackRoutinePreview> routines;



  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final List<PackSkillPreview> skills;



  @JsonKey(
    
    name: r'apps',
    required: true,
    includeIfNull: false,
  )


  final List<PackAppPreview> apps;



  @JsonKey(
    
    name: r'looks',
    required: true,
    includeIfNull: false,
  )


  final List<PackLookPreview> looks;



  @JsonKey(
    
    name: r'includes',
    required: true,
    includeIfNull: false,
  )


  final List<PackIncludePreview> includes;



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
    
    name: r'settings',
    required: true,
    includeIfNull: false,
  )


  final List<PluginSettingInfo> settings;



  @JsonKey(
    
    name: r'inputs',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryInput> inputs;



  @JsonKey(
    
    name: r'needs_apps',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryMissingAppsInner> needsApps;



  @JsonKey(
    
    name: r'examples',
    required: true,
    includeIfNull: false,
  )


  final List<String> examples;



  @JsonKey(
    
    name: r'reach',
    required: true,
    includeIfNull: false,
  )


  final PackReach reach;



  @JsonKey(
    
    name: r'warnings',
    required: true,
    includeIfNull: false,
  )


  final List<String> warnings;



  @JsonKey(
    
    name: r'installed',
    required: true,
    includeIfNull: true,
  )


  final PackPreviewInstalled? installed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackPreview &&
      other.name == name &&
      other.title == title &&
      other.version == version &&
      other.description == description &&
      other.summary == summary &&
      other.icon == icon &&
      other.author == author &&
      other.license == license &&
      other.homepage == homepage &&
      other.source_ == source_ &&
      other.commit == commit &&
      other.reviewed == reviewed &&
      other.bots == bots &&
      other.routines == routines &&
      other.skills == skills &&
      other.apps == apps &&
      other.looks == looks &&
      other.includes == includes &&
      other.servers == servers &&
      other.secrets == secrets &&
      other.settings == settings &&
      other.inputs == inputs &&
      other.needsApps == needsApps &&
      other.examples == examples &&
      other.reach == reach &&
      other.warnings == warnings &&
      other.installed == installed;

    @override
    int get hashCode =>
        name.hashCode +
        title.hashCode +
        (version == null ? 0 : version.hashCode) +
        description.hashCode +
        summary.hashCode +
        icon.hashCode +
        (author == null ? 0 : author.hashCode) +
        (license == null ? 0 : license.hashCode) +
        (homepage == null ? 0 : homepage.hashCode) +
        source_.hashCode +
        (commit == null ? 0 : commit.hashCode) +
        reviewed.hashCode +
        bots.hashCode +
        routines.hashCode +
        skills.hashCode +
        apps.hashCode +
        looks.hashCode +
        includes.hashCode +
        servers.hashCode +
        secrets.hashCode +
        settings.hashCode +
        inputs.hashCode +
        needsApps.hashCode +
        examples.hashCode +
        reach.hashCode +
        warnings.hashCode +
        (installed == null ? 0 : installed.hashCode);

  factory PackPreview.fromJson(Map<String, dynamic> json) => _$PackPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

