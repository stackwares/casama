import 'package:kasama_api/src/model/abuse_event.dart';
import 'package:kasama_api/src/model/abuse_event_list.dart';
import 'package:kasama_api/src/model/accepted.dart';
import 'package:kasama_api/src/model/account_deletion.dart';
import 'package:kasama_api/src/model/admin_org.dart';
import 'package:kasama_api/src/model/admin_org_list.dart';
import 'package:kasama_api/src/model/admin_overview.dart';
import 'package:kasama_api/src/model/admin_service.dart';
import 'package:kasama_api/src/model/admin_service_list.dart';
import 'package:kasama_api/src/model/admin_user.dart';
import 'package:kasama_api/src/model/admin_user_list.dart';
import 'package:kasama_api/src/model/app_catalog.dart';
import 'package:kasama_api/src/model/approval.dart';
import 'package:kasama_api/src/model/approval_decision_request.dart';
import 'package:kasama_api/src/model/approval_list.dart';
import 'package:kasama_api/src/model/approval_requested_event.dart';
import 'package:kasama_api/src/model/approval_requested_event_payload.dart';
import 'package:kasama_api/src/model/approval_resolved_event.dart';
import 'package:kasama_api/src/model/approval_resolved_event_payload.dart';
import 'package:kasama_api/src/model/attach_integration_request.dart';
import 'package:kasama_api/src/model/billing_summary.dart';
import 'package:kasama_api/src/model/billing_usage.dart';
import 'package:kasama_api/src/model/billing_usage_item.dart';
import 'package:kasama_api/src/model/bot.dart';
import 'package:kasama_api/src/model/bot_budget.dart';
import 'package:kasama_api/src/model/bot_list.dart';
import 'package:kasama_api/src/model/bot_secret_request.dart';
import 'package:kasama_api/src/model/bot_secret_request_list.dart';
import 'package:kasama_api/src/model/catalog_app.dart';
import 'package:kasama_api/src/model/catalog_app_api_key.dart';
import 'package:kasama_api/src/model/chat_gpt_sign_in_complete_request.dart';
import 'package:kasama_api/src/model/chat_gpt_sign_in_start.dart';
import 'package:kasama_api/src/model/chat_gpt_sign_in_start_request.dart';
import 'package:kasama_api/src/model/checkout_request.dart';
import 'package:kasama_api/src/model/checkpoint.dart';
import 'package:kasama_api/src/model/checkpoint_created_event.dart';
import 'package:kasama_api/src/model/checkpoint_created_event_payload.dart';
import 'package:kasama_api/src/model/checkpoint_list.dart';
import 'package:kasama_api/src/model/computer.dart';
import 'package:kasama_api/src/model/computer_file_entry.dart';
import 'package:kasama_api/src/model/computer_file_list.dart';
import 'package:kasama_api/src/model/computer_list.dart';
import 'package:kasama_api/src/model/computer_size.dart';
import 'package:kasama_api/src/model/computer_state_event.dart';
import 'package:kasama_api/src/model/computer_state_event_payload.dart';
import 'package:kasama_api/src/model/connect_app_request.dart';
import 'package:kasama_api/src/model/connect_app_response.dart';
import 'package:kasama_api/src/model/connect_flow_status.dart';
import 'package:kasama_api/src/model/connect_key.dart';
import 'package:kasama_api/src/model/connect_key_list.dart';
import 'package:kasama_api/src/model/conversation.dart';
import 'package:kasama_api/src/model/conversation_list.dart';
import 'package:kasama_api/src/model/create_bot_request.dart';
import 'package:kasama_api/src/model/create_checkpoint_request.dart';
import 'package:kasama_api/src/model/create_computer_request.dart';
import 'package:kasama_api/src/model/create_connect_key_request.dart';
import 'package:kasama_api/src/model/create_conversation_request.dart';
import 'package:kasama_api/src/model/create_credential_request.dart';
import 'package:kasama_api/src/model/create_integration_request.dart';
import 'package:kasama_api/src/model/create_invite_link_request.dart';
import 'package:kasama_api/src/model/create_invite_request.dart';
import 'package:kasama_api/src/model/create_local_device_request.dart';
import 'package:kasama_api/src/model/create_organization_request.dart';
import 'package:kasama_api/src/model/create_routine_request.dart';
import 'package:kasama_api/src/model/create_secret_request.dart';
import 'package:kasama_api/src/model/create_task_comment_request.dart';
import 'package:kasama_api/src/model/create_task_request.dart';
import 'package:kasama_api/src/model/created_connect_key.dart';
import 'package:kasama_api/src/model/created_invite_link.dart';
import 'package:kasama_api/src/model/created_local_device.dart';
import 'package:kasama_api/src/model/created_routine.dart';
import 'package:kasama_api/src/model/credential.dart';
import 'package:kasama_api/src/model/credential_list.dart';
import 'package:kasama_api/src/model/credential_test_result.dart';
import 'package:kasama_api/src/model/credit_entry.dart';
import 'package:kasama_api/src/model/credit_pack.dart';
import 'package:kasama_api/src/model/delete_account_request.dart';
import 'package:kasama_api/src/model/delete_integration200_response.dart';
import 'package:kasama_api/src/model/delete_result.dart';
import 'package:kasama_api/src/model/deleted_computer.dart';
import 'package:kasama_api/src/model/deleted_device.dart';
import 'package:kasama_api/src/model/deleted_id.dart';
import 'package:kasama_api/src/model/deleted_routine.dart';
import 'package:kasama_api/src/model/fulfill_secret_request_body.dart';
import 'package:kasama_api/src/model/health.dart';
import 'package:kasama_api/src/model/ice_server.dart';
import 'package:kasama_api/src/model/integration.dart';
import 'package:kasama_api/src/model/integration_device.dart';
import 'package:kasama_api/src/model/integration_list.dart';
import 'package:kasama_api/src/model/integration_test_result.dart';
import 'package:kasama_api/src/model/integration_tools_inner.dart';
import 'package:kasama_api/src/model/invite.dart';
import 'package:kasama_api/src/model/invite_link.dart';
import 'package:kasama_api/src/model/invite_link_list.dart';
import 'package:kasama_api/src/model/lease.dart';
import 'package:kasama_api/src/model/lease_changed_event.dart';
import 'package:kasama_api/src/model/lease_changed_event_payload.dart';
import 'package:kasama_api/src/model/local_capabilities.dart';
import 'package:kasama_api/src/model/local_device.dart';
import 'package:kasama_api/src/model/local_device_list.dart';
import 'package:kasama_api/src/model/local_mcp_integration_list.dart';
import 'package:kasama_api/src/model/local_mcp_server_info.dart';
import 'package:kasama_api/src/model/me.dart';
import 'package:kasama_api/src/model/membership.dart';
import 'package:kasama_api/src/model/memory.dart';
import 'package:kasama_api/src/model/memory_list.dart';
import 'package:kasama_api/src/model/memory_written_event.dart';
import 'package:kasama_api/src/model/memory_written_event_payload.dart';
import 'package:kasama_api/src/model/message_attachment.dart';
import 'package:kasama_api/src/model/message_completed_event.dart';
import 'package:kasama_api/src/model/message_completed_event_payload.dart';
import 'package:kasama_api/src/model/message_delta_event.dart';
import 'package:kasama_api/src/model/message_delta_event_payload.dart';
import 'package:kasama_api/src/model/model_choice.dart';
import 'package:kasama_api/src/model/model_fallback_event.dart';
import 'package:kasama_api/src/model/model_fallback_event_payload.dart';
import 'package:kasama_api/src/model/model_option.dart';
import 'package:kasama_api/src/model/model_option_list.dart';
import 'package:kasama_api/src/model/model_policy.dart';
import 'package:kasama_api/src/model/ok.dart';
import 'package:kasama_api/src/model/org_settings.dart';
import 'package:kasama_api/src/model/organization.dart';
import 'package:kasama_api/src/model/organization_list.dart';
import 'package:kasama_api/src/model/organization_with_role.dart';
import 'package:kasama_api/src/model/plan.dart';
import 'package:kasama_api/src/model/plan_catalog.dart';
import 'package:kasama_api/src/model/portal_request.dart';
import 'package:kasama_api/src/model/problem.dart';
import 'package:kasama_api/src/model/problem_errors_inner.dart';
import 'package:kasama_api/src/model/provider_account.dart';
import 'package:kasama_api/src/model/provider_account_list.dart';
import 'package:kasama_api/src/model/provider_app.dart';
import 'package:kasama_api/src/model/provider_app_list.dart';
import 'package:kasama_api/src/model/provider_connect_request.dart';
import 'package:kasama_api/src/model/provider_connect_response.dart';
import 'package:kasama_api/src/model/public_config.dart';
import 'package:kasama_api/src/model/purchase_request.dart';
import 'package:kasama_api/src/model/redirect_url.dart';
import 'package:kasama_api/src/model/release_lease_request.dart';
import 'package:kasama_api/src/model/revoked_connect_key.dart';
import 'package:kasama_api/src/model/routine.dart';
import 'package:kasama_api/src/model/routine_list.dart';
import 'package:kasama_api/src/model/run.dart';
import 'package:kasama_api/src/model/run_cancelled_event.dart';
import 'package:kasama_api/src/model/run_cancelled_event_payload.dart';
import 'package:kasama_api/src/model/run_completed_event.dart';
import 'package:kasama_api/src/model/run_completed_event_payload.dart';
import 'package:kasama_api/src/model/run_error.dart';
import 'package:kasama_api/src/model/run_event_envelope.dart';
import 'package:kasama_api/src/model/run_events_page.dart';
import 'package:kasama_api/src/model/run_failed_event.dart';
import 'package:kasama_api/src/model/run_failed_event_payload.dart';
import 'package:kasama_api/src/model/run_started.dart';
import 'package:kasama_api/src/model/run_started_event.dart';
import 'package:kasama_api/src/model/run_started_event_payload.dart';
import 'package:kasama_api/src/model/saved_count.dart';
import 'package:kasama_api/src/model/secret.dart';
import 'package:kasama_api/src/model/secret_list.dart';
import 'package:kasama_api/src/model/secret_requested_event.dart';
import 'package:kasama_api/src/model/secret_requested_event_payload.dart';
import 'package:kasama_api/src/model/secret_resolved_event.dart';
import 'package:kasama_api/src/model/secret_resolved_event_payload.dart';
import 'package:kasama_api/src/model/send_message_request.dart';
import 'package:kasama_api/src/model/send_message_response.dart';
import 'package:kasama_api/src/model/set_local_mcp_servers_request.dart';
import 'package:kasama_api/src/model/set_org_limits_request.dart';
import 'package:kasama_api/src/model/signup_challenge.dart';
import 'package:kasama_api/src/model/skill_loaded_event.dart';
import 'package:kasama_api/src/model/skill_loaded_event_payload.dart';
import 'package:kasama_api/src/model/stream_session.dart';
import 'package:kasama_api/src/model/stream_session_request.dart';
import 'package:kasama_api/src/model/subrun_completed_event.dart';
import 'package:kasama_api/src/model/subrun_completed_event_payload.dart';
import 'package:kasama_api/src/model/subrun_started_event.dart';
import 'package:kasama_api/src/model/subrun_started_event_payload.dart';
import 'package:kasama_api/src/model/subscription.dart';
import 'package:kasama_api/src/model/suspend_org_request.dart';
import 'package:kasama_api/src/model/take_lease_request.dart';
import 'package:kasama_api/src/model/takeover_request.dart';
import 'package:kasama_api/src/model/takeover_request_list.dart';
import 'package:kasama_api/src/model/takeover_requested_event.dart';
import 'package:kasama_api/src/model/takeover_requested_event_payload.dart';
import 'package:kasama_api/src/model/takeover_resolved_event.dart';
import 'package:kasama_api/src/model/takeover_resolved_event_payload.dart';
import 'package:kasama_api/src/model/task.dart';
import 'package:kasama_api/src/model/task_comment.dart';
import 'package:kasama_api/src/model/task_comment_list.dart';
import 'package:kasama_api/src/model/task_list.dart';
import 'package:kasama_api/src/model/template.dart';
import 'package:kasama_api/src/model/template_list.dart';
import 'package:kasama_api/src/model/template_routines_inner.dart';
import 'package:kasama_api/src/model/test_credential_request.dart';
import 'package:kasama_api/src/model/tool_completed_event.dart';
import 'package:kasama_api/src/model/tool_completed_event_payload.dart';
import 'package:kasama_api/src/model/tool_failed_event.dart';
import 'package:kasama_api/src/model/tool_failed_event_payload.dart';
import 'package:kasama_api/src/model/tool_output_event.dart';
import 'package:kasama_api/src/model/tool_output_event_payload.dart';
import 'package:kasama_api/src/model/tool_started_event.dart';
import 'package:kasama_api/src/model/tool_started_event_payload.dart';
import 'package:kasama_api/src/model/transcription.dart';
import 'package:kasama_api/src/model/ui_action_part.dart';
import 'package:kasama_api/src/model/ui_shown_event.dart';
import 'package:kasama_api/src/model/ui_shown_event_payload.dart';
import 'package:kasama_api/src/model/update_computer_request.dart';
import 'package:kasama_api/src/model/update_credential_request.dart';
import 'package:kasama_api/src/model/update_integration_request.dart';
import 'package:kasama_api/src/model/update_local_device_request.dart';
import 'package:kasama_api/src/model/update_notice.dart';
import 'package:kasama_api/src/model/update_org_settings_request.dart';
import 'package:kasama_api/src/model/update_organization_request.dart';
import 'package:kasama_api/src/model/update_routine_request.dart';
import 'package:kasama_api/src/model/update_task_request.dart';
import 'package:kasama_api/src/model/upload_result.dart';
import 'package:kasama_api/src/model/usage_event.dart';
import 'package:kasama_api/src/model/usage_event_payload.dart';
import 'package:kasama_api/src/model/usage_report.dart';
import 'package:kasama_api/src/model/usage_report_by_bot_inner.dart';
import 'package:kasama_api/src/model/usage_report_by_day_inner.dart';
import 'package:kasama_api/src/model/usage_report_by_kind_inner.dart';
import 'package:kasama_api/src/model/usage_report_by_model_inner.dart';
import 'package:kasama_api/src/model/voice_session.dart';
import 'package:kasama_api/src/model/voice_session_request.dart';
import 'package:kasama_api/src/model/voice_tool_request.dart';
import 'package:kasama_api/src/model/voice_tool_result.dart';
import 'package:kasama_api/src/model/voice_transcript_request.dart';
import 'package:kasama_api/src/model/voice_transcript_request_turns_inner.dart';
import 'package:kasama_api/src/model/wallpaper_download_request.dart';
import 'package:kasama_api/src/model/wallpaper_photo.dart';
import 'package:kasama_api/src/model/wallpaper_photo_list.dart';
import 'package:kasama_api/src/model/workspace_badge.dart';
import 'package:kasama_api/src/model/workspace_badge_list.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

  ReturnType deserialize<ReturnType, BaseType>(dynamic value, String targetType, {bool growable= true}) {
      switch (targetType) {
        case 'String':
          return '$value' as ReturnType;
        case 'int':
          return (value is int ? value : int.parse('$value')) as ReturnType;
        case 'bool':
          if (value is bool) {
            return value as ReturnType;
          }
          final valueString = '$value'.toLowerCase();
          return (valueString == 'true' || valueString == '1') as ReturnType;
        case 'double':
          return (value is double ? value : double.parse('$value')) as ReturnType;
        case 'AbuseEvent':
          return AbuseEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AbuseEventList':
          return AbuseEventList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Accepted':
          return Accepted.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AccountDeletion':
          return AccountDeletion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminOrg':
          return AdminOrg.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminOrgList':
          return AdminOrgList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminOverview':
          return AdminOverview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminService':
          return AdminService.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminServiceList':
          return AdminServiceList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminUser':
          return AdminUser.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminUserList':
          return AdminUserList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppCatalog':
          return AppCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Approval':
          return Approval.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovalDecisionRequest':
          return ApprovalDecisionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovalList':
          return ApprovalList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovalRequestedEvent':
          return ApprovalRequestedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovalRequestedEventPayload':
          return ApprovalRequestedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovalResolvedEvent':
          return ApprovalResolvedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovalResolvedEventPayload':
          return ApprovalResolvedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AttachIntegrationRequest':
          return AttachIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Autonomy':
          
          
        case 'BillingSource':
          
          
        case 'BillingSummary':
          return BillingSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingUsage':
          return BillingUsage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingUsageItem':
          return BillingUsageItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Bot':
          return Bot.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotBudget':
          return BotBudget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotList':
          return BotList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotSecretRequest':
          return BotSecretRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotSecretRequestList':
          return BotSecretRequestList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogApp':
          return CatalogApp.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogAppApiKey':
          return CatalogAppApiKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatGptSignInCompleteRequest':
          return ChatGptSignInCompleteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatGptSignInStart':
          return ChatGptSignInStart.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatGptSignInStartRequest':
          return ChatGptSignInStartRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckoutRequest':
          return CheckoutRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Checkpoint':
          return Checkpoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckpointCreatedEvent':
          return CheckpointCreatedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckpointCreatedEventPayload':
          return CheckpointCreatedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckpointList':
          return CheckpointList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Computer':
          return Computer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerFileEntry':
          return ComputerFileEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerFileList':
          return ComputerFileList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerList':
          return ComputerList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerSize':
          return ComputerSize.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerState':
          
          
        case 'ComputerStateEvent':
          return ComputerStateEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerStateEventPayload':
          return ComputerStateEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectAppRequest':
          return ConnectAppRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectAppResponse':
          return ConnectAppResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectFlowStatus':
          return ConnectFlowStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectKey':
          return ConnectKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectKeyList':
          return ConnectKeyList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Conversation':
          return Conversation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConversationList':
          return ConversationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateBotRequest':
          return CreateBotRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateCheckpointRequest':
          return CreateCheckpointRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateComputerRequest':
          return CreateComputerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateConnectKeyRequest':
          return CreateConnectKeyRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateConversationRequest':
          return CreateConversationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateCredentialRequest':
          return CreateCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateIntegrationRequest':
          return CreateIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteLinkRequest':
          return CreateInviteLinkRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteRequest':
          return CreateInviteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateLocalDeviceRequest':
          return CreateLocalDeviceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateOrganizationRequest':
          return CreateOrganizationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateRoutineRequest':
          return CreateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateSecretRequest':
          return CreateSecretRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateTaskCommentRequest':
          return CreateTaskCommentRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateTaskRequest':
          return CreateTaskRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedConnectKey':
          return CreatedConnectKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedInviteLink':
          return CreatedInviteLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedLocalDevice':
          return CreatedLocalDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedRoutine':
          return CreatedRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Credential':
          return Credential.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CredentialList':
          return CredentialList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CredentialStatus':
          
          
        case 'CredentialTestResult':
          return CredentialTestResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreditEntry':
          return CreditEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreditPack':
          return CreditPack.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteAccountRequest':
          return DeleteAccountRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteIntegration200Response':
          return DeleteIntegration200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteResult':
          return DeleteResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedComputer':
          return DeletedComputer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedDevice':
          return DeletedDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedId':
          return DeletedId.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedRoutine':
          return DeletedRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FulfillSecretRequestBody':
          return FulfillSecretRequestBody.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Health':
          return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IceServer':
          return IceServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Integration':
          return Integration.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationDevice':
          return IntegrationDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationKind':
          
          
        case 'IntegrationList':
          return IntegrationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationTestResult':
          return IntegrationTestResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationToolsInner':
          return IntegrationToolsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Invite':
          return Invite.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteLink':
          return InviteLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteLinkList':
          return InviteLinkList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteRole':
          
          
        case 'Lease':
          return Lease.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LeaseChangedEvent':
          return LeaseChangedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LeaseChangedEventPayload':
          return LeaseChangedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalCapabilities':
          return LocalCapabilities.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalDevice':
          return LocalDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalDeviceList':
          return LocalDeviceList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalMcpIntegrationList':
          return LocalMcpIntegrationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalMcpServerInfo':
          return LocalMcpServerInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Me':
          return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Membership':
          return Membership.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Memory':
          return Memory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemoryList':
          return MemoryList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemoryWrittenEvent':
          return MemoryWrittenEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemoryWrittenEventPayload':
          return MemoryWrittenEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageAttachment':
          return MessageAttachment.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageCompletedEvent':
          return MessageCompletedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageCompletedEventPayload':
          return MessageCompletedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageDeltaEvent':
          return MessageDeltaEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageDeltaEventPayload':
          return MessageDeltaEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ModelChoice':
          return ModelChoice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ModelFallbackEvent':
          return ModelFallbackEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ModelFallbackEventPayload':
          return ModelFallbackEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ModelOption':
          return ModelOption.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ModelOptionList':
          return ModelOptionList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ModelPolicy':
          return ModelPolicy.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Ok':
          return Ok.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OrgRole':
          
          
        case 'OrgSettings':
          return OrgSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Organization':
          return Organization.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OrganizationList':
          return OrganizationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OrganizationWithRole':
          return OrganizationWithRole.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Plan':
          return Plan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanCatalog':
          return PlanCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PortalRequest':
          return PortalRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Problem':
          return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProblemErrorsInner':
          return ProblemErrorsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderAccount':
          return ProviderAccount.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderAccountList':
          return ProviderAccountList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderApp':
          return ProviderApp.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderAppList':
          return ProviderAppList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderConnectRequest':
          return ProviderConnectRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderConnectResponse':
          return ProviderConnectResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderId':
          
          
        case 'PublicConfig':
          return PublicConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PurchaseRequest':
          return PurchaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReasoningEffort':
          
          
        case 'RedirectUrl':
          return RedirectUrl.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReleaseLeaseRequest':
          return ReleaseLeaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RevokedConnectKey':
          return RevokedConnectKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Risk':
          
          
        case 'Routine':
          return Routine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RoutineList':
          return RoutineList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RoutineTrigger':
          
          
        case 'Run':
          return Run.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunCancelledEvent':
          return RunCancelledEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunCancelledEventPayload':
          return RunCancelledEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunCompletedEvent':
          return RunCompletedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunCompletedEventPayload':
          return RunCompletedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunError':
          return RunError.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunEventEnvelope':
          return RunEventEnvelope.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunEventsPage':
          return RunEventsPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunFailedEvent':
          return RunFailedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunFailedEventPayload':
          return RunFailedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStarted':
          return RunStarted.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStartedEvent':
          return RunStartedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStartedEventPayload':
          return RunStartedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStatus':
          
          
        case 'SavedCount':
          return SavedCount.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Secret':
          return Secret.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SecretKind':
          
          
        case 'SecretList':
          return SecretList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SecretRequestedEvent':
          return SecretRequestedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SecretRequestedEventPayload':
          return SecretRequestedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SecretResolvedEvent':
          return SecretResolvedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SecretResolvedEventPayload':
          return SecretResolvedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendMessageRequest':
          return SendMessageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendMessageResponse':
          return SendMessageResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetLocalMcpServersRequest':
          return SetLocalMcpServersRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetOrgLimitsRequest':
          return SetOrgLimitsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupChallenge':
          return SignupChallenge.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillLoadedEvent':
          return SkillLoadedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillLoadedEventPayload':
          return SkillLoadedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StreamMode':
          
          
        case 'StreamSession':
          return StreamSession.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StreamSessionRequest':
          return StreamSessionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SubrunCompletedEvent':
          return SubrunCompletedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SubrunCompletedEventPayload':
          return SubrunCompletedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SubrunStartedEvent':
          return SubrunStartedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SubrunStartedEventPayload':
          return SubrunStartedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Subscription':
          return Subscription.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SuspendOrgRequest':
          return SuspendOrgRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeLeaseRequest':
          return TakeLeaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeoverRequest':
          return TakeoverRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeoverRequestList':
          return TakeoverRequestList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeoverRequestedEvent':
          return TakeoverRequestedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeoverRequestedEventPayload':
          return TakeoverRequestedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeoverResolvedEvent':
          return TakeoverResolvedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeoverResolvedEventPayload':
          return TakeoverResolvedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Task':
          return Task.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskComment':
          return TaskComment.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskCommentList':
          return TaskCommentList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskList':
          return TaskList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TaskPriority':
          
          
        case 'TaskStatus':
          
          
        case 'Template':
          return Template.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TemplateList':
          return TemplateList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TemplateRoutinesInner':
          return TemplateRoutinesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TestCredentialRequest':
          return TestCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolCompletedEvent':
          return ToolCompletedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolCompletedEventPayload':
          return ToolCompletedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolFailedEvent':
          return ToolFailedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolFailedEventPayload':
          return ToolFailedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolOutputEvent':
          return ToolOutputEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolOutputEventPayload':
          return ToolOutputEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolStartedEvent':
          return ToolStartedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ToolStartedEventPayload':
          return ToolStartedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Transcription':
          return Transcription.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UiActionPart':
          return UiActionPart.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UiShownEvent':
          return UiShownEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UiShownEventPayload':
          return UiShownEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateComputerRequest':
          return UpdateComputerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateCredentialRequest':
          return UpdateCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateIntegrationRequest':
          return UpdateIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateLocalDeviceRequest':
          return UpdateLocalDeviceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateNotice':
          return UpdateNotice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateOrgSettingsRequest':
          return UpdateOrgSettingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateOrganizationRequest':
          return UpdateOrganizationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateRoutineRequest':
          return UpdateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateTaskRequest':
          return UpdateTaskRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UploadResult':
          return UploadResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageEvent':
          return UsageEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageEventPayload':
          return UsageEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageReport':
          return UsageReport.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageReportByBotInner':
          return UsageReportByBotInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageReportByDayInner':
          return UsageReportByDayInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageReportByKindInner':
          return UsageReportByKindInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageReportByModelInner':
          return UsageReportByModelInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Visibility':
          
          
        case 'VoiceSession':
          return VoiceSession.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceSessionRequest':
          return VoiceSessionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceToolRequest':
          return VoiceToolRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceToolResult':
          return VoiceToolResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceTranscriptRequest':
          return VoiceTranscriptRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceTranscriptRequestTurnsInner':
          return VoiceTranscriptRequestTurnsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WallpaperDownloadRequest':
          return WallpaperDownloadRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WallpaperPhoto':
          return WallpaperPhoto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WallpaperPhotoList':
          return WallpaperPhotoList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceBadge':
          return WorkspaceBadge.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceBadgeList':
          return WorkspaceBadgeList.fromJson(value as Map<String, dynamic>) as ReturnType;
        default:
          RegExpMatch? match;

          if (value is List && (match = _regList.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toList(growable: growable) as ReturnType;
          }
          if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
            targetType = match![1]!; // ignore: parameter_assignments
            return value
              .map<BaseType>((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable))
              .toSet() as ReturnType;
          }
          if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
            targetType = match![1]!.trim(); // ignore: parameter_assignments
            return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map((dynamic v) => deserialize<BaseType, BaseType>(v, targetType, growable: growable)),
            ) as ReturnType;
          }
          break;
    }
    throw Exception('Cannot deserialize');
  }