//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subrun_started_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubrunStartedEventPayload {
  /// Returns a new [SubrunStartedEventPayload] instance.
  SubrunStartedEventPayload({

    required  this.childRunId,

    required  this.botId,

    required  this.task,
  });

  @JsonKey(
    
    name: r'child_run_id',
    required: true,
    includeIfNull: false,
  )


  final String childRunId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'task',
    required: true,
    includeIfNull: false,
  )


  final String task;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SubrunStartedEventPayload &&
      other.childRunId == childRunId &&
      other.botId == botId &&
      other.task == task;

    @override
    int get hashCode =>
        childRunId.hashCode +
        botId.hashCode +
        task.hashCode;

  factory SubrunStartedEventPayload.fromJson(Map<String, dynamic> json) => _$SubrunStartedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SubrunStartedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

