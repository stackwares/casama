//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approval_requested_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApprovalRequestedEventPayload {
  /// Returns a new [ApprovalRequestedEventPayload] instance.
  ApprovalRequestedEventPayload({

    required  this.approvalId,

    required  this.tool,

    required  this.argsRedacted,

    required  this.risk,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'approval_id',
    required: true,
    includeIfNull: false,
  )


  final String approvalId;



  @JsonKey(
    
    name: r'tool',
    required: true,
    includeIfNull: false,
  )


  final String tool;



  @JsonKey(
    
    name: r'args_redacted',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> argsRedacted;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: false,
  )


  final ApprovalRequestedEventPayloadRiskEnum risk;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApprovalRequestedEventPayload &&
      other.approvalId == approvalId &&
      other.tool == tool &&
      other.argsRedacted == argsRedacted &&
      other.risk == risk &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        approvalId.hashCode +
        tool.hashCode +
        argsRedacted.hashCode +
        risk.hashCode +
        expiresAt.hashCode;

  factory ApprovalRequestedEventPayload.fromJson(Map<String, dynamic> json) => _$ApprovalRequestedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalRequestedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApprovalRequestedEventPayloadRiskEnum {
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high');

const ApprovalRequestedEventPayloadRiskEnum(this.value);

final String value;

@override
String toString() => value;
}


