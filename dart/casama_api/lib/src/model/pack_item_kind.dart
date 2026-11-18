//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum PackItemKind {
      @JsonValue(r'bot')
      bot(r'bot'),
      @JsonValue(r'skill')
      skill(r'skill'),
      @JsonValue(r'routine')
      routine(r'routine'),
      @JsonValue(r'app')
      app(r'app'),
      @JsonValue(r'look')
      look(r'look'),
      @JsonValue(r'tools')
      tools(r'tools'),
      @JsonValue(r'include')
      include(r'include');

  const PackItemKind(this.value);

  final String value;

  @override
  String toString() => value;
}
