//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/local_capabilities.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_local_device_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateLocalDeviceRequest {
  /// Returns a new [UpdateLocalDeviceRequest] instance.
  UpdateLocalDeviceRequest({

     this.name,

     this.capabilities,

     this.allowedRoots,

     this.allowedBotIds,

     this.enabled,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'capabilities',
    required: false,
    includeIfNull: false,
  )


  final LocalCapabilities? capabilities;



  @JsonKey(
    
    name: r'allowed_roots',
    required: false,
    includeIfNull: false,
  )


  final List<String>? allowedRoots;



  @JsonKey(
    
    name: r'allowed_bot_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? allowedBotIds;



  @JsonKey(
    
    name: r'enabled',
    required: false,
    includeIfNull: false,
  )


  final bool? enabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateLocalDeviceRequest &&
      other.name == name &&
      other.capabilities == capabilities &&
      other.allowedRoots == allowedRoots &&
      other.allowedBotIds == allowedBotIds &&
      other.enabled == enabled;

    @override
    int get hashCode =>
        name.hashCode +
        capabilities.hashCode +
        allowedRoots.hashCode +
        allowedBotIds.hashCode +
        enabled.hashCode;

  factory UpdateLocalDeviceRequest.fromJson(Map<String, dynamic> json) => _$UpdateLocalDeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateLocalDeviceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

