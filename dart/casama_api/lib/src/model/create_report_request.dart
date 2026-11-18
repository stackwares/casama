//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/report_target.dart';
import 'package:casama_api/src/model/report_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_report_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateReportRequest {
  /// Returns a new [CreateReportRequest] instance.
  CreateReportRequest({

    required  this.targetKind,

    required  this.targetId,

    required  this.reason,

     this.note,
  });

  @JsonKey(
    
    name: r'target_kind',
    required: true,
    includeIfNull: false,
  )


  final ReportTarget targetKind;



  @JsonKey(
    
    name: r'target_id',
    required: true,
    includeIfNull: false,
  )


  final String targetId;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final ReportReason reason;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateReportRequest &&
      other.targetKind == targetKind &&
      other.targetId == targetId &&
      other.reason == reason &&
      other.note == note;

    @override
    int get hashCode =>
        targetKind.hashCode +
        targetId.hashCode +
        reason.hashCode +
        note.hashCode;

  factory CreateReportRequest.fromJson(Map<String, dynamic> json) => _$CreateReportRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReportRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

