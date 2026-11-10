//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/teach_draft.dart';
import 'package:kasama_api/src/model/teach_step.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'teach_session.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TeachSession {
  /// Returns a new [TeachSession] instance.
  TeachSession({

    required  this.id,

    required  this.botId,

    required  this.computerId,

    required  this.status,

    required  this.conversationId,

    required  this.draft,

    required  this.skillId,

    required  this.steps,

    required  this.startedAt,

    required  this.stoppedAt,
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
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final TeachSessionStatusEnum status;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'draft',
    required: true,
    includeIfNull: true,
  )


  final TeachDraft? draft;



  @JsonKey(
    
    name: r'skill_id',
    required: true,
    includeIfNull: true,
  )


  final String? skillId;



  @JsonKey(
    
    name: r'steps',
    required: true,
    includeIfNull: false,
  )


  final List<TeachStep> steps;



  @JsonKey(
    
    name: r'started_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime startedAt;



  @JsonKey(
    
    name: r'stopped_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? stoppedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TeachSession &&
      other.id == id &&
      other.botId == botId &&
      other.computerId == computerId &&
      other.status == status &&
      other.conversationId == conversationId &&
      other.draft == draft &&
      other.skillId == skillId &&
      other.steps == steps &&
      other.startedAt == startedAt &&
      other.stoppedAt == stoppedAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        computerId.hashCode +
        status.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        (draft == null ? 0 : draft.hashCode) +
        (skillId == null ? 0 : skillId.hashCode) +
        steps.hashCode +
        startedAt.hashCode +
        (stoppedAt == null ? 0 : stoppedAt.hashCode);

  factory TeachSession.fromJson(Map<String, dynamic> json) => _$TeachSessionFromJson(json);

  Map<String, dynamic> toJson() => _$TeachSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TeachSessionStatusEnum {
@JsonValue(r'recording')
recording(r'recording'),
@JsonValue(r'drafting')
drafting(r'drafting'),
@JsonValue(r'drafted')
drafted(r'drafted'),
@JsonValue(r'saved')
saved(r'saved'),
@JsonValue(r'cancelled')
cancelled(r'cancelled'),
@JsonValue(r'failed')
failed(r'failed');

const TeachSessionStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


