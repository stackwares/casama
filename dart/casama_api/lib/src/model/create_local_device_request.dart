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

     this.system,

     this.clientId,
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



      /// Required for platform \"app\"
  @JsonKey(
    
    name: r'system',
    required: false,
    includeIfNull: false,
  )


  final CreateLocalDeviceRequestSystemEnum? system;



      /// Required for platform \"app\": the id this app install reports its open chat with (chat focus), so a bot can use the browser only while its chat is on this phone's screen
  @JsonKey(
    
    name: r'client_id',
    required: false,
    includeIfNull: false,
  )


  final String? clientId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateLocalDeviceRequest &&
      other.orgId == orgId &&
      other.name == name &&
      other.platform == platform &&
      other.system == system &&
      other.clientId == clientId;

    @override
    int get hashCode =>
        orgId.hashCode +
        name.hashCode +
        platform.hashCode +
        system.hashCode +
        clientId.hashCode;

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
linux(r'linux'),
@JsonValue(r'chrome')
chrome(r'chrome'),
@JsonValue(r'app')
app(r'app');

const CreateLocalDeviceRequestPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


/// Required for platform \"app\"
enum CreateLocalDeviceRequestSystemEnum {
    /// Required for platform \"app\"
@JsonValue(r'ios')
ios(r'ios'),
    /// Required for platform \"app\"
@JsonValue(r'android')
android(r'android');

const CreateLocalDeviceRequestSystemEnum(this.value);

final String value;

@override
String toString() => value;
}


