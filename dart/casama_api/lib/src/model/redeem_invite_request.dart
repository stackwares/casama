//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/waitlist_proof.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeem_invite_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemInviteRequest {
  /// Returns a new [RedeemInviteRequest] instance.
  RedeemInviteRequest({

     this.email,

    required  this.code,

    required  this.proof,

     this.idToken,

     this.provider,

     this.tokenNonce,

     this.source_,

     this.newsletter,
  });

  @JsonKey(
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final String? email;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'proof',
    required: true,
    includeIfNull: false,
  )


  final WaitlistProof proof;



  @JsonKey(
    
    name: r'id_token',
    required: false,
    includeIfNull: false,
  )


  final String? idToken;



  @JsonKey(
    
    name: r'provider',
    required: false,
    includeIfNull: false,
  )


  final RedeemInviteRequestProviderEnum? provider;



  @JsonKey(
    
    name: r'token_nonce',
    required: false,
    includeIfNull: false,
  )


  final String? tokenNonce;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;



  @JsonKey(
    
    name: r'newsletter',
    required: false,
    includeIfNull: false,
  )


  final bool? newsletter;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemInviteRequest &&
      other.email == email &&
      other.code == code &&
      other.proof == proof &&
      other.idToken == idToken &&
      other.provider == provider &&
      other.tokenNonce == tokenNonce &&
      other.source_ == source_ &&
      other.newsletter == newsletter;

    @override
    int get hashCode =>
        email.hashCode +
        code.hashCode +
        proof.hashCode +
        idToken.hashCode +
        provider.hashCode +
        tokenNonce.hashCode +
        source_.hashCode +
        newsletter.hashCode;

  factory RedeemInviteRequest.fromJson(Map<String, dynamic> json) => _$RedeemInviteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemInviteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RedeemInviteRequestProviderEnum {
@JsonValue(r'apple')
apple(r'apple'),
@JsonValue(r'google')
google(r'google');

const RedeemInviteRequestProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


