//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_config_key_providers.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicConfigKeyProviders {
  /// Returns a new [PublicConfigKeyProviders] instance.
  PublicConfigKeyProviders({

    required  this.chat,

    required  this.more,

    required  this.cloud,

    required  this.runsChat,

     this.hints,
  });

  @JsonKey(
    
    name: r'chat',
    required: true,
    includeIfNull: false,
  )


  final List<String> chat;



  @JsonKey(
    
    name: r'more',
    required: true,
    includeIfNull: false,
  )


  final List<String> more;



  @JsonKey(
    
    name: r'cloud',
    required: true,
    includeIfNull: false,
  )


  final List<String> cloud;



  @JsonKey(
    
    name: r'runs_chat',
    required: true,
    includeIfNull: false,
  )


  final List<String> runsChat;



  @JsonKey(
    
    name: r'hints',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? hints;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicConfigKeyProviders &&
      other.chat == chat &&
      other.more == more &&
      other.cloud == cloud &&
      other.runsChat == runsChat &&
      other.hints == hints;

    @override
    int get hashCode =>
        chat.hashCode +
        more.hashCode +
        cloud.hashCode +
        runsChat.hashCode +
        hints.hashCode;

  factory PublicConfigKeyProviders.fromJson(Map<String, dynamic> json) => _$PublicConfigKeyProvidersFromJson(json);

  Map<String, dynamic> toJson() => _$PublicConfigKeyProvidersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

