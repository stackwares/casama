//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_session_limits.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VoiceSessionLimits {
  /// Returns a new [VoiceSessionLimits] instance.
  VoiceSessionLimits({

    required  this.silenceSeconds,

    required  this.heartbeatSeconds,

    required  this.maxCallSeconds,

    required  this.warningSeconds,

    required  this.appEndsAtMax,
  });

      /// Hang up after this long with nobody speaking and no job running
  @JsonKey(
    
    name: r'silence_seconds',
    required: true,
    includeIfNull: false,
  )


  final int silenceSeconds;



      /// Send a heartbeat this often; the server ends a call that stops sending them
  @JsonKey(
    
    name: r'heartbeat_seconds',
    required: true,
    includeIfNull: false,
  )


  final int heartbeatSeconds;



      /// The longest the call may run
  @JsonKey(
    
    name: r'max_call_seconds',
    required: true,
    includeIfNull: false,
  )


  final int maxCallSeconds;



      /// How long before max_call_seconds the bot should warn the person
  @JsonKey(
    
    name: r'warning_seconds',
    required: true,
    includeIfNull: false,
  )


  final int warningSeconds;



      /// True when the app must end the call at max_call_seconds itself (it isn't relayed); false when the server's relay does
  @JsonKey(
    
    name: r'app_ends_at_max',
    required: true,
    includeIfNull: false,
  )


  final bool appEndsAtMax;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VoiceSessionLimits &&
      other.silenceSeconds == silenceSeconds &&
      other.heartbeatSeconds == heartbeatSeconds &&
      other.maxCallSeconds == maxCallSeconds &&
      other.warningSeconds == warningSeconds &&
      other.appEndsAtMax == appEndsAtMax;

    @override
    int get hashCode =>
        silenceSeconds.hashCode +
        heartbeatSeconds.hashCode +
        maxCallSeconds.hashCode +
        warningSeconds.hashCode +
        appEndsAtMax.hashCode;

  factory VoiceSessionLimits.fromJson(Map<String, dynamic> json) => _$VoiceSessionLimitsFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSessionLimitsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

