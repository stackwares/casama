//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/calendar_trigger_config.dart';
import 'package:casama_api/src/model/message_trigger_config.dart';
import 'package:casama_api/src/model/routine_trigger.dart';
import 'package:casama_api/src/model/device_trigger_config.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Routine {
  /// Returns a new [Routine] instance.
  Routine({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.instructionsMd,

    required  this.scheduleCron,

    required  this.timezone,

    required  this.trigger,

     this.calendar,

     this.message,

     this.device,

    required  this.notify,

    required  this.enabled,

    required  this.nextRunAt,

    required  this.lastRunAt,

     this.endsAt,

     this.maxRuns,

     this.runCount,

    required  this.conversationId,

    required  this.createdAt,
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
    
    name: r'instructions_md',
    required: true,
    includeIfNull: false,
  )


  final String instructionsMd;



  @JsonKey(
    
    name: r'schedule_cron',
    required: true,
    includeIfNull: true,
  )


  final String? scheduleCron;



  @JsonKey(
    
    name: r'timezone',
    required: true,
    includeIfNull: false,
  )


  final String timezone;



  @JsonKey(
    
    name: r'trigger',
    required: true,
    includeIfNull: false,
  )


  final RoutineTrigger trigger;



  @JsonKey(
    
    name: r'calendar',
    required: false,
    includeIfNull: false,
  )


  final CalendarTriggerConfig? calendar;



  @JsonKey(
    
    name: r'message',
    required: false,
    includeIfNull: false,
  )


  final MessageTriggerConfig? message;



  @JsonKey(
    
    name: r'device',
    required: false,
    includeIfNull: false,
  )


  final DeviceTriggerConfig? device;



  @JsonKey(
    
    name: r'notify',
    required: true,
    includeIfNull: false,
  )


  final bool notify;



  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'next_run_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? nextRunAt;



  @JsonKey(
    
    name: r'last_run_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastRunAt;



      /// When it switches itself off for good (D-262)
  @JsonKey(
    
    name: r'ends_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? endsAt;



      /// How many runs before it switches itself off (D-262)
  @JsonKey(
    
    name: r'max_runs',
    required: false,
    includeIfNull: false,
  )


  final int? maxRuns;



      /// Runs that count toward max_runs (manual runs don't)
  @JsonKey(
    
    name: r'run_count',
    required: false,
    includeIfNull: false,
  )


  final int? runCount;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Routine &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.instructionsMd == instructionsMd &&
      other.scheduleCron == scheduleCron &&
      other.timezone == timezone &&
      other.trigger == trigger &&
      other.calendar == calendar &&
      other.message == message &&
      other.device == device &&
      other.notify == notify &&
      other.enabled == enabled &&
      other.nextRunAt == nextRunAt &&
      other.lastRunAt == lastRunAt &&
      other.endsAt == endsAt &&
      other.maxRuns == maxRuns &&
      other.runCount == runCount &&
      other.conversationId == conversationId &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        instructionsMd.hashCode +
        (scheduleCron == null ? 0 : scheduleCron.hashCode) +
        timezone.hashCode +
        trigger.hashCode +
        (calendar == null ? 0 : calendar.hashCode) +
        (message == null ? 0 : message.hashCode) +
        (device == null ? 0 : device.hashCode) +
        notify.hashCode +
        enabled.hashCode +
        (nextRunAt == null ? 0 : nextRunAt.hashCode) +
        (lastRunAt == null ? 0 : lastRunAt.hashCode) +
        (endsAt == null ? 0 : endsAt.hashCode) +
        (maxRuns == null ? 0 : maxRuns.hashCode) +
        runCount.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        createdAt.hashCode;

  factory Routine.fromJson(Map<String, dynamic> json) => _$RoutineFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

