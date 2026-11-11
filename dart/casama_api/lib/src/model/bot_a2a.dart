//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_a2a.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotA2a {
  /// Returns a new [BotA2a] instance.
  BotA2a({

    required  this.workspaceEnabled,

    required  this.published,

    required  this.agentCardUrl,
  });

  @JsonKey(
    
    name: r'workspace_enabled',
    required: true,
    includeIfNull: false,
  )


  final bool workspaceEnabled;



  @JsonKey(
    
    name: r'published',
    required: true,
    includeIfNull: false,
  )


  final bool published;



  @JsonKey(
    
    name: r'agent_card_url',
    required: true,
    includeIfNull: false,
  )


  final String agentCardUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotA2a &&
      other.workspaceEnabled == workspaceEnabled &&
      other.published == published &&
      other.agentCardUrl == agentCardUrl;

    @override
    int get hashCode =>
        workspaceEnabled.hashCode +
        published.hashCode +
        agentCardUrl.hashCode;

  factory BotA2a.fromJson(Map<String, dynamic> json) => _$BotA2aFromJson(json);

  Map<String, dynamic> toJson() => _$BotA2aToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

