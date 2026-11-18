//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/replay_param_info.dart';
import 'package:casama_api/src/model/replay_steps_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'replay.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Replay {
  /// Returns a new [Replay] instance.
  Replay({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.description,

    required  this.params,

    required  this.steps,

    required  this.source_,

    required  this.runs,

    required  this.failures,

    required  this.lastFailure,

    required  this.lastRunAt,

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
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'params',
    required: true,
    includeIfNull: false,
  )


  final List<ReplayParamInfo> params;



  @JsonKey(
    
    name: r'steps',
    required: true,
    includeIfNull: false,
  )


  final List<ReplayStepsInner> steps;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final ReplaySource_Enum source_;



  @JsonKey(
    
    name: r'runs',
    required: true,
    includeIfNull: false,
  )


  final int runs;



  @JsonKey(
    
    name: r'failures',
    required: true,
    includeIfNull: false,
  )


  final int failures;



  @JsonKey(
    
    name: r'last_failure',
    required: true,
    includeIfNull: true,
  )


  final String? lastFailure;



  @JsonKey(
    
    name: r'last_run_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastRunAt;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Replay &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.description == description &&
      other.params == params &&
      other.steps == steps &&
      other.source_ == source_ &&
      other.runs == runs &&
      other.failures == failures &&
      other.lastFailure == lastFailure &&
      other.lastRunAt == lastRunAt &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        description.hashCode +
        params.hashCode +
        steps.hashCode +
        source_.hashCode +
        runs.hashCode +
        failures.hashCode +
        (lastFailure == null ? 0 : lastFailure.hashCode) +
        (lastRunAt == null ? 0 : lastRunAt.hashCode) +
        updatedAt.hashCode;

  factory Replay.fromJson(Map<String, dynamic> json) => _$ReplayFromJson(json);

  Map<String, dynamic> toJson() => _$ReplayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ReplaySource_Enum {
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'teach')
teach(r'teach'),
@JsonValue(r'manual')
manual(r'manual');

const ReplaySource_Enum(this.value);

final String value;

@override
String toString() => value;
}


