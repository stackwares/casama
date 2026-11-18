//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/os_permission_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_device_permissions_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportDevicePermissionsRequest {
  /// Returns a new [ReportDevicePermissionsRequest] instance.
  ReportDevicePermissionsRequest({

    required  this.permissions,
  });

  @JsonKey(
    
    name: r'permissions',
    required: true,
    includeIfNull: false,
  )


  final Map<String, OsPermissionState> permissions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportDevicePermissionsRequest &&
      other.permissions == permissions;

    @override
    int get hashCode =>
        permissions.hashCode;

  factory ReportDevicePermissionsRequest.fromJson(Map<String, dynamic> json) => _$ReportDevicePermissionsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReportDevicePermissionsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

