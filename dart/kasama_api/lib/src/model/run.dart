//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/run_status.dart';
import 'package:kasama_api/src/model/run_error.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Run {
  /// Returns a new [Run] instance.
  Run({

    required  this.id,

    required  this.botId,

    required  this.conversationId,

    required  this.parentRunId,

    required  this.trigger,

    required  this.status,

    required  this.tokensIn,

    required  this.tokensOut,

    required  this.costUsd,

    required  this.lastSeq,

    required  this.startedAt,

    required  this.endedAt,

    required  this.error,

    required  this.traceId,

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
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'parent_run_id',
    required: true,
    includeIfNull: true,
  )


  final String? parentRunId;



  @JsonKey(
    
    name: r'trigger',
    required: true,
    includeIfNull: false,
  )


  final String trigger;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final RunStatus status;



  @JsonKey(
    
    name: r'tokens_in',
    required: true,
    includeIfNull: false,
  )


  final int tokensIn;



  @JsonKey(
    
    name: r'tokens_out',
    required: true,
    includeIfNull: false,
  )


  final int tokensOut;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



  @JsonKey(
    
    name: r'last_seq',
    required: true,
    includeIfNull: false,
  )


  final int lastSeq;



  @JsonKey(
    
    name: r'started_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? startedAt;



  @JsonKey(
    
    name: r'ended_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? endedAt;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final RunError? error;



      /// OpenTelemetry trace of this run (D-107)
  @JsonKey(
    
    name: r'trace_id',
    required: true,
    includeIfNull: true,
  )


  final String? traceId;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Run &&
      other.id == id &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.parentRunId == parentRunId &&
      other.trigger == trigger &&
      other.status == status &&
      other.tokensIn == tokensIn &&
      other.tokensOut == tokensOut &&
      other.costUsd == costUsd &&
      other.lastSeq == lastSeq &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.error == error &&
      other.traceId == traceId &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        (parentRunId == null ? 0 : parentRunId.hashCode) +
        trigger.hashCode +
        status.hashCode +
        tokensIn.hashCode +
        tokensOut.hashCode +
        costUsd.hashCode +
        lastSeq.hashCode +
        (startedAt == null ? 0 : startedAt.hashCode) +
        (endedAt == null ? 0 : endedAt.hashCode) +
        (error == null ? 0 : error.hashCode) +
        (traceId == null ? 0 : traceId.hashCode) +
        createdAt.hashCode;

  factory Run.fromJson(Map<String, dynamic> json) => _$RunFromJson(json);

  Map<String, dynamic> toJson() => _$RunToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

