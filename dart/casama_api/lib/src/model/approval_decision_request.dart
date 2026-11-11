//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approval_decision_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApprovalDecisionRequest {
  /// Returns a new [ApprovalDecisionRequest] instance.
  ApprovalDecisionRequest({

    required  this.decision,

     this.alwaysAllow,
  });

  @JsonKey(
    
    name: r'decision',
    required: true,
    includeIfNull: false,
  )


  final ApprovalDecisionRequestDecisionEnum decision;



      /// Always allow this tool for this bot
  @JsonKey(
    
    name: r'always_allow',
    required: false,
    includeIfNull: false,
  )


  final bool? alwaysAllow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApprovalDecisionRequest &&
      other.decision == decision &&
      other.alwaysAllow == alwaysAllow;

    @override
    int get hashCode =>
        decision.hashCode +
        alwaysAllow.hashCode;

  factory ApprovalDecisionRequest.fromJson(Map<String, dynamic> json) => _$ApprovalDecisionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalDecisionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApprovalDecisionRequestDecisionEnum {
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'denied')
denied(r'denied');

const ApprovalDecisionRequestDecisionEnum(this.value);

final String value;

@override
String toString() => value;
}


