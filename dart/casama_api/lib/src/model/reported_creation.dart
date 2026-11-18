//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reported_creation.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportedCreation {
  /// Returns a new [ReportedCreation] instance.
  ReportedCreation({

    required  this.id,

    required  this.orgId,

    required  this.orgName,

    required  this.title,

    required  this.kind,

    required  this.reports,

    required  this.reporters,

    required  this.lastReason,

    required  this.takenDown,

    required  this.lastReportedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: false,
  )


  final String orgName;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'reports',
    required: true,
    includeIfNull: false,
  )


  final int reports;



  @JsonKey(
    
    name: r'reporters',
    required: true,
    includeIfNull: false,
  )


  final int reporters;



  @JsonKey(
    
    name: r'last_reason',
    required: true,
    includeIfNull: false,
  )


  final String lastReason;



  @JsonKey(
    
    name: r'taken_down',
    required: true,
    includeIfNull: false,
  )


  final bool takenDown;



  @JsonKey(
    
    name: r'last_reported_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime lastReportedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportedCreation &&
      other.id == id &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.title == title &&
      other.kind == kind &&
      other.reports == reports &&
      other.reporters == reporters &&
      other.lastReason == lastReason &&
      other.takenDown == takenDown &&
      other.lastReportedAt == lastReportedAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        orgName.hashCode +
        title.hashCode +
        kind.hashCode +
        reports.hashCode +
        reporters.hashCode +
        lastReason.hashCode +
        takenDown.hashCode +
        lastReportedAt.hashCode;

  factory ReportedCreation.fromJson(Map<String, dynamic> json) => _$ReportedCreationFromJson(json);

  Map<String, dynamic> toJson() => _$ReportedCreationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

