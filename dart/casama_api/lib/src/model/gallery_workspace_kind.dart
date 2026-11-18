//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum GalleryWorkspaceKind {
      @JsonValue(r'skill')
      skill(r'skill'),
      @JsonValue(r'app')
      app(r'app'),
      @JsonValue(r'bot')
      bot(r'bot'),
      @JsonValue(r'routine')
      routine(r'routine'),
      @JsonValue(r'plugin')
      plugin(r'plugin');

  const GalleryWorkspaceKind(this.value);

  final String value;

  @override
  String toString() => value;
}
