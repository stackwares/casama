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
      openaiCompatible(r'openai_compatible'),
      @JsonValue(r'fal')
      fal(r'fal'),
      @JsonValue(r'brave_search')
      braveSearch(r'brave_search'),
      @JsonValue(r'tavily')
      tavily(r'tavily'),
      @JsonValue(r'deepgram')
      deepgram(r'deepgram'),
      @JsonValue(r'elevenlabs')
      elevenlabs(r'elevenlabs'),
      @JsonValue(r'cartesia')
      cartesia(r'cartesia'),
      @JsonValue(r'fish_audio')
      fishAudio(r'fish_audio'),
      @JsonValue(r'chatgpt')
      chatgpt(r'chatgpt'),
      @JsonValue(r'treg')
      treg(r'treg');

  const ProviderId(this.value);

  final String value;

  @override
  String toString() => value;
}
