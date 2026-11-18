//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/takeover_requested_event_payload.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'takeover_requested_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeoverRequestedEvent {
  /// Returns a new [TakeoverRequestedEvent] instance.
  TakeoverRequestedEvent({

    required  this.v,

    required  this.runId,

    required  this.seq,

    required  this.ts,

    required  this.botId,

    required  this.type,

    required  this.payload,
  });

      /// Protocol version, currently 1
          // minimum: 1
  @JsonKey(
    
    name: r'v',
    required: true,
    includeIfNull: false,
  )


  final int v;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



          // minimum: 0
  @JsonKey(
    
    name: r'seq',
    required: true,
    includeIfNull: false,
  )


  final int seq;



  @JsonKey(
    
    name: r'ts',
    required: true,
    includeIfNull: false,
  )


  final DateTime ts;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final TakeoverRequestedEventTypeEnum type;



  @JsonKey(
    
    name: r'payload',
    required: true,
    includeIfNull: false,
  )


  final TakeoverRequestedEventPayload payload;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeoverRequestedEvent &&
      other.v == v &&
      other.runId == runId &&
      other.seq == seq &&
      other.ts == ts &&
      other.botId == botId &&
      other.type == type &&
      other.payload == payload;

    @override
    int get hashCode =>
        v.hashCode +
        runId.hashCode +
        seq.hashCode +
        ts.hashCode +
        botId.hashCode +
        type.hashCode +
        payload.hashCode;

  factory TakeoverRequestedEvent.fromJson(Map<String, dynamic> json) => _$TakeoverRequestedEventFromJson(json);

  Map<String, dynamic> toJson() => _$TakeoverRequestedEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TakeoverRequestedEventTypeEnum {
@JsonValue(r'takeover.requested')
takeoverPeriodRequested(r'takeover.requested');

const TakeoverRequestedEventTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


