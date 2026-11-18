//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_question.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpQuestion {
  /// Returns a new [McpQuestion] instance.
  McpQuestion({

    required  this.id,

    required  this.orgId,

    required  this.botId,

    required  this.runId,

    required  this.connection,

    required  this.message,

    required  this.schema,

    required  this.status,

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
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



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
    
    name: r'connection',
    required: true,
    includeIfNull: false,
  )


  final String connection;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;



  @JsonKey(
    
    name: r'schema',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> schema;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final McpQuestionStatusEnum status;



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
    bool operator ==(Object other) => identical(this, other) || other is McpQuestion &&
      other.id == id &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.runId == runId &&
      other.connection == connection &&
      other.message == message &&
      other.schema == schema &&
      other.status == status &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        botId.hashCode +
        runId.hashCode +
        connection.hashCode +
        message.hashCode +
        schema.hashCode +
        status.hashCode +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory McpQuestion.fromJson(Map<String, dynamic> json) => _$McpQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$McpQuestionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum McpQuestionStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'accepted')
accepted(r'accepted'),
@JsonValue(r'declined')
declined(r'declined'),
@JsonValue(r'cancelled')
cancelled(r'cancelled'),
@JsonValue(r'expired')
expired(r'expired');

const McpQuestionStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


