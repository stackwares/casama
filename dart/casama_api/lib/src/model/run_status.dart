//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum RunStatus {
      @JsonValue(r'queued')
      queued(r'queued'),
      @JsonValue(r'running')
      running(r'running'),
      @JsonValue(r'waiting_approval')
      waitingApproval(r'waiting_approval'),
      @JsonValue(r'waiting_takeover')
      waitingTakeover(r'waiting_takeover'),
      @JsonValue(r'completed')
      completed(r'completed'),
      @JsonValue(r'failed')
      failed(r'failed'),
      @JsonValue(r'cancelled')
      cancelled(r'cancelled');

  const RunStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
