//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum DeviceKind {
      @JsonValue(r'calendar')
      calendar(r'calendar'),
      @JsonValue(r'reminders')
      reminders(r'reminders'),
      @JsonValue(r'contacts')
      contacts(r'contacts'),
      @JsonValue(r'places')
      places(r'places'),
      @JsonValue(r'photos')
      photos(r'photos'),
      @JsonValue(r'health')
      health(r'health'),
      @JsonValue(r'notifications')
      notifications(r'notifications'),
      @JsonValue(r'activity')
      activity(r'activity');

  const DeviceKind(this.value);

  final String value;

  @override
  String toString() => value;
}
