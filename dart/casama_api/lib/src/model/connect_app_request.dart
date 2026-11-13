//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_app_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectAppRequest {
  /// Returns a new [ConnectAppRequest] instance.
  ConnectAppRequest({

    required  this.orgId,

    required  this.appId,

    required  this.method,

     this.apiKey,

     this.integrationId,

     this.returnToApp,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'app_id',
    required: true,
    includeIfNull: false,
  )


  final String appId;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final ConnectAppRequestMethodEnum method;



  @JsonKey(
    
    name: r'api_key',
    required: false,
    includeIfNull: false,
  )


  final String? apiKey;



  @JsonKey(
    
    name: r'integration_id',
    required: false,
    includeIfNull: false,
  )


  final String? integrationId;



  @JsonKey(
    
    name: r'return_to_app',
    required: false,
    includeIfNull: false,
  )


  final bool? returnToApp;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectAppRequest &&
      other.orgId == orgId &&
      other.appId == appId &&
      other.method == method &&
      other.apiKey == apiKey &&
      other.integrationId == integrationId &&
      other.returnToApp == returnToApp;

    @override
    int get hashCode =>
        orgId.hashCode +
        appId.hashCode +
        method.hashCode +
        apiKey.hashCode +
        integrationId.hashCode +
        returnToApp.hashCode;

  factory ConnectAppRequest.fromJson(Map<String, dynamic> json) => _$ConnectAppRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectAppRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ConnectAppRequestMethodEnum {
@JsonValue(r'oauth')
oauth(r'oauth'),
@JsonValue(r'api_key')
apiKey(r'api_key'),
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'managed')
managed(r'managed');

const ConnectAppRequestMethodEnum(this.value);

final String value;

@override
String toString() => value;
}


