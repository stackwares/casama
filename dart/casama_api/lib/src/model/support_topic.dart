//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum SupportTopic {
      @JsonValue(r'billing')
      billing(r'billing'),
      @JsonValue(r'broken')
      broken(r'broken'),
      @JsonValue(r'account')
      account(r'account'),
      @JsonValue(r'question')
      question(r'question'),
      @JsonValue(r'other')
      other(r'other');

  const SupportTopic(this.value);

  final String value;

  @override
  String toString() => value;
}
