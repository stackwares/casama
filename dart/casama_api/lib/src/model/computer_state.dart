//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ComputerState {
      @JsonValue(r'provisioning')
      provisioning(r'provisioning'),
      @JsonValue(r'starting')
      starting(r'starting'),
      @JsonValue(r'running')
      running(r'running'),
      @JsonValue(r'idle')
      idle(r'idle'),
      @JsonValue(r'sleeping')
      sleeping(r'sleeping'),
      @JsonValue(r'stopped')
      stopped(r'stopped'),
      @JsonValue(r'error')
      error(r'error');

  const ComputerState(this.value);

  final String value;

  @override
  String toString() => value;
}
