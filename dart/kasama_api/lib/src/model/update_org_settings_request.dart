//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_org_settings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateOrgSettingsRequest {
  /// Returns a new [UpdateOrgSettingsRequest] instance.
  UpdateOrgSettingsRequest({

     this.runEventRetentionDays,

     this.requireMfa,

     this.mcpDecideApprovals,

     this.allowBotToBot,

     this.a2aEnabled,

     this.llmTracing,
  });

          // minimum: 7
          // maximum: 3650
  @JsonKey(
    
    name: r'run_event_retention_days',
    required: false,
    includeIfNull: false,
  )


  final int? runEventRetentionDays;



      /// Owners and admins must use two-step sign-in (turning it on needs an aal2 session)
  @JsonKey(
    
    name: r'require_mfa',
    required: false,
    includeIfNull: false,
  )


  final bool? requireMfa;



      /// Allow approving or denying actions from AI apps connected over MCP (D-117)
  @JsonKey(
    
    name: r'mcp_decide_approvals',
    required: false,
    includeIfNull: false,
  )


  final bool? mcpDecideApprovals;



      /// Bots may @mention, message and delegate to each other (D-133); subagents always work
  @JsonKey(
    
    name: r'allow_bot_to_bot',
    required: false,
    includeIfNull: false,
  )


  final bool? allowBotToBot;



      /// Bots the workspace chooses can be published as A2A agents, reachable with workspace API keys (D-140)
  @JsonKey(
    
    name: r'a2a_enabled',
    required: false,
    includeIfNull: false,
  )


  final bool? a2aEnabled;



      /// Send model calls to the server's Langfuse, secrets redacted (D-107); no effect without Langfuse
  @JsonKey(
    
    name: r'llm_tracing',
    required: false,
    includeIfNull: false,
  )


  final bool? llmTracing;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateOrgSettingsRequest &&
      other.runEventRetentionDays == runEventRetentionDays &&
      other.requireMfa == requireMfa &&
      other.mcpDecideApprovals == mcpDecideApprovals &&
      other.allowBotToBot == allowBotToBot &&
      other.a2aEnabled == a2aEnabled &&
      other.llmTracing == llmTracing;

    @override
    int get hashCode =>
        runEventRetentionDays.hashCode +
        requireMfa.hashCode +
        mcpDecideApprovals.hashCode +
        allowBotToBot.hashCode +
        a2aEnabled.hashCode +
        llmTracing.hashCode;

  factory UpdateOrgSettingsRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrgSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOrgSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

