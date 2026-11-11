//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/calendar_trigger_config.dart';
import 'package:kasama_api/src/model/routine_trigger.dart';
import 'package:kasama_api/src/model/device_trigger_config.dart';
import 'package:kasama_api/src/model/message_trigger_config.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_routine_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateRoutineRequest {
  /// Returns a new [CreateRoutineRequest] instance.
  CreateRoutineRequest({

    required  this.botId,

    required  this.name,

    required  this.instructions,

     this.trigger,

     this.scheduleCron,

     this.runAt,

     this.timezone,

     this.notify,

     this.events,

     this.calendar,

     this.message,

     this.device,
  });

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
    
    name: r'instructions',
    required: true,
    includeIfNull: false,
  )


  final String instructions;



  @JsonKey(
    
    name: r'trigger',
    required: false,
    includeIfNull: false,
  )


  final RoutineTrigger? trigger;



      /// 5-field cron, required for schedule triggers
  @JsonKey(
    
    name: r'schedule_cron',
    required: false,
    includeIfNull: false,
  )


  final String? scheduleCron;



      /// When a once routine runs (it switches itself off afterwards)
  @JsonKey(
    
    name: r'run_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? runAt;



      /// IANA timezone; defaults to your profile's
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



      /// GitHub event names to accept
  @JsonKey(
    
    name: r'events',
    required: false,
    includeIfNull: false,
  )


  final List<String>? events;



      /// Required for calendar_event triggers
  @JsonKey(
    
    name: r'calendar',
    required: false,
    includeIfNull: false,
  )


  final CalendarTriggerConfig? calendar;



      /// Filters for message triggers: an email or chat message that matches starts the routine
  @JsonKey(
    
    name: r'message',
    required: false,
    includeIfNull: false,
  )


  final MessageTriggerConfig? message;



      /// Required for device triggers: the event on your own phone or computer
  @JsonKey(
    
    name: r'device',
    required: false,
    includeIfNull: false,
  )


  final DeviceTriggerConfig? device;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateRoutineRequest &&
      other.botId == botId &&
      other.name == name &&
      other.instructions == instructions &&
      other.trigger == trigger &&
      other.scheduleCron == scheduleCron &&
      other.runAt == runAt &&
      other.timezone == timezone &&
      other.notify == notify &&
      other.events == events &&
      other.calendar == calendar &&
      other.message == message &&
      other.device == device;

    @override
    int get hashCode =>
        botId.hashCode +
        name.hashCode +
        instructions.hashCode +
        trigger.hashCode +
        scheduleCron.hashCode +
        runAt.hashCode +
        timezone.hashCode +
        notify.hashCode +
        events.hashCode +
        (calendar == null ? 0 : calendar.hashCode) +
        (message == null ? 0 : message.hashCode) +
        (device == null ? 0 : device.hashCode);

  factory CreateRoutineRequest.fromJson(Map<String, dynamic> json) => _$CreateRoutineRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRoutineRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

