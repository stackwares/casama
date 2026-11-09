//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ProviderId {
      @JsonValue(r'openai')
      openai(r'openai'),
      @JsonValue(r'anthropic')
      anthropic(r'anthropic'),
      @JsonValue(r'google')
      google(r'google'),
      @JsonValue(r'xai')
      xai(r'xai'),
      @JsonValue(r'openrouter')
      openrouter(r'openrouter'),
      @JsonValue(r'openai_compatible')
      openaiCompatible(r'openai_compatible');

  const ProviderId(this.value);

  final String value;

  @override
  String toString() => value;
}
