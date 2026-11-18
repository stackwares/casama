//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_secret_store_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetSecretStoreRequest {
  /// Returns a new [SetSecretStoreRequest] instance.
  SetSecretStoreRequest({

    required  this.siteUrl,

    required  this.projectId,

     this.environment,

     this.secretPath,

    required  this.clientId,

    required  this.clientSecret,

     this.moveExisting,
  });

  @JsonKey(
    
    name: r'site_url',
    required: true,
    includeIfNull: false,
  )


  final String siteUrl;



  @JsonKey(
    
    name: r'project_id',
    required: true,
    includeIfNull: false,
  )


  final String projectId;



  @JsonKey(
    
    name: r'environment',
    required: false,
    includeIfNull: false,
  )


  final String? environment;



  @JsonKey(
    
    name: r'secret_path',
    required: false,
    includeIfNull: false,
  )


  final String? secretPath;



  @JsonKey(
    
    name: r'client_id',
    required: true,
    includeIfNull: false,
  )


  final String clientId;



  @JsonKey(
    
    name: r'client_secret',
    required: true,
    includeIfNull: false,
  )


  final String clientSecret;



  @JsonKey(
    
    name: r'move_existing',
    required: false,
    includeIfNull: false,
  )


  final bool? moveExisting;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetSecretStoreRequest &&
      other.siteUrl == siteUrl &&
      other.projectId == projectId &&
      other.environment == environment &&
      other.secretPath == secretPath &&
      other.clientId == clientId &&
      other.clientSecret == clientSecret &&
      other.moveExisting == moveExisting;

    @override
    int get hashCode =>
        siteUrl.hashCode +
        projectId.hashCode +
        environment.hashCode +
        secretPath.hashCode +
        clientId.hashCode +
        clientSecret.hashCode +
        moveExisting.hashCode;

  factory SetSecretStoreRequest.fromJson(Map<String, dynamic> json) => _$SetSecretStoreRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetSecretStoreRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

