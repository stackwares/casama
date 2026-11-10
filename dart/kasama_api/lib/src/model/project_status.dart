//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ProjectStatus {
      @JsonValue(r'planning')
      planning(r'planning'),
      @JsonValue(r'active')
      active(r'active'),
      @JsonValue(r'paused')
      paused(r'paused'),
      @JsonValue(r'blocked')
      blocked(r'blocked'),
      @JsonValue(r'done')
      done(r'done'),
      @JsonValue(r'cancelled')
      cancelled(r'cancelled');

  const ProjectStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
