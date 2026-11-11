//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subrun_completed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SubrunCompletedEventPayload {
  /// Returns a new [SubrunCompletedEventPayload] instance.
  SubrunCompletedEventPayload({

    required  this.childRunId,

    required  this.status,

    required  this.summary,
  });

  @JsonKey(
    
    name: r'child_run_id',
    required: true,
    includeIfNull: false,
  )


  final String childRunId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final SubrunCompletedEventPayloadStatusEnum status;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SubrunCompletedEventPayload &&
      other.childRunId == childRunId &&
      other.status == status &&
      other.summary == summary;

    @override
    int get hashCode =>
        childRunId.hashCode +
        status.hashCode +
        summary.hashCode;

  factory SubrunCompletedEventPayload.fromJson(Map<String, dynamic> json) => _$SubrunCompletedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SubrunCompletedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SubrunCompletedEventPayloadStatusEnum {
@JsonValue(r'completed')
completed(r'completed'),
@JsonValue(r'failed')
failed(r'failed'),
@JsonValue(r'cancelled')
cancelled(r'cancelled');

const SubrunCompletedEventPayloadStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


