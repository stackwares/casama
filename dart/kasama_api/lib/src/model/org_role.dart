//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum OrgRole {
      @JsonValue(r'owner')
      owner(r'owner'),
      @JsonValue(r'admin')
      admin(r'admin'),
      @JsonValue(r'member')
      member(r'member');

  const OrgRole(this.value);

  final String value;

  @override
  String toString() => value;
}
