//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'takeover_requested_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TakeoverRequestedEventPayload {
  /// Returns a new [TakeoverRequestedEventPayload] instance.
  TakeoverRequestedEventPayload({

    required  this.computerId,

    required  this.reason,
  });

  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TakeoverRequestedEventPayload &&
      other.computerId == computerId &&
      other.reason == reason;

    @override
    int get hashCode =>
        computerId.hashCode +
        reason.hashCode;

  factory TakeoverRequestedEventPayload.fromJson(Map<String, dynamic> json) => _$TakeoverRequestedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$TakeoverRequestedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

