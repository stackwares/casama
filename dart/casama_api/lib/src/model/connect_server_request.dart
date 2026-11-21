//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_server_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectServerRequest {
  /// Returns a new [ConnectServerRequest] instance.
  ConnectServerRequest({

    required  this.orgId,

    required  this.url,

    required  this.name,

    required  this.method,

     this.apiKey,

     this.authHeader,

     this.privateUrl,

     this.botId,

     this.returnToApp,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final ConnectServerRequestMethodEnum method;



  @JsonKey(
    
    name: r'api_key',
    required: false,
    includeIfNull: false,
  )


  final String? apiKey;



  @JsonKey(
    
    name: r'auth_header',
    required: false,
    includeIfNull: false,
  )


  final String? authHeader;



  @JsonKey(
    
    name: r'private_url',
    required: false,
    includeIfNull: false,
  )


  final bool? privateUrl;



  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;



  @JsonKey(
    
    name: r'return_to_app',
    required: false,
    includeIfNull: false,
  )


  final bool? returnToApp;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectServerRequest &&
      other.orgId == orgId &&
      other.url == url &&
      other.name == name &&
      other.method == method &&
      other.apiKey == apiKey &&
      other.authHeader == authHeader &&
      other.privateUrl == privateUrl &&
      other.botId == botId &&
      other.returnToApp == returnToApp;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode +
        name.hashCode +
        method.hashCode +
        apiKey.hashCode +
        authHeader.hashCode +
        privateUrl.hashCode +
        botId.hashCode +
        returnToApp.hashCode;

  factory ConnectServerRequest.fromJson(Map<String, dynamic> json) => _$ConnectServerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectServerRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ConnectServerRequestMethodEnum {
@JsonValue(r'oauth')
oauth(r'oauth'),
@JsonValue(r'api_key')
apiKey(r'api_key'),
@JsonValue(r'none')
none(r'none');

const ConnectServerRequestMethodEnum(this.value);

final String value;

@override
String toString() => value;
}


