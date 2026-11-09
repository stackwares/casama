//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_secret_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateSecretRequest {
  /// Returns a new [CreateSecretRequest] instance.
  CreateSecretRequest({

    required  this.orgId,

    required  this.name,

    required  this.value,

    required  this.allowedHosts,

     this.allowedBotIds,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



      /// Referenced as {{secret:NAME}}
  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// Stored in Vault; never returned
  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final String value;



  @JsonKey(
    
    name: r'allowed_hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedHosts;



  @JsonKey(
    
    name: r'allowed_bot_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? allowedBotIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateSecretRequest &&
      other.orgId == orgId &&
      other.name == name &&
      other.value == value &&
      other.allowedHosts == allowedHosts &&
      other.allowedBotIds == allowedBotIds;

    @override
    int get hashCode =>
        orgId.hashCode +
        name.hashCode +
        value.hashCode +
        allowedHosts.hashCode +
        allowedBotIds.hashCode;

  factory CreateSecretRequest.fromJson(Map<String, dynamic> json) => _$CreateSecretRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateSecretRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

