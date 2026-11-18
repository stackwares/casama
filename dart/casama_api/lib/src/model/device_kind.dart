//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
enum DeviceKind {
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'calendar')
      calendar(r'calendar'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'reminders')
      reminders(r'reminders'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'contacts')
      contacts(r'contacts'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'places')
      places(r'places'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'photos')
      photos(r'photos'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'health')
      health(r'health'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'notifications')
      notifications(r'notifications'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'activity')
      activity(r'activity'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'browser_tab')
      browserTab(r'browser_tab'),
          /// browser_tab and browser_history come from Casama for Chrome (platform web, D-323) and are live only: never stored
      @JsonValue(r'browser_history')
      browserHistory(r'browser_history');

  const DeviceKind(this.value);

  final String value;

  @override
  String toString() => value;
}
