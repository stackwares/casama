//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_trigger_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceTriggerConfig {
  /// Returns a new [DeviceTriggerConfig] instance.
  DeviceTriggerConfig({

    required  this.event,

     this.place,

     this.app,

     this.minutesBefore,
  });

  @JsonKey(
    
    name: r'event',
    required: true,
    includeIfNull: false,
  )


  final DeviceTriggerConfigEventEnum event;



      /// arrive and leave: a named place (Home, Work, Gym)
  @JsonKey(
    
    name: r'place',
    required: false,
    includeIfNull: false,
  )


  final String? place;



      /// notification: the watched app (its name or package id)
  @JsonKey(
    
    name: r'app',
    required: false,
    includeIfNull: false,
  )


  final String? app;



      /// leave_now: extra minutes on top of the travel time (default 5)
          // minimum: 0
          // maximum: 120
  @JsonKey(
    
    name: r'minutes_before',
    required: false,
    includeIfNull: false,
  )


  final int? minutesBefore;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceTriggerConfig &&
      other.event == event &&
      other.place == place &&
      other.app == app &&
      other.minutesBefore == minutesBefore;

    @override
    int get hashCode =>
        event.hashCode +
        place.hashCode +
        app.hashCode +
        minutesBefore.hashCode;

  factory DeviceTriggerConfig.fromJson(Map<String, dynamic> json) => _$DeviceTriggerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTriggerConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceTriggerConfigEventEnum {
@JsonValue(r'wake')
wake(r'wake'),
@JsonValue(r'arrive')
arrive(r'arrive'),
@JsonValue(r'leave')
leave(r'leave'),
@JsonValue(r'leave_now')
leaveNow(r'leave_now'),
@JsonValue(r'workout_ended')
workoutEnded(r'workout_ended'),
@JsonValue(r'notification')
notification(r'notification'),
@JsonValue(r'focus_on')
focusOn(r'focus_on'),
@JsonValue(r'focus_off')
focusOff(r'focus_off');

const DeviceTriggerConfigEventEnum(this.value);

final String value;

@override
String toString() => value;
}


