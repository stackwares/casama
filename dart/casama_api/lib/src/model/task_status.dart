//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum TaskStatus {
      @JsonValue(r'todo')
      todo(r'todo'),
      @JsonValue(r'in_progress')
      inProgress(r'in_progress'),
      @JsonValue(r'in_review')
      inReview(r'in_review'),
      @JsonValue(r'blocked')
      blocked(r'blocked'),
      @JsonValue(r'done')
      done(r'done');

  const TaskStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
