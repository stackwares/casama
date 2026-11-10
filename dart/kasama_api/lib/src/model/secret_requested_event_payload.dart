//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'secret_requested_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SecretRequestedEventPayload {
  /// Returns a new [SecretRequestedEventPayload] instance.
  SecretRequestedEventPayload({

    required  this.requestId,

    required  this.name,

    required  this.service,

    required  this.allowedHosts,

    required  this.reason,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'request_id',
    required: true,
    includeIfNull: false,
  )


  final String requestId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'service',
    required: true,
    includeIfNull: false,
  )


  final String service;



  @JsonKey(
    
    name: r'allowed_hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedHosts;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SecretRequestedEventPayload &&
      other.requestId == requestId &&
      other.name == name &&
      other.service == service &&
      other.allowedHosts == allowedHosts &&
      other.reason == reason &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        requestId.hashCode +
        name.hashCode +
        service.hashCode +
        allowedHosts.hashCode +
        reason.hashCode +
        expiresAt.hashCode;

  factory SecretRequestedEventPayload.fromJson(Map<String, dynamic> json) => _$SecretRequestedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SecretRequestedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

