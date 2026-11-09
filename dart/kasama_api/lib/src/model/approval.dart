//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/risk.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approval.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Approval {
  /// Returns a new [Approval] instance.
  Approval({

    required  this.id,

    required  this.botId,

    required  this.runId,

    required  this.toolName,

    required  this.argsRedacted,

    required  this.summary,

    required  this.risk,

    required  this.status,

    required  this.decidedAt,

    required  this.expiresAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



  @JsonKey(
    
    name: r'tool_name',
    required: true,
    includeIfNull: false,
  )


  final String toolName;



  @JsonKey(
    
    name: r'args_redacted',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> argsRedacted;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: false,
  )


  final Risk risk;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ApprovalStatusEnum status;



  @JsonKey(
    
    name: r'decided_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? decidedAt;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Approval &&
      other.id == id &&
      other.botId == botId &&
      other.runId == runId &&
      other.toolName == toolName &&
      other.argsRedacted == argsRedacted &&
      other.summary == summary &&
      other.risk == risk &&
      other.status == status &&
      other.decidedAt == decidedAt &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        runId.hashCode +
        toolName.hashCode +
        argsRedacted.hashCode +
        summary.hashCode +
        risk.hashCode +
        status.hashCode +
        (decidedAt == null ? 0 : decidedAt.hashCode) +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory Approval.fromJson(Map<String, dynamic> json) => _$ApprovalFromJson(json);

  Map<String, dynamic> toJson() => _$ApprovalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ApprovalStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'denied')
denied(r'denied'),
@JsonValue(r'expired')
expired(r'expired');

const ApprovalStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


