//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_heartbeat.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceHeartbeat {
  /// Returns a new [VoiceHeartbeat] instance.
  VoiceHeartbeat({

    required  this.ended,
  });

      /// The server already ended this call (no heartbeat in time); the app should hang up
  @JsonKey(
    
    name: r'ended',
    required: true,
    includeIfNull: false,
  )


  final bool ended;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceHeartbeat &&
      other.ended == ended;

    @override
    int get hashCode =>
        ended.hashCode;

  factory VoiceHeartbeat.fromJson(Map<String, dynamic> json) => _$VoiceHeartbeatFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceHeartbeatToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

