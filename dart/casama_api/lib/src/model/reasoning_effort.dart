//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// For reasoning models; the server default applies to the default model when unset
enum ReasoningEffort {
          /// For reasoning models; the server default applies to the default model when unset
      @JsonValue(r'none')
      none(r'none'),
          /// For reasoning models; the server default applies to the default model when unset
      @JsonValue(r'low')
      low(r'low'),
          /// For reasoning models; the server default applies to the default model when unset
      @JsonValue(r'medium')
      medium(r'medium'),
          /// For reasoning models; the server default applies to the default model when unset
      @JsonValue(r'high')
      high(r'high'),
          /// For reasoning models; the server default applies to the default model when unset
      @JsonValue(r'xhigh')
      xhigh(r'xhigh'),
          /// For reasoning models; the server default applies to the default model when unset
      @JsonValue(r'max')
      max(r'max');

  const ReasoningEffort(this.value);

  final String value;

  @override
  String toString() => value;
}
