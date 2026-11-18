//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_kind_settings.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_source.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceSource {
  /// Returns a new [DeviceSource] instance.
  DeviceSource({

    required  this.id,

    required  this.deviceKey,

    required  this.name,

    required  this.platform,

    required  this.kinds,

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
    
    name: r'device_key',
    required: true,
    includeIfNull: false,
  )


  final String deviceKey;



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


  final DeviceSourcePlatformEnum platform;



  @JsonKey(
    
    name: r'kinds',
    required: true,
    includeIfNull: false,
  )


  final Map<String, DeviceKindSettings> kinds;



  @JsonKey(
    
    name: r'last_seen_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime lastSeenAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceSource &&
      other.id == id &&
      other.deviceKey == deviceKey &&
      other.name == name &&
      other.platform == platform &&
      other.kinds == kinds &&
      other.lastSeenAt == lastSeenAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        deviceKey.hashCode +
        name.hashCode +
        platform.hashCode +
        kinds.hashCode +
        lastSeenAt.hashCode +
        createdAt.hashCode;

  factory DeviceSource.fromJson(Map<String, dynamic> json) => _$DeviceSourceFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceSourcePlatformEnum {
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android'),
@JsonValue(r'macos')
macos(r'macos'),
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux'),
@JsonValue(r'web')
web(r'web');

const DeviceSourcePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


