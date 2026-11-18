//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

/// computer: a computer used for bots (a local device, D-066); source: a device that shares data (D-149)
enum DevicePermissionType {
          /// computer: a computer used for bots (a local device, D-066); source: a device that shares data (D-149)
      @JsonValue(r'computer')
      computer(r'computer'),
          /// computer: a computer used for bots (a local device, D-066); source: a device that shares data (D-149)
      @JsonValue(r'source')
      source_(r'source');

  const DevicePermissionType(this.value);

  final String value;

  @override
  String toString() => value;
}
