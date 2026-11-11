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





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCredentialRequest &&
      other.label == label &&
      other.fallbackOnLimit == fallbackOnLimit;

    @override
    int get hashCode =>
        label.hashCode +
        fallbackOnLimit.hashCode;

  factory UpdateCredentialRequest.fromJson(Map<String, dynamic> json) => _$UpdateCredentialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCredentialRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

