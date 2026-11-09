//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_started_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunStartedEventPayload {
  /// Returns a new [RunStartedEventPayload] instance.
  RunStartedEventPayload({

    required  this.trigger,

    required  this.model,

    required  this.computerId,
  });

  @JsonKey(
    
    name: r'trigger',
    required: true,
    includeIfNull: false,
  )


  final String trigger;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;



  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: true,
  )


  final String? computerId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunStartedEventPayload &&
      other.trigger == trigger &&
      other.model == model &&
      other.computerId == computerId;

    @override
    int get hashCode =>
        trigger.hashCode +
        model.hashCode +
        (computerId == null ? 0 : computerId.hashCode);

  factory RunStartedEventPayload.fromJson(Map<String, dynamic> json) => _$RunStartedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RunStartedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

