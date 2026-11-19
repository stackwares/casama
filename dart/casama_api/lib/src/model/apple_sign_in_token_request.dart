//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'apple_sign_in_token_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppleSignInTokenRequest {
  /// Returns a new [AppleSignInTokenRequest] instance.
  AppleSignInTokenRequest({

     this.authorizationCode,

     this.refreshToken,
  });

      /// The one-time authorization code from Apple's system sheet (iOS and macOS); the server swaps it for a refresh token
  @JsonKey(
    
    name: r'authorization_code',
    required: false,
    includeIfNull: false,
  )


  final String? authorizationCode;



      /// Apple's refresh token from the browser sign-in (Supabase Auth's provider_refresh_token)
  @JsonKey(
    
    name: r'refresh_token',
    required: false,
    includeIfNull: false,
  )


  final String? refreshToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppleSignInTokenRequest &&
      other.authorizationCode == authorizationCode &&
      other.refreshToken == refreshToken;

    @override
    int get hashCode =>
        authorizationCode.hashCode +
        refreshToken.hashCode;

  factory AppleSignInTokenRequest.fromJson(Map<String, dynamic> json) => _$AppleSignInTokenRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppleSignInTokenRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

