//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_question_resolved_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpQuestionResolvedEventPayload {
  /// Returns a new [McpQuestionResolvedEventPayload] instance.
  McpQuestionResolvedEventPayload({

    required  this.questionId,

    required  this.outcome,
  });

  @JsonKey(
    
    name: r'question_id',
    required: true,
    includeIfNull: false,
  )


  final String questionId;



  @JsonKey(
    
    name: r'outcome',
    required: true,
    includeIfNull: false,
  )


  final McpQuestionResolvedEventPayloadOutcomeEnum outcome;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpQuestionResolvedEventPayload &&
      other.questionId == questionId &&
      other.outcome == outcome;

    @override
    int get hashCode =>
        questionId.hashCode +
        outcome.hashCode;

  factory McpQuestionResolvedEventPayload.fromJson(Map<String, dynamic> json) => _$McpQuestionResolvedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$McpQuestionResolvedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum McpQuestionResolvedEventPayloadOutcomeEnum {
@JsonValue(r'accepted')
accepted(r'accepted'),
@JsonValue(r'declined')
declined(r'declined'),
@JsonValue(r'cancelled')
cancelled(r'cancelled'),
@JsonValue(r'expired')
expired(r'expired');

const McpQuestionResolvedEventPayloadOutcomeEnum(this.value);

final String value;

@override
String toString() => value;
}


