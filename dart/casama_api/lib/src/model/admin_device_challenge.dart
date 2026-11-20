//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_device_challenge.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDeviceChallenge {
  /// Returns a new [AdminDeviceChallenge] instance.
  AdminDeviceChallenge({

    required  this.challengeId,

    required  this.challenge,
  });

  @JsonKey(
    
    name: r'challenge_id',
    required: true,
    includeIfNull: false,
  )


  final String challengeId;



  @JsonKey(
    
    name: r'challenge',
    required: true,
    includeIfNull: false,
  )


  final String challenge;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDeviceChallenge &&
      other.challengeId == challengeId &&
      other.challenge == challenge;

    @override
    int get hashCode =>
        challengeId.hashCode +
        challenge.hashCode;

  factory AdminDeviceChallenge.fromJson(Map<String, dynamic> json) => _$AdminDeviceChallengeFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDeviceChallengeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

