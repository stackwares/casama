//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/local_capabilities.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_device.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalDevice {
  /// Returns a new [LocalDevice] instance.
  LocalDevice({

    required  this.id,

    required  this.orgId,

    required  this.userId,

    required  this.computerId,

    required  this.name,

    required  this.platform,

     this.osVersion,

    required  this.capabilities,

    required  this.allowedRoots,

    required  this.allowedBotIds,

    required  this.enabled,

    required  this.online,

    required  this.lastSeenAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: false,
  )


  final String userId;



  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: true,
  )


  final String? computerId;



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


  final LocalDevicePlatformEnum platform;



      /// What the desktop app reported when it last connected, e.g. \"macOS 26.2\"
  @JsonKey(
    
    name: r'os_version',
    required: false,
    includeIfNull: false,
  )


  final String? osVersion;



  @JsonKey(
    
    name: r'capabilities',
    required: true,
    includeIfNull: false,
  )


  final LocalCapabilities capabilities;



  @JsonKey(
    
    name: r'allowed_roots',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedRoots;



  @JsonKey(
    
    name: r'allowed_bot_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedBotIds;



  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



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
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalDevice &&
      other.id == id &&
      other.orgId == orgId &&
      other.userId == userId &&
      other.computerId == computerId &&
      other.name == name &&
      other.platform == platform &&
      other.osVersion == osVersion &&
      other.capabilities == capabilities &&
      other.allowedRoots == allowedRoots &&
      other.allowedBotIds == allowedBotIds &&
      other.enabled == enabled &&
      other.online == online &&
      other.lastSeenAt == lastSeenAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        userId.hashCode +
        (computerId == null ? 0 : computerId.hashCode) +
        name.hashCode +
        platform.hashCode +
        (osVersion == null ? 0 : osVersion.hashCode) +
        capabilities.hashCode +
        allowedRoots.hashCode +
        allowedBotIds.hashCode +
        enabled.hashCode +
        online.hashCode +
        (lastSeenAt == null ? 0 : lastSeenAt.hashCode) +
        createdAt.hashCode;

  factory LocalDevice.fromJson(Map<String, dynamic> json) => _$LocalDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$LocalDeviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum LocalDevicePlatformEnum {
@JsonValue(r'macos')
macos(r'macos'),
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux');

const LocalDevicePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


