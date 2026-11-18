//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/integration.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'connect_app_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ConnectAppResponse {
  /// Returns a new [ConnectAppResponse] instance.
  ConnectAppResponse({

    required  this.status,

     this.integration,

     this.authorizeUrl,

     this.flowId,

     this.error,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ConnectAppResponseStatusEnum status;



  @JsonKey(
    
    name: r'integration',
    required: false,
    includeIfNull: false,
  )


  final Integration? integration;



  @JsonKey(
    
    name: r'authorize_url',
    required: false,
    includeIfNull: false,
  )


  final String? authorizeUrl;



  @JsonKey(
    
    name: r'flow_id',
    required: false,
    includeIfNull: false,
  )


  final String? flowId;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ConnectAppResponse &&
      other.status == status &&
      other.integration == integration &&
      other.authorizeUrl == authorizeUrl &&
      other.flowId == flowId &&
      other.error == error;

    @override
    int get hashCode =>
        status.hashCode +
        integration.hashCode +
        authorizeUrl.hashCode +
        flowId.hashCode +
        error.hashCode;

  factory ConnectAppResponse.fromJson(Map<String, dynamic> json) => _$ConnectAppResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectAppResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ConnectAppResponseStatusEnum {
@JsonValue(r'connected')
connected(r'connected'),
@JsonValue(r'authorize')
authorize(r'authorize'),
@JsonValue(r'error')
error(r'error');

const ConnectAppResponseStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


