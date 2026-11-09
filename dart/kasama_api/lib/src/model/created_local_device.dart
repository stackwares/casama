//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/local_capabilities.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_local_device.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatedLocalDevice {
  /// Returns a new [CreatedLocalDevice] instance.
  CreatedLocalDevice({

    required  this.id,

    required  this.orgId,

    required  this.userId,

    required  this.computerId,

    required  this.name,

    required  this.platform,

    required  this.capabilities,

    required  this.allowedRoots,

    required  this.allowedBotIds,

    required  this.enabled,

    required  this.online,

    required  this.lastSeenAt,

    required  this.createdAt,

    required  this.token,
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


  final CreatedLocalDevicePlatformEnum platform;



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



      /// Device token, shown once; the app keeps it in secure storage
  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatedLocalDevice &&
      other.id == id &&
      other.orgId == orgId &&
      other.userId == userId &&
      other.computerId == computerId &&
      other.name == name &&
      other.platform == platform &&
      other.capabilities == capabilities &&
      other.allowedRoots == allowedRoots &&
      other.allowedBotIds == allowedBotIds &&
      other.enabled == enabled &&
      other.online == online &&
      other.lastSeenAt == lastSeenAt &&
      other.createdAt == createdAt &&
      other.token == token;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        userId.hashCode +
        (computerId == null ? 0 : computerId.hashCode) +
        name.hashCode +
        platform.hashCode +
        capabilities.hashCode +
        allowedRoots.hashCode +
        allowedBotIds.hashCode +
        enabled.hashCode +
        online.hashCode +
        (lastSeenAt == null ? 0 : lastSeenAt.hashCode) +
        createdAt.hashCode +
        token.hashCode;

  factory CreatedLocalDevice.fromJson(Map<String, dynamic> json) => _$CreatedLocalDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedLocalDeviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreatedLocalDevicePlatformEnum {
@JsonValue(r'macos')
macos(r'macos'),
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux');

const CreatedLocalDevicePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


