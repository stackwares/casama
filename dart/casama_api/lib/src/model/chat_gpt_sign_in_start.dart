//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chat_gpt_sign_in_start.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChatGptSignInStart {
  /// Returns a new [ChatGptSignInStart] instance.
  ChatGptSignInStart({

    required  this.authorizeUrl,

    required  this.redirectUri,

    required  this.state,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'authorize_url',
    required: true,
    includeIfNull: false,
  )


  final String authorizeUrl;



  @JsonKey(
    
    name: r'redirect_uri',
    required: true,
    includeIfNull: false,
  )


  final String redirectUri;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final String state;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChatGptSignInStart &&
      other.authorizeUrl == authorizeUrl &&
      other.redirectUri == redirectUri &&
      other.state == state &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        authorizeUrl.hashCode +
        redirectUri.hashCode +
        state.hashCode +
        expiresAt.hashCode;

  factory ChatGptSignInStart.fromJson(Map<String, dynamic> json) => _$ChatGptSignInStartFromJson(json);

  Map<String, dynamic> toJson() => _$ChatGptSignInStartToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

