//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_integration_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateIntegrationRequest {
  /// Returns a new [UpdateIntegrationRequest] instance.
  UpdateIntegrationRequest({

     this.riskOverrides,
  });

  @JsonKey(
    
    name: r'risk_overrides',
    required: false,
    includeIfNull: false,
  )


  final Map<String, UpdateIntegrationRequestRiskOverridesEnum>? riskOverrides;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateIntegrationRequest &&
      other.riskOverrides == riskOverrides;

    @override
    int get hashCode =>
        riskOverrides.hashCode;

  factory UpdateIntegrationRequest.fromJson(Map<String, dynamic> json) => _$UpdateIntegrationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateIntegrationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UpdateIntegrationRequestRiskOverridesEnum {
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high');

const UpdateIntegrationRequestRiskOverridesEnum(this.value);

final String value;

@override
String toString() => value;
}


