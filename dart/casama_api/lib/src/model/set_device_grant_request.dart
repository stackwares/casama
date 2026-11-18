//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_device_grant_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetDeviceGrantRequest {
  /// Returns a new [SetDeviceGrantRequest] instance.
  SetDeviceGrantRequest({

    required  this.botId,

    required  this.kind,

    required  this.allowed,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final DeviceKind kind;



  @JsonKey(
    
    name: r'allowed',
    required: true,
    includeIfNull: false,
  )


  final bool allowed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetDeviceGrantRequest &&
      other.botId == botId &&
      other.kind == kind &&
      other.allowed == allowed;

    @override
    int get hashCode =>
        botId.hashCode +
        kind.hashCode +
        allowed.hashCode;

  factory SetDeviceGrantRequest.fromJson(Map<String, dynamic> json) => _$SetDeviceGrantRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetDeviceGrantRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

