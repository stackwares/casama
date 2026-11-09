//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approval_resolved_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApprovalResolvedEventPayload {
  /// Returns a new [ApprovalResolvedEventPayload] instance.
  ApprovalResolvedEventPayload({

    required  this.approvalId,

    required  this.decision,

    required  this.decidedBy,
  });

  @JsonKey(
    
    name: r'approval_id',
    required: true,
    includeIfNull: false,
  )


  final String approvalId;



  @JsonKey(
    
    name: r'decision',
    required: true,
    includeIfNull: false,
  )


  final ApprovalResolvedEventPayloadDecisionEnum decision;



  @JsonKey(
    
    name: r'decided_by',
    required: true,
    includeIfNull: true,
  )


  final String? decidedBy;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApprovalResolvedEventPayload &&
      other.approvalId == approvalId &&
      other.decision == decision &&
      other.decidedBy == decidedBy;

    @override
    int get hashCode =>
        approvalId.hashCode +
        decision.hashCode +
        (decidedBy == null ? 0 : decidedBy.hashCode);

  factory ApprovalResolvedEventPayload.fromJson(Map<String, dynamic> json) => _$ApprovalResolvedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalResolvedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApprovalResolvedEventPayloadDecisionEnum {
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'denied')
denied(r'denied'),
@JsonValue(r'expired')
expired(r'expired');

const ApprovalResolvedEventPayloadDecisionEnum(this.value);

final String value;

@override
String toString() => value;
}


