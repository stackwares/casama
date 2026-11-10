//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/skill_stats_revisions_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_stats.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillStats {
  /// Returns a new [SkillStats] instance.
  SkillStats({

    required  this.uses,

    required  this.successes,

    required  this.failures,

    required  this.corrections,

    required  this.successRate,

    required  this.lastFailureAt,

    required  this.lastFailureRunId,

    required  this.revisions,
  });

  @JsonKey(
    
    name: r'uses',
    required: true,
    includeIfNull: false,
  )


  final int uses;



  @JsonKey(
    
    name: r'successes',
    required: true,
    includeIfNull: false,
  )


  final int successes;



  @JsonKey(
    
    name: r'failures',
    required: true,
    includeIfNull: false,
  )


  final int failures;



  @JsonKey(
    
    name: r'corrections',
    required: true,
    includeIfNull: false,
  )


  final int corrections;



  @JsonKey(
    
    name: r'success_rate',
    required: true,
    includeIfNull: true,
  )


  final num? successRate;



  @JsonKey(
    
    name: r'last_failure_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastFailureAt;



  @JsonKey(
    
    name: r'last_failure_run_id',
    required: true,
    includeIfNull: true,
  )


  final String? lastFailureRunId;



  @JsonKey(
    
    name: r'revisions',
    required: true,
    includeIfNull: false,
  )


  final List<SkillStatsRevisionsInner> revisions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillStats &&
      other.uses == uses &&
      other.successes == successes &&
      other.failures == failures &&
      other.corrections == corrections &&
      other.successRate == successRate &&
      other.lastFailureAt == lastFailureAt &&
      other.lastFailureRunId == lastFailureRunId &&
      other.revisions == revisions;

    @override
    int get hashCode =>
        uses.hashCode +
        successes.hashCode +
        failures.hashCode +
        corrections.hashCode +
        (successRate == null ? 0 : successRate.hashCode) +
        (lastFailureAt == null ? 0 : lastFailureAt.hashCode) +
        (lastFailureRunId == null ? 0 : lastFailureRunId.hashCode) +
        revisions.hashCode;

  factory SkillStats.fromJson(Map<String, dynamic> json) => _$SkillStatsFromJson(json);

  Map<String, dynamic> toJson() => _$SkillStatsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

