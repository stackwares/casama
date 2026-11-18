//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/glance_routine.dart';
import 'package:casama_api/src/model/glance_creation.dart';
import 'package:casama_api/src/model/glance_flags.dart';
import 'package:casama_api/src/model/glance_starter.dart';
import 'package:casama_api/src/model/glance_run.dart';
import 'package:casama_api/src/model/glance_credits.dart';
import 'package:casama_api/src/model/glance_done.dart';
import 'package:casama_api/src/model/glance_routine_choice.dart';
import 'package:casama_api/src/model/glance_brief.dart';
import 'package:casama_api/src/model/glance_needs.dart';
import 'package:casama_api/src/model/glance_tasks.dart';
import 'package:casama_api/src/model/glance_bot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Glance {
  /// Returns a new [Glance] instance.
  Glance({

    required  this.version,

    required  this.madeAt,

    required  this.orgId,

    required  this.needs,

    required  this.bots,

    required  this.runs,

    required  this.next,

    required  this.routines,

    required  this.brief,

    required  this.lately,

    required  this.recent,

    required  this.tasks,

    required  this.credits,

    required  this.starters,

    required  this.flags,
  });

  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final String version;



  @JsonKey(
    
    name: r'made_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime madeAt;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'needs',
    required: true,
    includeIfNull: false,
  )


  final GlanceNeeds needs;



  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceBot> bots;



  @JsonKey(
    
    name: r'runs',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceRun> runs;



  @JsonKey(
    
    name: r'next',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceRoutine> next;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceRoutineChoice> routines;



  @JsonKey(
    
    name: r'brief',
    required: true,
    includeIfNull: true,
  )


  final GlanceBrief? brief;



  @JsonKey(
    
    name: r'lately',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceDone> lately;



  @JsonKey(
    
    name: r'recent',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceCreation> recent;



  @JsonKey(
    
    name: r'tasks',
    required: true,
    includeIfNull: false,
  )


  final GlanceTasks tasks;



  @JsonKey(
    
    name: r'credits',
    required: true,
    includeIfNull: false,
  )


  final GlanceCredits credits;



  @JsonKey(
    
    name: r'starters',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceStarter> starters;



  @JsonKey(
    
    name: r'flags',
    required: true,
    includeIfNull: false,
  )


  final GlanceFlags flags;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Glance &&
      other.version == version &&
      other.madeAt == madeAt &&
      other.orgId == orgId &&
      other.needs == needs &&
      other.bots == bots &&
      other.runs == runs &&
      other.next == next &&
      other.routines == routines &&
      other.brief == brief &&
      other.lately == lately &&
      other.recent == recent &&
      other.tasks == tasks &&
      other.credits == credits &&
      other.starters == starters &&
      other.flags == flags;

    @override
    int get hashCode =>
        version.hashCode +
        madeAt.hashCode +
        orgId.hashCode +
        needs.hashCode +
        bots.hashCode +
        runs.hashCode +
        next.hashCode +
        routines.hashCode +
        (brief == null ? 0 : brief.hashCode) +
        lately.hashCode +
        recent.hashCode +
        tasks.hashCode +
        credits.hashCode +
        starters.hashCode +
        flags.hashCode;

  factory Glance.fromJson(Map<String, dynamic> json) => _$GlanceFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

