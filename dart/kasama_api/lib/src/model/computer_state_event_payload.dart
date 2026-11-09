//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_state_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerStateEventPayload {
  /// Returns a new [ComputerStateEventPayload] instance.
  ComputerStateEventPayload({

    required  this.computerId,

    required  this.state,
  });

  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final ComputerStateEventPayloadStateEnum state;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerStateEventPayload &&
      other.computerId == computerId &&
      other.state == state;

    @override
    int get hashCode =>
        computerId.hashCode +
        state.hashCode;

  factory ComputerStateEventPayload.fromJson(Map<String, dynamic> json) => _$ComputerStateEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerStateEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ComputerStateEventPayloadStateEnum {
@JsonValue(r'provisioning')
provisioning(r'provisioning'),
@JsonValue(r'starting')
starting(r'starting'),
@JsonValue(r'running')
running(r'running'),
@JsonValue(r'idle')
idle(r'idle'),
@JsonValue(r'sleeping')
sleeping(r'sleeping'),
@JsonValue(r'stopped')
stopped(r'stopped'),
@JsonValue(r'error')
error(r'error');

const ComputerStateEventPayloadStateEnum(this.value);

final String value;

@override
String toString() => value;
}


