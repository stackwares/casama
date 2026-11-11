//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum Autonomy {
      @JsonValue(r'ask_always')
      askAlways(r'ask_always'),
      @JsonValue(r'ask_risky')
      askRisky(r'ask_risky'),
      @JsonValue(r'autonomous')
      autonomous(r'autonomous');

  const Autonomy(this.value);

  final String value;

  @override
  String toString() => value;
}
