//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_link_key_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateLinkKeyRequest {
  /// Returns a new [CreateLinkKeyRequest] instance.
  CreateLinkKeyRequest({

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


  final List<CreateLinkKeyRequestScopesEnum>? scopes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateLinkKeyRequest &&
      other.instanceName == instanceName &&
      other.scopes == scopes;

    @override
    int get hashCode =>
        instanceName.hashCode +
        scopes.hashCode;

  factory CreateLinkKeyRequest.fromJson(Map<String, dynamic> json) => _$CreateLinkKeyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateLinkKeyRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateLinkKeyRequestScopesEnum {
@JsonValue(r'computers')
computers(r'computers'),
@JsonValue(r'models')
models(r'models'),
@JsonValue(r'remote_access')
remoteAccess(r'remote_access'),
@JsonValue(r'push')
push(r'push');

const CreateLinkKeyRequestScopesEnum(this.value);

final String value;

@override
String toString() => value;
}


