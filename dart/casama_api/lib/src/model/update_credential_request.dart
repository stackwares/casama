//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_credential_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateCredentialRequest {
  /// Returns a new [UpdateCredentialRequest] instance.
  UpdateCredentialRequest({

     this.label,

     this.fallbackOnLimit,

     this.embeddingModel,
  });

  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final String? label;



  @JsonKey(
    
    name: r'fallback_on_limit',
    required: false,
    includeIfNull: false,
  )


  final bool? fallbackOnLimit;



      /// openai_compatible only; null or empty turns it off
  @JsonKey(
    
    name: r'embedding_model',
    required: false,
    includeIfNull: false,
  )


  final String? embeddingModel;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCredentialRequest &&
      other.label == label &&
      other.fallbackOnLimit == fallbackOnLimit &&
      other.embeddingModel == embeddingModel;

    @override
    int get hashCode =>
        label.hashCode +
        fallbackOnLimit.hashCode +
        (embeddingModel == null ? 0 : embeddingModel.hashCode);

  factory UpdateCredentialRequest.fromJson(Map<String, dynamic> json) => _$UpdateCredentialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCredentialRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

