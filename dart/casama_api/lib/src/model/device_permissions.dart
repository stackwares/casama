//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_permission_type.dart';
import 'package:casama_api/src/model/os_permission_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_permissions.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DevicePermissions {
  /// Returns a new [DevicePermissions] instance.
  DevicePermissions({

    required  this.deviceRef,

    required  this.type,

    required  this.id,

    required  this.name,

    required  this.platform,

    required  this.permissions,

    required  this.reportedAt,

    required  this.online,
  });

      /// `computer:<id>` or `source:<id>`
  @JsonKey(
    
    name: r'device_ref',
    required: true,
    includeIfNull: false,
  )


  final String deviceRef;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final DevicePermissionType type;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



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


  final Map<String, OsPermissionState> permissions;



  @JsonKey(
    
    name: r'reported_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? reportedAt;



  @JsonKey(
    
    name: r'online',
    required: true,
    includeIfNull: false,
  )


  final bool online;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DevicePermissions &&
      other.deviceRef == deviceRef &&
      other.type == type &&
      other.id == id &&
      other.name == name &&
      other.platform == platform &&
      other.permissions == permissions &&
      other.reportedAt == reportedAt &&
      other.online == online;

    @override
    int get hashCode =>
        deviceRef.hashCode +
        type.hashCode +
        id.hashCode +
        name.hashCode +
        platform.hashCode +
        permissions.hashCode +
        (reportedAt == null ? 0 : reportedAt.hashCode) +
        online.hashCode;

  factory DevicePermissions.fromJson(Map<String, dynamic> json) => _$DevicePermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePermissionsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

