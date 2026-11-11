//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum SearchKind {
      @JsonValue(r'message')
      message(r'message'),
      @JsonValue(r'chat')
      chat(r'chat'),
      @JsonValue(r'memory')
      memory(r'memory'),
      @JsonValue(r'skill')
      skill(r'skill'),
      @JsonValue(r'routine')
      routine(r'routine'),
      @JsonValue(r'ticket')
      ticket(r'ticket');

  const SearchKind(this.value);

  final String value;

  @override
  String toString() => value;
}
