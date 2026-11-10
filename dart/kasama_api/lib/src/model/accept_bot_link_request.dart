//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accept_bot_link_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcceptBotLinkRequest {
  /// Returns a new [AcceptBotLinkRequest] instance.
  AcceptBotLinkRequest({

    required  this.invite,

    required  this.botId,

    required  this.name,
  });

  @JsonKey(
    
    name: r'invite',
    required: true,
    includeIfNull: false,
  )


  final String invite;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AcceptBotLinkRequest &&
      other.invite == invite &&
      other.botId == botId &&
      other.name == name;

    @override
    int get hashCode =>
        invite.hashCode +
        botId.hashCode +
        name.hashCode;

  factory AcceptBotLinkRequest.fromJson(Map<String, dynamic> json) => _$AcceptBotLinkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptBotLinkRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

