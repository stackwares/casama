//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_permission_needed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DevicePermissionNeededEventPayload {
  /// Returns a new [DevicePermissionNeededEventPayload] instance.
  DevicePermissionNeededEventPayload({

    required  this.deviceRef,

    required  this.deviceName,

    required  this.platform,

    required  this.permissions,

    required  this.reason,

    required  this.botId,
  });

  @JsonKey(
    
    name: r'device_ref',
    required: true,
    includeIfNull: false,
  )


  final String deviceRef;



  @JsonKey(
    
    name: r'device_name',
    required: true,
    includeIfNull: false,
  )


  final String deviceName;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final String platform;



  @JsonKey(
    
    name: r'permissions',
    required: true,
    includeIfNull: false,
  )


  final List<String> permissions;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DevicePermissionNeededEventPayload &&
      other.deviceRef == deviceRef &&
      other.deviceName == deviceName &&
      other.platform == platform &&
      other.permissions == permissions &&
      other.reason == reason &&
      other.botId == botId;

    @override
    int get hashCode =>
        deviceRef.hashCode +
        deviceName.hashCode +
        platform.hashCode +
        permissions.hashCode +
        reason.hashCode +
        botId.hashCode;

  factory DevicePermissionNeededEventPayload.fromJson(Map<String, dynamic> json) => _$DevicePermissionNeededEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePermissionNeededEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

