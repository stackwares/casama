//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/local_capabilities.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_device.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerDevice {
  /// Returns a new [ComputerDevice] instance.
  ComputerDevice({

    required  this.platform,

    required  this.online,

    required  this.lastSeenAt,

    required  this.capabilities,
  });

  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final ComputerDevicePlatformEnum platform;



  @JsonKey(
    
    name: r'online',
    required: true,
    includeIfNull: false,
  )


  final bool online;



  @JsonKey(
    
    name: r'last_seen_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastSeenAt;



  @JsonKey(
    
    name: r'capabilities',
    required: true,
    includeIfNull: false,
  )


  final LocalCapabilities capabilities;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerDevice &&
      other.platform == platform &&
      other.online == online &&
      other.lastSeenAt == lastSeenAt &&
      other.capabilities == capabilities;

    @override
    int get hashCode =>
        platform.hashCode +
        online.hashCode +
        (lastSeenAt == null ? 0 : lastSeenAt.hashCode) +
        capabilities.hashCode;

  factory ComputerDevice.fromJson(Map<String, dynamic> json) => _$ComputerDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerDeviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ComputerDevicePlatformEnum {
@JsonValue(r'macos')
macos(r'macos'),
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux');

const ComputerDevicePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


