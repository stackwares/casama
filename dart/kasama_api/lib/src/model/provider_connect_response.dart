//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provider_connect_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderConnectResponse {
  /// Returns a new [ProviderConnectResponse] instance.
  ProviderConnectResponse({

    required  this.redirectUrl,
  });

  @JsonKey(
    
    name: r'redirect_url',
    required: true,
    includeIfNull: false,
  )


  final String redirectUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProviderConnectResponse &&
      other.redirectUrl == redirectUrl;

    @override
    int get hashCode =>
        redirectUrl.hashCode;

  factory ProviderConnectResponse.fromJson(Map<String, dynamic> json) => _$ProviderConnectResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderConnectResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

