//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkpoint_created_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckpointCreatedEventPayload {
  /// Returns a new [CheckpointCreatedEventPayload] instance.
  CheckpointCreatedEventPayload({

    required  this.checkpointId,

    required  this.label,
  });

  @JsonKey(
    
    name: r'checkpoint_id',
    required: true,
    includeIfNull: false,
  )


  final String checkpointId;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CheckpointCreatedEventPayload &&
      other.checkpointId == checkpointId &&
      other.label == label;

    @override
    int get hashCode =>
        checkpointId.hashCode +
        label.hashCode;

  factory CheckpointCreatedEventPayload.fromJson(Map<String, dynamic> json) => _$CheckpointCreatedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointCreatedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

