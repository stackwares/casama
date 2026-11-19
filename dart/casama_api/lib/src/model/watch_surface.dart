//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum WatchSurface {
      @JsonValue(r'app')
      app(r'app'),
      @JsonValue(r'notification')
      notification(r'notification'),
      @JsonValue(r'complication')
      complication(r'complication'),
      @JsonValue(r'smart_stack')
      smartStack(r'smart_stack'),
      @JsonValue(r'tile')
      tile(r'tile'),
      @JsonValue(r'control')
      control(r'control'),
      @JsonValue(r'siri')
      siri(r'siri');

  const WatchSurface(this.value);

  final String value;

  @override
  String toString() => value;
}
