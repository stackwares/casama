//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/plugin_preview.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_update_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginUpdatePreview {
  /// Returns a new [PluginUpdatePreview] instance.
  PluginUpdatePreview({

    required  this.upToDate,

    required  this.fromCommit,

    required  this.toCommit,

    required  this.fromVersion,

    required  this.toVersion,

    required  this.skillsAdded,

    required  this.skillsRemoved,

    required  this.skillsChanged,

    required  this.serversAdded,

    required  this.serversRemoved,

    required  this.serversChanged,

    required  this.hostsAdded,

    required  this.secretsAdded,

    required  this.preview,
  });

  @JsonKey(
    
    name: r'up_to_date',
    required: true,
    includeIfNull: false,
  )


  final bool upToDate;



  @JsonKey(
    
    name: r'from_commit',
    required: true,
    includeIfNull: false,
  )


  final String fromCommit;



  @JsonKey(
    
    name: r'to_commit',
    required: true,
    includeIfNull: false,
  )


  final String toCommit;



  @JsonKey(
    
    name: r'from_version',
    required: true,
    includeIfNull: true,
  )


  final String? fromVersion;



  @JsonKey(
    
    name: r'to_version',
    required: true,
    includeIfNull: true,
  )


  final String? toVersion;



  @JsonKey(
    
    name: r'skills_added',
    required: true,
    includeIfNull: false,
  )


  final List<String> skillsAdded;



  @JsonKey(
    
    name: r'skills_removed',
    required: true,
    includeIfNull: false,
  )


  final List<String> skillsRemoved;



  @JsonKey(
    
    name: r'skills_changed',
    required: true,
    includeIfNull: false,
  )


  final List<String> skillsChanged;



  @JsonKey(
    
    name: r'servers_added',
    required: true,
    includeIfNull: false,
  )


  final List<String> serversAdded;



  @JsonKey(
    
    name: r'servers_removed',
    required: true,
    includeIfNull: false,
  )


  final List<String> serversRemoved;



  @JsonKey(
    
    name: r'servers_changed',
    required: true,
    includeIfNull: false,
  )


  final List<String> serversChanged;



  @JsonKey(
    
    name: r'hosts_added',
    required: true,
    includeIfNull: false,
  )


  final List<String> hostsAdded;



  @JsonKey(
    
    name: r'secrets_added',
    required: true,
    includeIfNull: false,
  )


  final List<String> secretsAdded;



  @JsonKey(
    
    name: r'preview',
    required: true,
    includeIfNull: false,
  )


  final PluginPreview preview;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginUpdatePreview &&
      other.upToDate == upToDate &&
      other.fromCommit == fromCommit &&
      other.toCommit == toCommit &&
      other.fromVersion == fromVersion &&
      other.toVersion == toVersion &&
      other.skillsAdded == skillsAdded &&
      other.skillsRemoved == skillsRemoved &&
      other.skillsChanged == skillsChanged &&
      other.serversAdded == serversAdded &&
      other.serversRemoved == serversRemoved &&
      other.serversChanged == serversChanged &&
      other.hostsAdded == hostsAdded &&
      other.secretsAdded == secretsAdded &&
      other.preview == preview;

    @override
    int get hashCode =>
        upToDate.hashCode +
        fromCommit.hashCode +
        toCommit.hashCode +
        (fromVersion == null ? 0 : fromVersion.hashCode) +
        (toVersion == null ? 0 : toVersion.hashCode) +
        skillsAdded.hashCode +
        skillsRemoved.hashCode +
        skillsChanged.hashCode +
        serversAdded.hashCode +
        serversRemoved.hashCode +
        serversChanged.hashCode +
        hostsAdded.hashCode +
        secretsAdded.hashCode +
        preview.hashCode;

  factory PluginUpdatePreview.fromJson(Map<String, dynamic> json) => _$PluginUpdatePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PluginUpdatePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

