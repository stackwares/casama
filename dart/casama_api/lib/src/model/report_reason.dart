//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ReportReason {
      @JsonValue(r'spam')
      spam(r'spam'),
      @JsonValue(r'sexual')
      sexual(r'sexual'),
      @JsonValue(r'violence')
      violence(r'violence'),
      @JsonValue(r'harassment')
      harassment(r'harassment'),
      @JsonValue(r'illegal')
      illegal(r'illegal'),
      @JsonValue(r'impersonation')
      impersonation(r'impersonation'),
      @JsonValue(r'other')
      other(r'other');

  const ReportReason(this.value);

  final String value;

  @override
  String toString() => value;
}
