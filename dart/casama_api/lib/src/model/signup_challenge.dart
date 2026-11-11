//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'signup_challenge.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupChallenge {
  /// Returns a new [SignupChallenge] instance.
  SignupChallenge({

    required  this.challenge,

    required  this.difficulty,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'challenge',
    required: true,
    includeIfNull: false,
  )


  final String challenge;



      /// Find a nonce so that sha256(`<challenge>:<nonce>`) starts with this many zero bits
  @JsonKey(
    
    name: r'difficulty',
    required: true,
    includeIfNull: false,
  )


  final int difficulty;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final String expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SignupChallenge &&
      other.challenge == challenge &&
      other.difficulty == difficulty &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        challenge.hashCode +
        difficulty.hashCode +
        expiresAt.hashCode;

  factory SignupChallenge.fromJson(Map<String, dynamic> json) => _$SignupChallengeFromJson(json);

  Map<String, dynamic> toJson() => _$SignupChallengeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

