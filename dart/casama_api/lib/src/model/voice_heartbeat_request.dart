//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/voice_heartbeat_request_usage.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_heartbeat_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceHeartbeatRequest {
  /// Returns a new [VoiceHeartbeatRequest] instance.
  VoiceHeartbeatRequest({

     this.usage,
  });

  @JsonKey(
    
    name: r'usage',
    required: false,
    includeIfNull: false,
  )


  final VoiceHeartbeatRequestUsage? usage;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceHeartbeatRequest &&
      other.usage == usage;

    @override
    int get hashCode =>
        usage.hashCode;

  factory VoiceHeartbeatRequest.fromJson(Map<String, dynamic> json) => _$VoiceHeartbeatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceHeartbeatRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

