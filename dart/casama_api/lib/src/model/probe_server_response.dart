//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'probe_server_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProbeServerResponse {
  /// Returns a new [ProbeServerResponse] instance.
  ProbeServerResponse({

    required  this.auth,

    required  this.host,

     this.signInHost,

     this.oauthAvailable,

     this.appId,
  });

  @JsonKey(
    
    name: r'auth',
    required: true,
    includeIfNull: false,
  )


  final ProbeServerResponseAuthEnum auth;



  @JsonKey(
    
    name: r'host',
    required: true,
    includeIfNull: false,
  )


  final String host;



  @JsonKey(
    
    name: r'sign_in_host',
    required: false,
    includeIfNull: false,
  )


  final String? signInHost;



  @JsonKey(
    
    name: r'oauth_available',
    required: false,
    includeIfNull: false,
  )


  final bool? oauthAvailable;



  @JsonKey(
    
    name: r'app_id',
    required: false,
    includeIfNull: false,
  )


  final String? appId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProbeServerResponse &&
      other.auth == auth &&
      other.host == host &&
      other.signInHost == signInHost &&
      other.oauthAvailable == oauthAvailable &&
      other.appId == appId;

    @override
    int get hashCode =>
        auth.hashCode +
        host.hashCode +
        signInHost.hashCode +
        oauthAvailable.hashCode +
        appId.hashCode;

  factory ProbeServerResponse.fromJson(Map<String, dynamic> json) => _$ProbeServerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProbeServerResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ProbeServerResponseAuthEnum {
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'oauth')
oauth(r'oauth'),
@JsonValue(r'key')
key(r'key');

const ProbeServerResponseAuthEnum(this.value);

final String value;

@override
String toString() => value;
}


