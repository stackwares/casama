//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_cancelled_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunCancelledEventPayload {
  /// Returns a new [RunCancelledEventPayload] instance.
  RunCancelledEventPayload({

    required  this.cancelledBy,
  });

  @JsonKey(
    
    name: r'cancelled_by',
    required: true,
    includeIfNull: true,
  )


  final String? cancelledBy;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunCancelledEventPayload &&
      other.cancelledBy == cancelledBy;

    @override
    int get hashCode =>
        (cancelledBy == null ? 0 : cancelledBy.hashCode);

  factory RunCancelledEventPayload.fromJson(Map<String, dynamic> json) => _$RunCancelledEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$RunCancelledEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

