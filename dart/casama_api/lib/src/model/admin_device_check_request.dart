//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_device_check_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDeviceCheckRequest {
  /// Returns a new [AdminDeviceCheckRequest] instance.
  AdminDeviceCheckRequest({

    required  this.challengeId,

    required  this.signature,
  });

  @JsonKey(
    
    name: r'challenge_id',
    required: true,
    includeIfNull: false,
  )


  final String challengeId;



  @JsonKey(
    
    name: r'signature',
    required: true,
    includeIfNull: false,
  )


  final String signature;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDeviceCheckRequest &&
      other.challengeId == challengeId &&
      other.signature == signature;

    @override
    int get hashCode =>
        challengeId.hashCode +
        signature.hashCode;

  factory AdminDeviceCheckRequest.fromJson(Map<String, dynamic> json) => _$AdminDeviceCheckRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDeviceCheckRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

