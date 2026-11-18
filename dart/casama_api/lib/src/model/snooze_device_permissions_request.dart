//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'snooze_device_permissions_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SnoozeDevicePermissionsRequest {
  /// Returns a new [SnoozeDevicePermissionsRequest] instance.
  SnoozeDevicePermissionsRequest({

    required  this.botId,

    required  this.permissions,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'permissions',
    required: true,
    includeIfNull: false,
  )


  final List<String> permissions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SnoozeDevicePermissionsRequest &&
      other.botId == botId &&
      other.permissions == permissions;

    @override
    int get hashCode =>
        botId.hashCode +
        permissions.hashCode;

  factory SnoozeDevicePermissionsRequest.fromJson(Map<String, dynamic> json) => _$SnoozeDevicePermissionsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SnoozeDevicePermissionsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

