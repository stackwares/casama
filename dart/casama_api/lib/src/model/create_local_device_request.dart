//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_local_device_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateLocalDeviceRequest {
  /// Returns a new [CreateLocalDeviceRequest] instance.
  CreateLocalDeviceRequest({

    required  this.orgId,

    required  this.name,

    required  this.platform,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



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


  final CreateLocalDeviceRequestPlatformEnum platform;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateLocalDeviceRequest &&
      other.orgId == orgId &&
      other.name == name &&
      other.platform == platform;

    @override
    int get hashCode =>
        orgId.hashCode +
        name.hashCode +
        platform.hashCode;

  factory CreateLocalDeviceRequest.fromJson(Map<String, dynamic> json) => _$CreateLocalDeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateLocalDeviceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateLocalDeviceRequestPlatformEnum {
@JsonValue(r'macos')
macos(r'macos'),
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux');

const CreateLocalDeviceRequestPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


