//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
enum OsPermissionState {
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'granted')
      granted(r'granted'),
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'limited')
      limited(r'limited'),
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'denied')
      denied(r'denied'),
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'not_asked')
      notAsked(r'not_asked'),
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'restricted')
      restricted(r'restricted'),
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'unknown')
      unknown(r'unknown'),
          /// not_asked: the system would still prompt. limited: usable with limits (some photos, approximate location). unknown: can't tell without trying. unavailable: not on this device or build
      @JsonValue(r'unavailable')
      unavailable(r'unavailable');

  const OsPermissionState(this.value);

  final String value;

  @override
  String toString() => value;
}
