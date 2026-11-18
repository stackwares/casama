//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_completed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunCompletedEventPayload {
  /// Returns a new [RunCompletedEventPayload] instance.
  RunCompletedEventPayload({

    required  this.finalMessageId,
  });

  @JsonKey(
    
    name: r'final_message_id',
    required: true,
    includeIfNull: true,
  )


  final String? finalMessageId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunCompletedEventPayload &&
      other.finalMessageId == finalMessageId;

    @override
    int get hashCode =>
        (finalMessageId == null ? 0 : finalMessageId.hashCode);

  factory RunCompletedEventPayload.fromJson(Map<String, dynamic> json) => _$RunCompletedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RunCompletedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

