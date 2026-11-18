//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attach_integration_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttachIntegrationRequest {
  /// Returns a new [AttachIntegrationRequest] instance.
  AttachIntegrationRequest({

    required  this.integrationId,

     this.toolAllowlist,
  });

  @JsonKey(
    
    name: r'integration_id',
    required: true,
    includeIfNull: false,
  )


  final String integrationId;



  @JsonKey(
    
    name: r'tool_allowlist',
    required: false,
    includeIfNull: false,
  )


  final List<String>? toolAllowlist;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AttachIntegrationRequest &&
      other.integrationId == integrationId &&
      other.toolAllowlist == toolAllowlist;

    @override
    int get hashCode =>
        integrationId.hashCode +
        toolAllowlist.hashCode;

  factory AttachIntegrationRequest.fromJson(Map<String, dynamic> json) => _$AttachIntegrationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AttachIntegrationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

