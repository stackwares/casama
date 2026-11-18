//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum SiteKind {
      @JsonValue(r'banking')
      banking(r'banking'),
      @JsonValue(r'health')
      health(r'health'),
      @JsonValue(r'passwords')
      passwords(r'passwords'),
      @JsonValue(r'government')
      government(r'government');

  const SiteKind(this.value);

  final String value;

  @override
  String toString() => value;
}
