//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/stream_mode.dart';
import 'package:casama_api/src/model/ice_server.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stream_session.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class StreamSession {
  /// Returns a new [StreamSession] instance.
  StreamSession({

    required  this.signalingUrl,

    required  this.token,

    required  this.mode,

    required  this.expiresAt,

    required  this.iceServers,

    required  this.iceTransportPolicy,

    required  this.screenshotUrl,
  });

      /// WebSocket URL (Neko signaling protocol, proxied by the API); includes the token
  @JsonKey(
    
    name: r'signaling_url',
    required: true,
    includeIfNull: false,
  )


  final String signalingUrl;



      /// Bound to you, this computer and the mode; 5 minutes
  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;



  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final StreamMode mode;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'ice_servers',
    required: true,
    includeIfNull: false,
  )


  final List<IceServer> iceServers;



  @JsonKey(
    
    name: r'ice_transport_policy',
    required: true,
    includeIfNull: false,
  )


  final StreamSessionIceTransportPolicyEnum iceTransportPolicy;



      /// Fallback: poll about once a second
  @JsonKey(
    
    name: r'screenshot_url',
    required: true,
    includeIfNull: false,
  )


  final String screenshotUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is StreamSession &&
      other.signalingUrl == signalingUrl &&
      other.token == token &&
      other.mode == mode &&
      other.expiresAt == expiresAt &&
      other.iceServers == iceServers &&
      other.iceTransportPolicy == iceTransportPolicy &&
      other.screenshotUrl == screenshotUrl;

    @override
    int get hashCode =>
        signalingUrl.hashCode +
        token.hashCode +
        mode.hashCode +
        expiresAt.hashCode +
        iceServers.hashCode +
        iceTransportPolicy.hashCode +
        screenshotUrl.hashCode;

  factory StreamSession.fromJson(Map<String, dynamic> json) => _$StreamSessionFromJson(json);

  Map<String, dynamic> toJson() => _$StreamSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum StreamSessionIceTransportPolicyEnum {
@JsonValue(r'all')
all(r'all'),
@JsonValue(r'relay')
relay(r'relay');

const StreamSessionIceTransportPolicyEnum(this.value);

final String value;

@override
String toString() => value;
}


