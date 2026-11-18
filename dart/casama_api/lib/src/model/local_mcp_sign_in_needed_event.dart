//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/local_mcp_sign_in_needed_event_payload.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_mcp_sign_in_needed_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalMcpSignInNeededEvent {
  /// Returns a new [LocalMcpSignInNeededEvent] instance.
  LocalMcpSignInNeededEvent({

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


  final LocalMcpSignInNeededEventTypeEnum type;



  @JsonKey(
    
    name: r'payload',
    required: true,
    includeIfNull: false,
  )


  final LocalMcpSignInNeededEventPayload payload;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalMcpSignInNeededEvent &&
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

  factory LocalMcpSignInNeededEvent.fromJson(Map<String, dynamic> json) => _$LocalMcpSignInNeededEventFromJson(json);

  Map<String, dynamic> toJson() => _$LocalMcpSignInNeededEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum LocalMcpSignInNeededEventTypeEnum {
@JsonValue(r'local_mcp.sign_in_needed')
localMcpPeriodSignInNeeded(r'local_mcp.sign_in_needed');

const LocalMcpSignInNeededEventTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


