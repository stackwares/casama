//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_device_challenge_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDeviceChallengeRequest {
  /// Returns a new [AdminDeviceChallengeRequest] instance.
  AdminDeviceChallengeRequest({

    required  this.keyId,
  });

  @JsonKey(
    
    name: r'key_id',
    required: true,
    includeIfNull: false,
  )


  final String keyId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDeviceChallengeRequest &&
      other.keyId == keyId;

    @override
    int get hashCode =>
        keyId.hashCode;

  factory AdminDeviceChallengeRequest.fromJson(Map<String, dynamic> json) => _$AdminDeviceChallengeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDeviceChallengeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

