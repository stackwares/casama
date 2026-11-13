//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum CreationKind {
      @JsonValue(r'page')
      page(r'page'),
      @JsonValue(r'image')
      image(r'image'),
      @JsonValue(r'video')
      video(r'video'),
      @JsonValue(r'audio')
      audio(r'audio'),
      @JsonValue(r'document')
      document(r'document'),
      @JsonValue(r'file')
      file(r'file');

  const CreationKind(this.value);

  final String value;

  @override
  String toString() => value;
}
