//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_question_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpQuestionEventPayload {
  /// Returns a new [McpQuestionEventPayload] instance.
  McpQuestionEventPayload({

    required  this.questionId,

    required  this.connection,

    required  this.message,

    required  this.schema,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'question_id',
    required: true,
    includeIfNull: false,
  )


  final String questionId;



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
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpQuestionEventPayload &&
      other.questionId == questionId &&
      other.connection == connection &&
      other.message == message &&
      other.schema == schema &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        questionId.hashCode +
        connection.hashCode +
        message.hashCode +
        schema.hashCode +
        expiresAt.hashCode;

  factory McpQuestionEventPayload.fromJson(Map<String, dynamic> json) => _$McpQuestionEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$McpQuestionEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

