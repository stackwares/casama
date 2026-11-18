//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/voice_turns_request_turns_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_turns_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceTurnsRequest {
  /// Returns a new [VoiceTurnsRequest] instance.
  VoiceTurnsRequest({

    required  this.liveCallId,

    required  this.turns,
  });

  @JsonKey(
    
    name: r'live_call_id',
    required: true,
    includeIfNull: false,
  )


  final String liveCallId;



  @JsonKey(
    
    name: r'turns',
    required: true,
    includeIfNull: false,
  )


  final List<VoiceTurnsRequestTurnsInner> turns;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceTurnsRequest &&
      other.liveCallId == liveCallId &&
      other.turns == turns;

    @override
    int get hashCode =>
        liveCallId.hashCode +
        turns.hashCode;

  factory VoiceTurnsRequest.fromJson(Map<String, dynamic> json) => _$VoiceTurnsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceTurnsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

