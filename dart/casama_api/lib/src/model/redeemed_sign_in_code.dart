//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeemed_sign_in_code.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemedSignInCode {
  /// Returns a new [RedeemedSignInCode] instance.
  RedeemedSignInCode({

    required  this.tokenHash,

    required  this.email,
  });

      /// Finish with Auth's verify (type magiclink) to get this device its own session
  @JsonKey(
    
    name: r'token_hash',
    required: true,
    includeIfNull: false,
  )


  final String tokenHash;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemedSignInCode &&
      other.tokenHash == tokenHash &&
      other.email == email;

    @override
    int get hashCode =>
        tokenHash.hashCode +
        email.hashCode;

  factory RedeemedSignInCode.fromJson(Map<String, dynamic> json) => _$RedeemedSignInCodeFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemedSignInCodeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

