//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/channel_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_channel_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateChannelRequest {
  /// Returns a new [CreateChannelRequest] instance.
  CreateChannelRequest({

    required  this.botId,

    required  this.kind,

    required  this.name,

     this.config,

     this.secrets,

    required  this.allowedSenders,
  });

  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ChannelKind kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'config',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? config;



  @JsonKey(
    
    name: r'secrets',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? secrets;



  @JsonKey(
    
    name: r'allowed_senders',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedSenders;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateChannelRequest &&
      other.botId == botId &&
      other.kind == kind &&
      other.name == name &&
      other.config == config &&
      other.secrets == secrets &&
      other.allowedSenders == allowedSenders;

    @override
    int get hashCode =>
        botId.hashCode +
        kind.hashCode +
        name.hashCode +
        config.hashCode +
        secrets.hashCode +
        allowedSenders.hashCode;

  factory CreateChannelRequest.fromJson(Map<String, dynamic> json) => _$CreateChannelRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateChannelRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

