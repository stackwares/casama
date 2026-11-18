//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_ticket_row.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportTicketRow {
  /// Returns a new [SupportTicketRow] instance.
  SupportTicketRow({

    required  this.reference,

    required  this.topic,

    required  this.subject,

    required  this.status,

    required  this.userEmail,

    required  this.orgId,

    required  this.orgName,

    required  this.createdAt,

    required  this.closedAt,
  });

  @JsonKey(
    
    name: r'reference',
    required: true,
    includeIfNull: false,
  )


  final String reference;



  @JsonKey(
    
    name: r'topic',
    required: true,
    includeIfNull: false,
  )


  final String topic;



  @JsonKey(
    
    name: r'subject',
    required: true,
    includeIfNull: false,
  )


  final String subject;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final SupportTicketRowStatusEnum status;



  @JsonKey(
    
    name: r'user_email',
    required: true,
    includeIfNull: true,
  )


  final String? userEmail;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: true,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: true,
  )


  final String? orgName;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'closed_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? closedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportTicketRow &&
      other.reference == reference &&
      other.topic == topic &&
      other.subject == subject &&
      other.status == status &&
      other.userEmail == userEmail &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.createdAt == createdAt &&
      other.closedAt == closedAt;

    @override
    int get hashCode =>
        reference.hashCode +
        topic.hashCode +
        subject.hashCode +
        status.hashCode +
        (userEmail == null ? 0 : userEmail.hashCode) +
        (orgId == null ? 0 : orgId.hashCode) +
        (orgName == null ? 0 : orgName.hashCode) +
        createdAt.hashCode +
        (closedAt == null ? 0 : closedAt.hashCode);

  factory SupportTicketRow.fromJson(Map<String, dynamic> json) => _$SupportTicketRowFromJson(json);

  Map<String, dynamic> toJson() => _$SupportTicketRowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SupportTicketRowStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'closed')
closed(r'closed');

const SupportTicketRowStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


