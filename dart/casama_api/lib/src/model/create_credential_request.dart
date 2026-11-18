//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/provider_id.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_credential_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateCredentialRequest {
  /// Returns a new [CreateCredentialRequest] instance.
  CreateCredentialRequest({

    required  this.orgId,

    required  this.provider,

    required  this.label,

     this.apiKey,

     this.baseUrl,

     this.embeddingModel,

     this.visionModels,
  });

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



      /// Stored in Vault; never returned
  @JsonKey(
    
    name: r'api_key',
    required: false,
    includeIfNull: false,
  )


  final String? apiKey;



  @JsonKey(
    
    name: r'base_url',
    required: false,
    includeIfNull: false,
  )


  final String? baseUrl;



      /// openai_compatible only: an embedding model on that server, for memory search
  @JsonKey(
    
    name: r'embedding_model',
    required: false,
    includeIfNull: false,
  )


  final String? embeddingModel;



      /// openai_compatible only: models on that server that read images, if Casama doesn't recognize them
  @JsonKey(
    
    name: r'vision_models',
    required: false,
    includeIfNull: false,
  )


  final List<String>? visionModels;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateCredentialRequest &&
      other.orgId == orgId &&
      other.provider == provider &&
      other.label == label &&
      other.apiKey == apiKey &&
      other.baseUrl == baseUrl &&
      other.embeddingModel == embeddingModel &&
      other.visionModels == visionModels;

    @override
    int get hashCode =>
        orgId.hashCode +
        provider.hashCode +
        label.hashCode +
        apiKey.hashCode +
        baseUrl.hashCode +
        embeddingModel.hashCode +
        visionModels.hashCode;

  factory CreateCredentialRequest.fromJson(Map<String, dynamic> json) => _$CreateCredentialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCredentialRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

