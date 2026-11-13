//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_routine_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateRoutineRequest {
  /// Returns a new [UpdateRoutineRequest] instance.
  UpdateRoutineRequest({

     this.name,

     this.instructions,

     this.scheduleCron,

     this.runAt,

     this.timezone,

     this.notify,

     this.enabled,

     this.endsAt,

     this.maxRuns,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'instructions',
    required: false,
    includeIfNull: false,
  )


  final String? instructions;



      /// A once routine given a cron becomes a repeating one
  @JsonKey(
    
    name: r'schedule_cron',
    required: false,
    includeIfNull: false,
  )


  final String? scheduleCron;



      /// A repeating routine given run_at becomes a once one
  @JsonKey(
    
    name: r'run_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? runAt;



  @JsonKey(
    
    name: r'timezone',
    required: false,
    includeIfNull: false,
  )


  final String? timezone;



  @JsonKey(
    
    name: r'notify',
    required: false,
    includeIfNull: false,
  )


  final bool? notify;



  @JsonKey(
    
    name: r'enabled',
    required: false,
    includeIfNull: false,
  )


  final bool? enabled;



      /// When it switches itself off; null removes the end time
  @JsonKey(
    
    name: r'ends_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? endsAt;



      /// Runs left before it switches itself off, counted from now; null removes it
          // minimum: 1
          // maximum: 10000
  @JsonKey(
    
    name: r'max_runs',
    required: false,
    includeIfNull: false,
  )


  final int? maxRuns;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateRoutineRequest &&
      other.name == name &&
      other.instructions == instructions &&
      other.scheduleCron == scheduleCron &&
      other.runAt == runAt &&
      other.timezone == timezone &&
      other.notify == notify &&
      other.enabled == enabled &&
      other.endsAt == endsAt &&
      other.maxRuns == maxRuns;

    @override
    int get hashCode =>
        name.hashCode +
        instructions.hashCode +
        scheduleCron.hashCode +
        runAt.hashCode +
        timezone.hashCode +
        notify.hashCode +
        enabled.hashCode +
        (endsAt == null ? 0 : endsAt.hashCode) +
        (maxRuns == null ? 0 : maxRuns.hashCode);

  factory UpdateRoutineRequest.fromJson(Map<String, dynamic> json) => _$UpdateRoutineRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRoutineRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

