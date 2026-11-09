//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'test_credential_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TestCredentialRequest {
  /// Returns a new [TestCredentialRequest] instance.
  TestCredentialRequest({

     this.model,
  });

  @JsonKey(
    
    name: r'model',
    required: false,
    includeIfNull: false,
  )


  final String? model;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TestCredentialRequest &&
      other.model == model;

    @override
    int get hashCode =>
        model.hashCode;

  factory TestCredentialRequest.fromJson(Map<String, dynamic> json) => _$TestCredentialRequestFromJson(json);

  Map<String, dynamic> toJson() => _$TestCredentialRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

