//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum UsageSource {
      @JsonValue(r'chat')
      chat(r'chat'),
      @JsonValue(r'chat_app')
      chatApp(r'chat_app'),
      @JsonValue(r'routine')
      routine(r'routine'),
      @JsonValue(r'api')
      api(r'api'),
      @JsonValue(r'other')
      other(r'other');

  const UsageSource(this.value);

  final String value;

  @override
  String toString() => value;
}
