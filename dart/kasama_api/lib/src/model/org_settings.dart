//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'org_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrgSettings {
  /// Returns a new [OrgSettings] instance.
  OrgSettings({

    required  this.runEventRetentionDays,

    required  this.requireMfa,

    required  this.mcpDecideApprovals,

    required  this.llmTracing,
  });

          // minimum: 7
          // maximum: 3650
  @JsonKey(
    
    name: r'run_event_retention_days',
    required: true,
    includeIfNull: false,
  )


  final int runEventRetentionDays;



      /// Owners and admins must use two-step sign-in (turning it on needs an aal2 session)
  @JsonKey(
    
    name: r'require_mfa',
    required: true,
    includeIfNull: false,
  )


  final bool requireMfa;



      /// Allow approving or denying actions from AI apps connected over MCP (D-117)
  @JsonKey(
    
    name: r'mcp_decide_approvals',
    required: true,
    includeIfNull: false,
  )


  final bool mcpDecideApprovals;



      /// Send model calls to the server's Langfuse, secrets redacted (D-107); no effect without Langfuse
  @JsonKey(
    
    name: r'llm_tracing',
    required: true,
    includeIfNull: false,
  )


  final bool llmTracing;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OrgSettings &&
      other.runEventRetentionDays == runEventRetentionDays &&
      other.requireMfa == requireMfa &&
      other.mcpDecideApprovals == mcpDecideApprovals &&
      other.llmTracing == llmTracing;

    @override
    int get hashCode =>
        runEventRetentionDays.hashCode +
        requireMfa.hashCode +
        mcpDecideApprovals.hashCode +
        llmTracing.hashCode;

  factory OrgSettings.fromJson(Map<String, dynamic> json) => _$OrgSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$OrgSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

