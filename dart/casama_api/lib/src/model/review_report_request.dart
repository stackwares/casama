//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'review_report_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReviewReportRequest {
  /// Returns a new [ReviewReportRequest] instance.
  ReviewReportRequest({

    required  this.decision,

     this.suspendWorkspace,
  });

  @JsonKey(
    
    name: r'decision',
    required: true,
    includeIfNull: false,
  )


  final ReviewReportRequestDecisionEnum decision;



  @JsonKey(
    
    name: r'suspend_workspace',
    required: false,
    includeIfNull: false,
  )


  final bool? suspendWorkspace;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReviewReportRequest &&
      other.decision == decision &&
      other.suspendWorkspace == suspendWorkspace;

    @override
    int get hashCode =>
        decision.hashCode +
        suspendWorkspace.hashCode;

  factory ReviewReportRequest.fromJson(Map<String, dynamic> json) => _$ReviewReportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReviewReportRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ReviewReportRequestDecisionEnum {
@JsonValue(r'actioned')
actioned(r'actioned'),
@JsonValue(r'dismissed')
dismissed(r'dismissed');

const ReviewReportRequestDecisionEnum(this.value);

final String value;

@override
String toString() => value;
}


