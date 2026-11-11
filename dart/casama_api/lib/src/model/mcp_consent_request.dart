//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_consent_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpConsentRequest {
  /// Returns a new [McpConsentRequest] instance.
  McpConsentRequest({

    required  this.orgId,

    required  this.approve,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'approve',
    required: true,
    includeIfNull: false,
  )


  final bool approve;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpConsentRequest &&
      other.orgId == orgId &&
      other.approve == approve;

    @override
    int get hashCode =>
        orgId.hashCode +
        approve.hashCode;

  factory McpConsentRequest.fromJson(Map<String, dynamic> json) => _$McpConsentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$McpConsentRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

