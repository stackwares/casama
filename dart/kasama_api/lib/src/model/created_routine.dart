//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/calendar_trigger_config.dart';
import 'package:kasama_api/src/model/routine_trigger.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_routine.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatedRoutine {
  /// Returns a new [CreatedRoutine] instance.
  CreatedRoutine({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.instructionsMd,

    required  this.scheduleCron,

    required  this.timezone,

    required  this.trigger,

     this.calendar,

    required  this.notify,

    required  this.enabled,

    required  this.nextRunAt,

    required  this.lastRunAt,

    required  this.conversationId,

    required  this.createdAt,

     this.webhookUrl,

     this.webhookSecret,
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



  @JsonKey(
    
    name: r'webhook_url',
    required: false,
    includeIfNull: false,
  )


  final String? webhookUrl;



      /// Shown once; sign requests with HMAC-SHA256
  @JsonKey(
    
    name: r'webhook_secret',
    required: false,
    includeIfNull: false,
  )


  final String? webhookSecret;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatedRoutine &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.instructionsMd == instructionsMd &&
      other.scheduleCron == scheduleCron &&
      other.timezone == timezone &&
      other.trigger == trigger &&
      other.calendar == calendar &&
      other.notify == notify &&
      other.enabled == enabled &&
      other.nextRunAt == nextRunAt &&
      other.lastRunAt == lastRunAt &&
      other.conversationId == conversationId &&
      other.createdAt == createdAt &&
      other.webhookUrl == webhookUrl &&
      other.webhookSecret == webhookSecret;

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
        notify.hashCode +
        enabled.hashCode +
        (nextRunAt == null ? 0 : nextRunAt.hashCode) +
        (lastRunAt == null ? 0 : lastRunAt.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        createdAt.hashCode +
        webhookUrl.hashCode +
        webhookSecret.hashCode;

  factory CreatedRoutine.fromJson(Map<String, dynamic> json) => _$CreatedRoutineFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedRoutineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

