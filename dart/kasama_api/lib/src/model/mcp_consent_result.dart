//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_consent_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpConsentResult {
  /// Returns a new [McpConsentResult] instance.
  McpConsentResult({

    required  this.redirectUrl,
  });

  @JsonKey(
    
    name: r'redirect_url',
    required: true,
    includeIfNull: false,
  )


  final String redirectUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpConsentResult &&
      other.redirectUrl == redirectUrl;

    @override
    int get hashCode =>
        redirectUrl.hashCode;

  factory McpConsentResult.fromJson(Map<String, dynamic> json) => _$McpConsentResultFromJson(json);

  Map<String, dynamic> toJson() => _$McpConsentResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

