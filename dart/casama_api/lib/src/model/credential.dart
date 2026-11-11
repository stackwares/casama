//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/provider_id.dart';
import 'package:casama_api/src/model/credential_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credential.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Credential {
  /// Returns a new [Credential] instance.
  Credential({

    required  this.id,

    required  this.orgId,

    required  this.provider,

    required  this.label,

    required  this.baseUrl,

    required  this.keyHint,

    required  this.lastTestedAt,

    required  this.lastTestOk,

    required  this.ownerUserId,

    required  this.status,

    required  this.account,

    required  this.fallbackOnLimit,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: false,
  )


  final ProviderId provider;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'base_url',
    required: true,
    includeIfNull: true,
  )


  final String? baseUrl;



      /// Last 4 characters of the key
  @JsonKey(
    
    name: r'key_hint',
    required: true,
    includeIfNull: true,
  )


  final String? keyHint;



  @JsonKey(
    
    name: r'last_tested_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastTestedAt;



  @JsonKey(
    
    name: r'last_test_ok',
    required: true,
    includeIfNull: true,
  )


  final bool? lastTestOk;



      /// Set for personal credentials (a ChatGPT plan): only the owner's runs use it
  @JsonKey(
    
    name: r'owner_user_id',
    required: true,
    includeIfNull: true,
  )


  final String? ownerUserId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final CredentialStatus status;



      /// The signed-in ChatGPT account's email (chatgpt only)
  @JsonKey(
    
    name: r'account',
    required: true,
    includeIfNull: true,
  )


  final String? account;



      /// chatgpt: use the bot's next model when the plan limit is reached
  @JsonKey(
    
    name: r'fallback_on_limit',
    required: true,
    includeIfNull: false,
  )


  final bool fallbackOnLimit;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Credential &&
      other.id == id &&
      other.orgId == orgId &&
      other.provider == provider &&
      other.label == label &&
      other.baseUrl == baseUrl &&
      other.keyHint == keyHint &&
      other.lastTestedAt == lastTestedAt &&
      other.lastTestOk == lastTestOk &&
      other.ownerUserId == ownerUserId &&
      other.status == status &&
      other.account == account &&
      other.fallbackOnLimit == fallbackOnLimit &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        provider.hashCode +
        label.hashCode +
        (baseUrl == null ? 0 : baseUrl.hashCode) +
        (keyHint == null ? 0 : keyHint.hashCode) +
        (lastTestedAt == null ? 0 : lastTestedAt.hashCode) +
        (lastTestOk == null ? 0 : lastTestOk.hashCode) +
        (ownerUserId == null ? 0 : ownerUserId.hashCode) +
        status.hashCode +
        (account == null ? 0 : account.hashCode) +
        fallbackOnLimit.hashCode +
        createdAt.hashCode;

  factory Credential.fromJson(Map<String, dynamic> json) => _$CredentialFromJson(json);

  Map<String, dynamic> toJson() => _$CredentialToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

