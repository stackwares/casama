//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/routine_trigger.dart';
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

    required  this.notify,

    required  this.enabled,

    required  this.nextRunAt,

    required  this.lastRunAt,

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
      other.notify == notify &&
      other.enabled == enabled &&
      other.nextRunAt == nextRunAt &&
      other.lastRunAt == lastRunAt &&
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
        notify.hashCode +
        enabled.hashCode +
        (nextRunAt == null ? 0 : nextRunAt.hashCode) +
        (lastRunAt == null ? 0 : lastRunAt.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        createdAt.hashCode;

  factory Routine.fromJson(Map<String, dynamic> json) => _$RoutineFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

