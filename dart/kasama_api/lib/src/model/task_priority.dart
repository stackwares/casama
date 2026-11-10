//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum TaskPriority {
      @JsonValue(r'urgent')
      urgent(r'urgent'),
      @JsonValue(r'high')
      high(r'high'),
      @JsonValue(r'medium')
      medium(r'medium'),
      @JsonValue(r'low')
      low(r'low'),
      @JsonValue(r'none')
      none(r'none');

  const TaskPriority(this.value);

  final String value;

  @override
  String toString() => value;
}
