//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_item_ref.dart';
import 'package:casama_api/src/model/pack_kind_diff.dart';
import 'package:casama_api/src/model/pack_preview.dart';
import 'package:casama_api/src/model/pack_update_preview_runs_per_week.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_update_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackUpdatePreview {
  /// Returns a new [PackUpdatePreview] instance.
  PackUpdatePreview({

    required  this.upToDate,

    required  this.canCheck,

    required  this.fromCommit,

    required  this.toCommit,

    required  this.fromVersion,

    required  this.toVersion,

    required  this.bots,

    required  this.routines,

    required  this.skills,

    required  this.apps,

    required  this.looks,

    required  this.servers,

    required  this.hostsAdded,

    required  this.secretsAdded,

    required  this.schedulesChanged,

    required  this.runsPerWeek,

    required  this.reachGrew,

    required  this.edited,

     this.preview,
  });

  @JsonKey(
    
    name: r'up_to_date',
    required: true,
    includeIfNull: false,
  )


  final bool upToDate;



      /// False for a pack from a file or a link
  @JsonKey(
    
    name: r'can_check',
    required: true,
    includeIfNull: false,
  )


  final bool canCheck;



  @JsonKey(
    
    name: r'from_commit',
    required: true,
    includeIfNull: true,
  )


  final String? fromCommit;



  @JsonKey(
    
    name: r'to_commit',
    required: true,
    includeIfNull: true,
  )


  final String? toCommit;



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
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final PackKindDiff bots;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final PackKindDiff routines;



  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final PackKindDiff skills;



  @JsonKey(
    
    name: r'apps',
    required: true,
    includeIfNull: false,
  )


  final PackKindDiff apps;



  @JsonKey(
    
    name: r'looks',
    required: true,
    includeIfNull: false,
  )


  final PackKindDiff looks;



  @JsonKey(
    
    name: r'servers',
    required: true,
    includeIfNull: false,
  )


  final PackKindDiff servers;



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
    
    name: r'schedules_changed',
    required: true,
    includeIfNull: false,
  )


  final List<String> schedulesChanged;



  @JsonKey(
    
    name: r'runs_per_week',
    required: true,
    includeIfNull: false,
  )


  final PackUpdatePreviewRunsPerWeek runsPerWeek;



  @JsonKey(
    
    name: r'reach_grew',
    required: true,
    includeIfNull: false,
  )


  final bool reachGrew;



      /// Items the person changed: they stay theirs
  @JsonKey(
    
    name: r'edited',
    required: true,
    includeIfNull: false,
  )


  final List<PackItemRef> edited;



  @JsonKey(
    
    name: r'preview',
    required: false,
    includeIfNull: false,
  )


  final PackPreview? preview;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackUpdatePreview &&
      other.upToDate == upToDate &&
      other.canCheck == canCheck &&
      other.fromCommit == fromCommit &&
      other.toCommit == toCommit &&
      other.fromVersion == fromVersion &&
      other.toVersion == toVersion &&
      other.bots == bots &&
      other.routines == routines &&
      other.skills == skills &&
      other.apps == apps &&
      other.looks == looks &&
      other.servers == servers &&
      other.hostsAdded == hostsAdded &&
      other.secretsAdded == secretsAdded &&
      other.schedulesChanged == schedulesChanged &&
      other.runsPerWeek == runsPerWeek &&
      other.reachGrew == reachGrew &&
      other.edited == edited &&
      other.preview == preview;

    @override
    int get hashCode =>
        upToDate.hashCode +
        canCheck.hashCode +
        (fromCommit == null ? 0 : fromCommit.hashCode) +
        (toCommit == null ? 0 : toCommit.hashCode) +
        (fromVersion == null ? 0 : fromVersion.hashCode) +
        (toVersion == null ? 0 : toVersion.hashCode) +
        bots.hashCode +
        routines.hashCode +
        skills.hashCode +
        apps.hashCode +
        looks.hashCode +
        servers.hashCode +
        hostsAdded.hashCode +
        secretsAdded.hashCode +
        schedulesChanged.hashCode +
        runsPerWeek.hashCode +
        reachGrew.hashCode +
        edited.hashCode +
        preview.hashCode;

  factory PackUpdatePreview.fromJson(Map<String, dynamic> json) => _$PackUpdatePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackUpdatePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

