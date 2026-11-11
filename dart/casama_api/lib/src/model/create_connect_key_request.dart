//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_connect_key_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateConnectKeyRequest {
  /// Returns a new [CreateConnectKeyRequest] instance.
  CreateConnectKeyRequest({

    required  this.instanceName,

     this.scopes,
  });

  @JsonKey(
    
    name: r'instance_name',
    required: true,
    includeIfNull: false,
  )


  final String instanceName;



  @JsonKey(
    
    name: r'scopes',
    required: false,
    includeIfNull: false,
  )


  final List<CreateConnectKeyRequestScopesEnum>? scopes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateConnectKeyRequest &&
      other.instanceName == instanceName &&
      other.scopes == scopes;

    @override
    int get hashCode =>
        instanceName.hashCode +
        scopes.hashCode;

  factory CreateConnectKeyRequest.fromJson(Map<String, dynamic> json) => _$CreateConnectKeyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateConnectKeyRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateConnectKeyRequestScopesEnum {
@JsonValue(r'computers')
computers(r'computers'),
@JsonValue(r'models')
models(r'models');

const CreateConnectKeyRequestScopesEnum(this.value);

final String value;

@override
String toString() => value;
}


