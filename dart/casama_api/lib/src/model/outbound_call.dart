//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/outbound_call_transcript_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'outbound_call.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OutboundCall {
  /// Returns a new [OutboundCall] instance.
  OutboundCall({

    required  this.id,

    required  this.botId,

    required  this.number,

    required  this.purpose,

    required  this.status,

    required  this.transcript,

    required  this.seconds,

    required  this.startedAt,

    required  this.endedAt,

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
    
    name: r'number',
    required: true,
    includeIfNull: false,
  )


  final String number;



  @JsonKey(
    
    name: r'purpose',
    required: true,
    includeIfNull: false,
  )


  final String purpose;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final OutboundCallStatusEnum status;



  @JsonKey(
    
    name: r'transcript',
    required: true,
    includeIfNull: false,
  )


  final List<OutboundCallTranscriptInner> transcript;



  @JsonKey(
    
    name: r'seconds',
    required: true,
    includeIfNull: true,
  )


  final int? seconds;



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
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OutboundCall &&
      other.id == id &&
      other.botId == botId &&
      other.number == number &&
      other.purpose == purpose &&
      other.status == status &&
      other.transcript == transcript &&
      other.seconds == seconds &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        number.hashCode +
        purpose.hashCode +
        status.hashCode +
        transcript.hashCode +
        (seconds == null ? 0 : seconds.hashCode) +
        (startedAt == null ? 0 : startedAt.hashCode) +
        (endedAt == null ? 0 : endedAt.hashCode) +
        createdAt.hashCode;

  factory OutboundCall.fromJson(Map<String, dynamic> json) => _$OutboundCallFromJson(json);

  Map<String, dynamic> toJson() => _$OutboundCallToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum OutboundCallStatusEnum {
@JsonValue(r'queued')
queued(r'queued'),
@JsonValue(r'ringing')
ringing(r'ringing'),
@JsonValue(r'in_progress')
inProgress(r'in_progress'),
@JsonValue(r'completed')
completed(r'completed'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'busy')
busy(r'busy'),
@JsonValue(r'no_answer')
noAnswer(r'no_answer'),
@JsonValue(r'ended_by_user')
endedByUser(r'ended_by_user'),
@JsonValue(r'taken_over')
takenOver(r'taken_over');

const OutboundCallStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


