//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// schedule repeats on a cron; once runs a single time at run_at
enum RoutineTrigger {
          /// schedule repeats on a cron; once runs a single time at run_at
      @JsonValue(r'schedule')
      schedule(r'schedule'),
          /// schedule repeats on a cron; once runs a single time at run_at
      @JsonValue(r'once')
      once(r'once'),
          /// schedule repeats on a cron; once runs a single time at run_at
      @JsonValue(r'github')
      github(r'github'),
          /// schedule repeats on a cron; once runs a single time at run_at
      @JsonValue(r'webhook')
      webhook(r'webhook');

  const RoutineTrigger(this.value);

  final String value;

  @override
  String toString() => value;
}
