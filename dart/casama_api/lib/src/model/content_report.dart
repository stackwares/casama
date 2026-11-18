//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/report_target_kind.dart';
import 'package:casama_api/src/model/report_reason.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'content_report.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ContentReport {
  /// Returns a new [ContentReport] instance.
  ContentReport({

    required  this.id,

    required  this.targetKind,

    required  this.targetId,

    required  this.targetOrgId,

    required  this.targetOrgName,

    required  this.reason,

    required  this.note,

    required  this.snapshot,

    required  this.reporterEmail,

    required  this.sameTarget,

    required  this.status,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'target_kind',
    required: true,
    includeIfNull: false,
  )


  final ReportTargetKind targetKind;



  @JsonKey(
    
    name: r'target_id',
    required: true,
    includeIfNull: false,
  )


  final String targetId;



  @JsonKey(
    
    name: r'target_org_id',
    required: true,
    includeIfNull: true,
  )


  final String? targetOrgId;



  @JsonKey(
    
    name: r'target_org_name',
    required: true,
    includeIfNull: true,
  )


  final String? targetOrgName;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final ReportReason reason;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'snapshot',
    required: true,
    includeIfNull: true,
  )


  final String? snapshot;



  @JsonKey(
    
    name: r'reporter_email',
    required: true,
    includeIfNull: true,
  )


  final String? reporterEmail;



  @JsonKey(
    
    name: r'same_target',
    required: true,
    includeIfNull: false,
  )


  final int sameTarget;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ContentReportStatusEnum status;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ContentReport &&
      other.id == id &&
      other.targetKind == targetKind &&
      other.targetId == targetId &&
      other.targetOrgId == targetOrgId &&
      other.targetOrgName == targetOrgName &&
      other.reason == reason &&
      other.note == note &&
      other.snapshot == snapshot &&
      other.reporterEmail == reporterEmail &&
      other.sameTarget == sameTarget &&
      other.status == status &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        targetKind.hashCode +
        targetId.hashCode +
        (targetOrgId == null ? 0 : targetOrgId.hashCode) +
        (targetOrgName == null ? 0 : targetOrgName.hashCode) +
        reason.hashCode +
        (note == null ? 0 : note.hashCode) +
        (snapshot == null ? 0 : snapshot.hashCode) +
        (reporterEmail == null ? 0 : reporterEmail.hashCode) +
        sameTarget.hashCode +
        status.hashCode +
        createdAt.hashCode;

  factory ContentReport.fromJson(Map<String, dynamic> json) => _$ContentReportFromJson(json);

  Map<String, dynamic> toJson() => _$ContentReportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ContentReportStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'actioned')
actioned(r'actioned'),
@JsonValue(r'dismissed')
dismissed(r'dismissed');

const ContentReportStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


