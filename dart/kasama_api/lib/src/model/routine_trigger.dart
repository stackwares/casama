//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum RoutineTrigger {
      @JsonValue(r'schedule')
      schedule(r'schedule'),
      @JsonValue(r'github')
      github(r'github'),
      @JsonValue(r'webhook')
      webhook(r'webhook');

  const RoutineTrigger(this.value);

  final String value;

  @override
  String toString() => value;
}
