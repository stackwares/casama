//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum GallerySubmissionKind {
      @JsonValue(r'theme')
      theme(r'theme'),
      @JsonValue(r'scheme')
      scheme(r'scheme'),
      @JsonValue(r'wallpaper')
      wallpaper(r'wallpaper'),
      @JsonValue(r'skill')
      skill(r'skill'),
      @JsonValue(r'routine')
      routine(r'routine'),
      @JsonValue(r'bot')
      bot(r'bot');

  const GallerySubmissionKind(this.value);

  final String value;

  @override
  String toString() => value;
}
