//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/save_device_source_request_kinds.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_device_source_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveDeviceSourceRequest {
  /// Returns a new [SaveDeviceSourceRequest] instance.
  SaveDeviceSourceRequest({

    required  this.name,

    required  this.platform,

    required  this.kinds,
  });

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


  final SaveDeviceSourceRequestPlatformEnum platform;



  @JsonKey(
    
    name: r'kinds',
    required: true,
    includeIfNull: false,
  )


  final SaveDeviceSourceRequestKinds kinds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveDeviceSourceRequest &&
      other.name == name &&
      other.platform == platform &&
      other.kinds == kinds;

    @override
    int get hashCode =>
        name.hashCode +
        platform.hashCode +
        kinds.hashCode;

  factory SaveDeviceSourceRequest.fromJson(Map<String, dynamic> json) => _$SaveDeviceSourceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveDeviceSourceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SaveDeviceSourceRequestPlatformEnum {
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

const SaveDeviceSourceRequestPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


