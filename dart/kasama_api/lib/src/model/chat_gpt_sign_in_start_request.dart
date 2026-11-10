//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_gpt_sign_in_start_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChatGptSignInStartRequest {
  /// Returns a new [ChatGptSignInStartRequest] instance.
  ChatGptSignInStartRequest({

    required  this.orgId,

    required  this.redirectPort,

     this.credentialId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



      /// The client's loopback port; OpenAI redirects to http://127.0.0.1:<port>/auth/callback
          // minimum: 1024
          // maximum: 65535
  @JsonKey(
    
    name: r'redirect_port',
    required: true,
    includeIfNull: false,
  )


  final int redirectPort;



      /// Reconnect this ChatGPT credential
  @JsonKey(
    
    name: r'credential_id',
    required: false,
    includeIfNull: false,
  )


  final String? credentialId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChatGptSignInStartRequest &&
      other.orgId == orgId &&
      other.redirectPort == redirectPort &&
      other.credentialId == credentialId;

    @override
    int get hashCode =>
        orgId.hashCode +
        redirectPort.hashCode +
        credentialId.hashCode;

  factory ChatGptSignInStartRequest.fromJson(Map<String, dynamic> json) => _$ChatGptSignInStartRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatGptSignInStartRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

