//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ReportTargetKind {
      @JsonValue(r'gallery_item')
      galleryItem(r'gallery_item'),
      @JsonValue(r'bot')
      bot(r'bot'),
      @JsonValue(r'message')
      message(r'message'),
      @JsonValue(r'user')
      user(r'user'),
      @JsonValue(r'workspace')
      workspace(r'workspace');

  const ReportTargetKind(this.value);

  final String value;

  @override
  String toString() => value;
}
