//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_approval_decision.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryApprovalDecision {
  /// Returns a new [GalleryApprovalDecision] instance.
  GalleryApprovalDecision({

    required  this.decision,
  });

  @JsonKey(
    
    name: r'decision',
    required: true,
    includeIfNull: false,
  )


  final GalleryApprovalDecisionDecisionEnum decision;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryApprovalDecision &&
      other.decision == decision;

    @override
    int get hashCode =>
        decision.hashCode;

  factory GalleryApprovalDecision.fromJson(Map<String, dynamic> json) => _$GalleryApprovalDecisionFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryApprovalDecisionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryApprovalDecisionDecisionEnum {
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'denied')
denied(r'denied');

const GalleryApprovalDecisionDecisionEnum(this.value);

final String value;

@override
String toString() => value;
}


