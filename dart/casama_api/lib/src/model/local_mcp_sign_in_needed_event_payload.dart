//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'local_mcp_sign_in_needed_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalMcpSignInNeededEventPayload {
  /// Returns a new [LocalMcpSignInNeededEventPayload] instance.
  LocalMcpSignInNeededEventPayload({

    required  this.integrationId,

    required  this.deviceId,

    required  this.server,

    required  this.label,

    required  this.botId,
  });

  @JsonKey(
    
    name: r'integration_id',
    required: true,
    includeIfNull: false,
  )


  final String integrationId;



  @JsonKey(
    
    name: r'device_id',
    required: true,
    includeIfNull: false,
  )


  final String deviceId;



  @JsonKey(
    
    name: r'server',
    required: true,
    includeIfNull: false,
  )


  final String server;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalMcpSignInNeededEventPayload &&
      other.integrationId == integrationId &&
      other.deviceId == deviceId &&
      other.server == server &&
      other.label == label &&
      other.botId == botId;

    @override
    int get hashCode =>
        integrationId.hashCode +
        deviceId.hashCode +
        server.hashCode +
        label.hashCode +
        botId.hashCode;

  factory LocalMcpSignInNeededEventPayload.fromJson(Map<String, dynamic> json) => _$LocalMcpSignInNeededEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$LocalMcpSignInNeededEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

