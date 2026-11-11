//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// ok; plan_usage_off: signed in to ChatGPT without granting plan usage; needs_reconnect: sign in again
enum CredentialStatus {
          /// ok; plan_usage_off: signed in to ChatGPT without granting plan usage; needs_reconnect: sign in again
      @JsonValue(r'ok')
      ok(r'ok'),
          /// ok; plan_usage_off: signed in to ChatGPT without granting plan usage; needs_reconnect: sign in again
      @JsonValue(r'plan_usage_off')
      planUsageOff(r'plan_usage_off'),
          /// ok; plan_usage_off: signed in to ChatGPT without granting plan usage; needs_reconnect: sign in again
      @JsonValue(r'needs_reconnect')
      needsReconnect(r'needs_reconnect');

  const CredentialStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
