import 'package:kasama_api/src/model/abuse_event.dart';
import 'package:kasama_api/src/model/abuse_event_list.dart';
import 'package:kasama_api/src/model/accepted.dart';
import 'package:kasama_api/src/model/accepted_suggestion.dart';
import 'package:kasama_api/src/model/account_deletion.dart';
import 'package:kasama_api/src/model/action_rule.dart';
import 'package:kasama_api/src/model/action_rule_list.dart';
import 'package:kasama_api/src/model/action_rule_target.dart';
import 'package:kasama_api/src/model/add_teach_step_request.dart';
import 'package:kasama_api/src/model/admin_org.dart';
import 'package:kasama_api/src/model/admin_org_list.dart';
import 'package:kasama_api/src/model/admin_overview.dart';
import 'package:kasama_api/src/model/admin_service.dart';
import 'package:kasama_api/src/model/admin_service_list.dart';
import 'package:kasama_api/src/model/admin_user.dart';
import 'package:kasama_api/src/model/admin_user_list.dart';
import 'package:kasama_api/src/model/agent_import_plan.dart';
import 'package:kasama_api/src/model/agent_import_plan_leftovers_inner.dart';
import 'package:kasama_api/src/model/agent_import_plan_skipped_inner.dart';
import 'package:kasama_api/src/model/agent_import_plan_sources.dart';
import 'package:kasama_api/src/model/app_catalog.dart';
import 'package:kasama_api/src/model/apply_skill_update_request.dart';
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
import 'package:kasama_api/src/model/bot_checkins.dart';
import 'package:kasama_api/src/model/bot_list.dart';
import 'package:kasama_api/src/model/bot_page.dart';
import 'package:kasama_api/src/model/bot_page_detail.dart';
import 'package:kasama_api/src/model/bot_secret_request.dart';
import 'package:kasama_api/src/model/bot_secret_request_list.dart';
import 'package:kasama_api/src/model/bot_share_link.dart';
import 'package:kasama_api/src/model/bot_template_file.dart';
import 'package:kasama_api/src/model/bot_template_file_connections_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_memories_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_routines_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_skills_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_skills_inner_files_inner.dart';
import 'package:kasama_api/src/model/catalog_app.dart';
import 'package:kasama_api/src/model/catalog_app_api_key.dart';
import 'package:kasama_api/src/model/catalog_skill.dart';
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
import 'package:kasama_api/src/model/create_action_rule_request.dart';
import 'package:kasama_api/src/model/create_bot_request.dart';
import 'package:kasama_api/src/model/create_bot_share_request.dart';
import 'package:kasama_api/src/model/create_checkpoint_request.dart';
import 'package:kasama_api/src/model/create_computer_request.dart';
import 'package:kasama_api/src/model/create_connect_key_request.dart';
import 'package:kasama_api/src/model/create_conversation_request.dart';
import 'package:kasama_api/src/model/create_credential_request.dart';
import 'package:kasama_api/src/model/create_integration_request.dart';
import 'package:kasama_api/src/model/create_invite_link_request.dart';
import 'package:kasama_api/src/model/create_invite_request.dart';
import 'package:kasama_api/src/model/create_knowledge_source_request.dart';
import 'package:kasama_api/src/model/create_knowledge_source_request_documents_inner.dart';
import 'package:kasama_api/src/model/create_knowledge_source_request_files_inner.dart';
import 'package:kasama_api/src/model/create_local_device_request.dart';
import 'package:kasama_api/src/model/create_mcp_key_request.dart';
import 'package:kasama_api/src/model/create_organization_request.dart';
import 'package:kasama_api/src/model/create_project_request.dart';
import 'package:kasama_api/src/model/create_routine_request.dart';
import 'package:kasama_api/src/model/create_secret_request.dart';
import 'package:kasama_api/src/model/create_task_comment_request.dart';
import 'package:kasama_api/src/model/create_task_request.dart';
import 'package:kasama_api/src/model/created_connect_key.dart';
import 'package:kasama_api/src/model/created_invite_link.dart';
import 'package:kasama_api/src/model/created_local_device.dart';
import 'package:kasama_api/src/model/created_mcp_key.dart';
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
import 'package:kasama_api/src/model/deleted_knowledge_source.dart';
import 'package:kasama_api/src/model/deleted_page.dart';
import 'package:kasama_api/src/model/deleted_plugin.dart';
import 'package:kasama_api/src/model/deleted_routine.dart';
import 'package:kasama_api/src/model/deleted_rule.dart';
import 'package:kasama_api/src/model/deleted_teach.dart';
import 'package:kasama_api/src/model/deleted_watcher.dart';
import 'package:kasama_api/src/model/dismiss_suggestion_request.dart';
import 'package:kasama_api/src/model/edit_message_request.dart';
import 'package:kasama_api/src/model/file_search_result.dart';
import 'package:kasama_api/src/model/for_you.dart';
import 'package:kasama_api/src/model/for_you_approval.dart';
import 'package:kasama_api/src/model/for_you_brief.dart';
import 'package:kasama_api/src/model/fulfill_secret_request_body.dart';
import 'package:kasama_api/src/model/git_hub_skill_preview.dart';
import 'package:kasama_api/src/model/git_hub_skill_preview_request.dart';
import 'package:kasama_api/src/model/git_sync_status.dart';
import 'package:kasama_api/src/model/group_chat_list.dart';
import 'package:kasama_api/src/model/health.dart';
import 'package:kasama_api/src/model/ice_server.dart';
import 'package:kasama_api/src/model/import_bot_request.dart';
import 'package:kasama_api/src/model/import_bot_response.dart';
import 'package:kasama_api/src/model/import_bot_response_connections_to_add_inner.dart';
import 'package:kasama_api/src/model/import_workspace_files_request.dart';
import 'package:kasama_api/src/model/imported_memory_item.dart';
import 'package:kasama_api/src/model/install_catalog_skill_request.dart';
import 'package:kasama_api/src/model/install_git_hub_skill_request.dart';
import 'package:kasama_api/src/model/install_plugin_request.dart';
import 'package:kasama_api/src/model/installed_plugin_server.dart';
import 'package:kasama_api/src/model/installed_plugin_server_all_of_tools.dart';
import 'package:kasama_api/src/model/installed_skill.dart';
import 'package:kasama_api/src/model/integration.dart';
import 'package:kasama_api/src/model/integration_device.dart';
import 'package:kasama_api/src/model/integration_list.dart';
import 'package:kasama_api/src/model/integration_test_result.dart';
import 'package:kasama_api/src/model/integration_tools_inner.dart';
import 'package:kasama_api/src/model/invite.dart';
import 'package:kasama_api/src/model/invite_link.dart';
import 'package:kasama_api/src/model/invite_link_list.dart';
import 'package:kasama_api/src/model/knowledge_source.dart';
import 'package:kasama_api/src/model/knowledge_source_list.dart';
import 'package:kasama_api/src/model/lease.dart';
import 'package:kasama_api/src/model/lease_changed_event.dart';
import 'package:kasama_api/src/model/lease_changed_event_payload.dart';
import 'package:kasama_api/src/model/local_capabilities.dart';
import 'package:kasama_api/src/model/local_device.dart';
import 'package:kasama_api/src/model/local_device_list.dart';
import 'package:kasama_api/src/model/local_mcp_integration_list.dart';
import 'package:kasama_api/src/model/local_mcp_server_info.dart';
import 'package:kasama_api/src/model/mark_teach_secret_request.dart';
import 'package:kasama_api/src/model/mcp_auth_request_info.dart';
import 'package:kasama_api/src/model/mcp_consent_request.dart';
import 'package:kasama_api/src/model/mcp_consent_result.dart';
import 'package:kasama_api/src/model/mcp_key.dart';
import 'package:kasama_api/src/model/mcp_key_list.dart';
import 'package:kasama_api/src/model/me.dart';
import 'package:kasama_api/src/model/membership.dart';
import 'package:kasama_api/src/model/memory.dart';
import 'package:kasama_api/src/model/memory_import_prompt.dart';
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
import 'package:kasama_api/src/model/page_list.dart';
import 'package:kasama_api/src/model/page_version.dart';
import 'package:kasama_api/src/model/page_view_link.dart';
import 'package:kasama_api/src/model/page_view_link_request.dart';
import 'package:kasama_api/src/model/parse_memory_import_request.dart';
import 'package:kasama_api/src/model/parsed_memory_import.dart';
import 'package:kasama_api/src/model/plan.dart';
import 'package:kasama_api/src/model/plan_catalog.dart';
import 'package:kasama_api/src/model/plugin.dart';
import 'package:kasama_api/src/model/plugin_list.dart';
import 'package:kasama_api/src/model/plugin_preview.dart';
import 'package:kasama_api/src/model/plugin_preview_skills_inner.dart';
import 'package:kasama_api/src/model/plugin_secret_info.dart';
import 'package:kasama_api/src/model/plugin_server_info.dart';
import 'package:kasama_api/src/model/plugin_skills_inner.dart';
import 'package:kasama_api/src/model/plugin_update_preview.dart';
import 'package:kasama_api/src/model/portal_request.dart';
import 'package:kasama_api/src/model/preview_plugin_request.dart';
import 'package:kasama_api/src/model/problem.dart';
import 'package:kasama_api/src/model/problem_errors_inner.dart';
import 'package:kasama_api/src/model/project.dart';
import 'package:kasama_api/src/model/project_detail.dart';
import 'package:kasama_api/src/model/project_list.dart';
import 'package:kasama_api/src/model/project_milestone.dart';
import 'package:kasama_api/src/model/project_run.dart';
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
import 'package:kasama_api/src/model/revert_page_request.dart';
import 'package:kasama_api/src/model/revoked_connect_key.dart';
import 'package:kasama_api/src/model/revoked_key.dart';
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
import 'package:kasama_api/src/model/save_imported_memories_request.dart';
import 'package:kasama_api/src/model/save_teach_request.dart';
import 'package:kasama_api/src/model/save_teach_response.dart';
import 'package:kasama_api/src/model/saved_count.dart';
import 'package:kasama_api/src/model/saved_imported_memories.dart';
import 'package:kasama_api/src/model/search_response.dart';
import 'package:kasama_api/src/model/search_result.dart';
import 'package:kasama_api/src/model/secret.dart';
import 'package:kasama_api/src/model/secret_list.dart';
import 'package:kasama_api/src/model/secret_requested_event.dart';
import 'package:kasama_api/src/model/secret_requested_event_payload.dart';
import 'package:kasama_api/src/model/secret_resolved_event.dart';
import 'package:kasama_api/src/model/secret_resolved_event_payload.dart';
import 'package:kasama_api/src/model/send_message_request.dart';
import 'package:kasama_api/src/model/send_message_response.dart';
import 'package:kasama_api/src/model/set_git_sync_request.dart';
import 'package:kasama_api/src/model/set_local_mcp_servers_request.dart';
import 'package:kasama_api/src/model/set_org_limits_request.dart';
import 'package:kasama_api/src/model/signup_challenge.dart';
import 'package:kasama_api/src/model/skill_catalog.dart';
import 'package:kasama_api/src/model/skill_loaded_event.dart';
import 'package:kasama_api/src/model/skill_loaded_event_payload.dart';
import 'package:kasama_api/src/model/skill_preview_file.dart';
import 'package:kasama_api/src/model/skill_update_check.dart';
import 'package:kasama_api/src/model/start_agent_import_request.dart';
import 'package:kasama_api/src/model/start_agent_import_request_files_inner.dart';
import 'package:kasama_api/src/model/start_setup_response.dart';
import 'package:kasama_api/src/model/start_teach_request.dart';
import 'package:kasama_api/src/model/stream_session.dart';
import 'package:kasama_api/src/model/stream_session_request.dart';
import 'package:kasama_api/src/model/subrun_completed_event.dart';
import 'package:kasama_api/src/model/subrun_completed_event_payload.dart';
import 'package:kasama_api/src/model/subrun_started_event.dart';
import 'package:kasama_api/src/model/subrun_started_event_payload.dart';
import 'package:kasama_api/src/model/subscription.dart';
import 'package:kasama_api/src/model/suggestion.dart';
import 'package:kasama_api/src/model/suggestion_proposed_action.dart';
import 'package:kasama_api/src/model/suspend_org_request.dart';
import 'package:kasama_api/src/model/switch_branch_request.dart';
import 'package:kasama_api/src/model/switch_branch_response.dart';
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
import 'package:kasama_api/src/model/teach_draft.dart';
import 'package:kasama_api/src/model/teach_draft_inputs_inner.dart';
import 'package:kasama_api/src/model/teach_session.dart';
import 'package:kasama_api/src/model/teach_step.dart';
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
import 'package:kasama_api/src/model/update_page_request.dart';
import 'package:kasama_api/src/model/update_page_response.dart';
import 'package:kasama_api/src/model/update_plugin_request.dart';
import 'package:kasama_api/src/model/update_project_request.dart';
import 'package:kasama_api/src/model/update_routine_request.dart';
import 'package:kasama_api/src/model/update_task_request.dart';
import 'package:kasama_api/src/model/update_watcher_request.dart';
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
import 'package:kasama_api/src/model/watcher.dart';
import 'package:kasama_api/src/model/watcher_list.dart';
import 'package:kasama_api/src/model/workspace_badge.dart';
import 'package:kasama_api/src/model/workspace_badge_list.dart';
import 'package:kasama_api/src/model/workspace_files_export.dart';
import 'package:kasama_api/src/model/workspace_files_export_files_inner.dart';
import 'package:kasama_api/src/model/workspace_files_result.dart';
import 'package:kasama_api/src/model/write_agent_import_files_request.dart';
import 'package:kasama_api/src/model/write_agent_import_files_response.dart';

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
        case 'AcceptedSuggestion':
          return AcceptedSuggestion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AccountDeletion':
          return AccountDeletion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionRule':
          return ActionRule.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionRuleList':
          return ActionRuleList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionRuleTarget':
          return ActionRuleTarget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddTeachStepRequest':
          return AddTeachStepRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'AgentImportPlan':
          return AgentImportPlan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlanLeftoversInner':
          return AgentImportPlanLeftoversInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlanSkippedInner':
          return AgentImportPlanSkippedInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlanSources':
          return AgentImportPlanSources.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppCatalog':
          return AppCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApplySkillUpdateRequest':
          return ApplySkillUpdateRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'BotCheckins':
          return BotCheckins.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotList':
          return BotList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotPage':
          return BotPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotPageDetail':
          return BotPageDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotSecretRequest':
          return BotSecretRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotSecretRequestList':
          return BotSecretRequestList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotShareLink':
          return BotShareLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotTemplateFile':
          return BotTemplateFile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotTemplateFileConnectionsInner':
          return BotTemplateFileConnectionsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotTemplateFileMemoriesInner':
          return BotTemplateFileMemoriesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotTemplateFileRoutinesInner':
          return BotTemplateFileRoutinesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotTemplateFileSkillsInner':
          return BotTemplateFileSkillsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotTemplateFileSkillsInnerFilesInner':
          return BotTemplateFileSkillsInnerFilesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogApp':
          return CatalogApp.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogAppApiKey':
          return CatalogAppApiKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogSkill':
          return CatalogSkill.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'CreateActionRuleRequest':
          return CreateActionRuleRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateBotRequest':
          return CreateBotRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateBotShareRequest':
          return CreateBotShareRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'CreateKnowledgeSourceRequest':
          return CreateKnowledgeSourceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateKnowledgeSourceRequestDocumentsInner':
          return CreateKnowledgeSourceRequestDocumentsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateKnowledgeSourceRequestFilesInner':
          return CreateKnowledgeSourceRequestFilesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateLocalDeviceRequest':
          return CreateLocalDeviceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateMcpKeyRequest':
          return CreateMcpKeyRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateOrganizationRequest':
          return CreateOrganizationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateProjectRequest':
          return CreateProjectRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'CreatedMcpKey':
          return CreatedMcpKey.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'DeletedKnowledgeSource':
          return DeletedKnowledgeSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedPage':
          return DeletedPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedPlugin':
          return DeletedPlugin.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedRoutine':
          return DeletedRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedRule':
          return DeletedRule.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedTeach':
          return DeletedTeach.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedWatcher':
          return DeletedWatcher.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DismissSuggestionRequest':
          return DismissSuggestionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EditMessageRequest':
          return EditMessageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FileSearchResult':
          return FileSearchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForYou':
          return ForYou.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForYouApproval':
          return ForYouApproval.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ForYouBrief':
          return ForYouBrief.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'FulfillSecretRequestBody':
          return FulfillSecretRequestBody.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GitHubSkillPreview':
          return GitHubSkillPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GitHubSkillPreviewRequest':
          return GitHubSkillPreviewRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GitSyncStatus':
          return GitSyncStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GroupChatList':
          return GroupChatList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Health':
          return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IceServer':
          return IceServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportBotRequest':
          return ImportBotRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportBotResponse':
          return ImportBotResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportBotResponseConnectionsToAddInner':
          return ImportBotResponseConnectionsToAddInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportWorkspaceFilesRequest':
          return ImportWorkspaceFilesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportedMemoryItem':
          return ImportedMemoryItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstallCatalogSkillRequest':
          return InstallCatalogSkillRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstallGitHubSkillRequest':
          return InstallGitHubSkillRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstallPluginRequest':
          return InstallPluginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstalledPluginServer':
          return InstalledPluginServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstalledPluginServerAllOfTools':
          return InstalledPluginServerAllOfTools.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstalledSkill':
          return InstalledSkill.fromJson(value as Map<String, dynamic>) as ReturnType;
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
          
          
        case 'KnowledgeSource':
          return KnowledgeSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'KnowledgeSourceList':
          return KnowledgeSourceList.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'MarkTeachSecretRequest':
          return MarkTeachSecretRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpAuthRequestInfo':
          return McpAuthRequestInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpConsentRequest':
          return McpConsentRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpConsentResult':
          return McpConsentResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpKey':
          return McpKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpKeyList':
          return McpKeyList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Me':
          return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Membership':
          return Membership.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Memory':
          return Memory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemoryImportPrompt':
          return MemoryImportPrompt.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'PageList':
          return PageList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageVersion':
          return PageVersion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageViewLink':
          return PageViewLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageViewLinkRequest':
          return PageViewLinkRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ParseMemoryImportRequest':
          return ParseMemoryImportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ParsedMemoryImport':
          return ParsedMemoryImport.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Plan':
          return Plan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanCatalog':
          return PlanCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Plugin':
          return Plugin.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginList':
          return PluginList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginPreview':
          return PluginPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginPreviewSkillsInner':
          return PluginPreviewSkillsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginSecretInfo':
          return PluginSecretInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginServerInfo':
          return PluginServerInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginSkillsInner':
          return PluginSkillsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginUpdatePreview':
          return PluginUpdatePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PortalRequest':
          return PortalRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PreviewPluginRequest':
          return PreviewPluginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Problem':
          return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProblemErrorsInner':
          return ProblemErrorsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Project':
          return Project.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProjectDetail':
          return ProjectDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProjectList':
          return ProjectList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProjectMilestone':
          return ProjectMilestone.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProjectRun':
          return ProjectRun.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProjectStatus':
          
          
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
        case 'RevertPageRequest':
          return RevertPageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RevokedConnectKey':
          return RevokedConnectKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RevokedKey':
          return RevokedKey.fromJson(value as Map<String, dynamic>) as ReturnType;
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
          
          
        case 'SaveImportedMemoriesRequest':
          return SaveImportedMemoriesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveTeachRequest':
          return SaveTeachRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveTeachResponse':
          return SaveTeachResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavedCount':
          return SavedCount.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavedImportedMemories':
          return SavedImportedMemories.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchKind':
          
          
        case 'SearchResponse':
          return SearchResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchResult':
          return SearchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'SetGitSyncRequest':
          return SetGitSyncRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetLocalMcpServersRequest':
          return SetLocalMcpServersRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetOrgLimitsRequest':
          return SetOrgLimitsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupChallenge':
          return SignupChallenge.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillCatalog':
          return SkillCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillLoadedEvent':
          return SkillLoadedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillLoadedEventPayload':
          return SkillLoadedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillPreviewFile':
          return SkillPreviewFile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillUpdateCheck':
          return SkillUpdateCheck.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartAgentImportRequest':
          return StartAgentImportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartAgentImportRequestFilesInner':
          return StartAgentImportRequestFilesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartSetupResponse':
          return StartSetupResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartTeachRequest':
          return StartTeachRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'Suggestion':
          return Suggestion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SuggestionProposedAction':
          return SuggestionProposedAction.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SuspendOrgRequest':
          return SuspendOrgRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SwitchBranchRequest':
          return SwitchBranchRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SwitchBranchResponse':
          return SwitchBranchResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
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
          
          
        case 'TeachDraft':
          return TeachDraft.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TeachDraftInputsInner':
          return TeachDraftInputsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TeachSession':
          return TeachSession.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TeachStep':
          return TeachStep.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'UpdatePageRequest':
          return UpdatePageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePageResponse':
          return UpdatePageResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePluginRequest':
          return UpdatePluginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateProjectRequest':
          return UpdateProjectRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateRoutineRequest':
          return UpdateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateTaskRequest':
          return UpdateTaskRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateWatcherRequest':
          return UpdateWatcherRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'Watcher':
          return Watcher.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatcherList':
          return WatcherList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceBadge':
          return WorkspaceBadge.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceBadgeList':
          return WorkspaceBadgeList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceFilesExport':
          return WorkspaceFilesExport.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceFilesExportFilesInner':
          return WorkspaceFilesExportFilesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceFilesResult':
          return WorkspaceFilesResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WriteAgentImportFilesRequest':
          return WriteAgentImportFilesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WriteAgentImportFilesResponse':
          return WriteAgentImportFilesResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
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