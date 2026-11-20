import 'package:casama_api/src/model/about_you.dart';
import 'package:casama_api/src/model/abuse_event.dart';
import 'package:casama_api/src/model/abuse_event_list.dart';
import 'package:casama_api/src/model/accept_bot_link_request.dart';
import 'package:casama_api/src/model/accept_skill_proposal_request.dart';
import 'package:casama_api/src/model/accepted.dart';
import 'package:casama_api/src/model/accepted_suggestion.dart';
import 'package:casama_api/src/model/account_deletion.dart';
import 'package:casama_api/src/model/action_admin_limit_reset_campaign200_response.dart';
import 'package:casama_api/src/model/action_admin_limit_reset_campaign_request.dart';
import 'package:casama_api/src/model/action_admin_workspace_limit_reset_request.dart';
import 'package:casama_api/src/model/action_rule.dart';
import 'package:casama_api/src/model/action_rule_list.dart';
import 'package:casama_api/src/model/action_rule_target.dart';
import 'package:casama_api/src/model/add_teach_step_request.dart';
import 'package:casama_api/src/model/add_user_facts_request.dart';
import 'package:casama_api/src/model/add_user_facts_request_items_inner.dart';
import 'package:casama_api/src/model/add_waitlist_entries_request.dart';
import 'package:casama_api/src/model/admin_bot_setting.dart';
import 'package:casama_api/src/model/admin_browser_guard.dart';
import 'package:casama_api/src/model/admin_call_limits.dart';
import 'package:casama_api/src/model/admin_check.dart';
import 'package:casama_api/src/model/admin_credit_pack.dart';
import 'package:casama_api/src/model/admin_domain.dart';
import 'package:casama_api/src/model/admin_domain_order.dart';
import 'package:casama_api/src/model/admin_domains.dart';
import 'package:casama_api/src/model/admin_domains_counts.dart';
import 'package:casama_api/src/model/admin_link_server.dart';
import 'package:casama_api/src/model/admin_link_server_list.dart';
import 'package:casama_api/src/model/admin_mail_address.dart';
import 'package:casama_api/src/model/admin_mail_addresses200_response.dart';
import 'package:casama_api/src/model/admin_mail_reserved_names.dart';
import 'package:casama_api/src/model/admin_margin.dart';
import 'package:casama_api/src/model/admin_margin_by_day_inner.dart';
import 'package:casama_api/src/model/admin_margin_by_kind_inner.dart';
import 'package:casama_api/src/model/admin_margin_top_orgs_inner.dart';
import 'package:casama_api/src/model/admin_model_catalog.dart';
import 'package:casama_api/src/model/admin_org.dart';
import 'package:casama_api/src/model/admin_org_list.dart';
import 'package:casama_api/src/model/admin_overview.dart';
import 'package:casama_api/src/model/admin_passkey_check_request.dart';
import 'package:casama_api/src/model/admin_pin_check_request.dart';
import 'package:casama_api/src/model/admin_pin_state.dart';
import 'package:casama_api/src/model/admin_plan.dart';
import 'package:casama_api/src/model/admin_price_tables.dart';
import 'package:casama_api/src/model/admin_pricing.dart';
import 'package:casama_api/src/model/admin_service.dart';
import 'package:casama_api/src/model/admin_service_list.dart';
import 'package:casama_api/src/model/admin_user.dart';
import 'package:casama_api/src/model/admin_user_list.dart';
import 'package:casama_api/src/model/admin_vendor.dart';
import 'package:casama_api/src/model/admin_vendor_list.dart';
import 'package:casama_api/src/model/admit_waitlist_request.dart';
import 'package:casama_api/src/model/agent_import_plan.dart';
import 'package:casama_api/src/model/agent_import_plan_leftovers_inner.dart';
import 'package:casama_api/src/model/agent_import_plan_skipped_inner.dart';
import 'package:casama_api/src/model/agent_import_plan_sources.dart';
import 'package:casama_api/src/model/announcement.dart';
import 'package:casama_api/src/model/answer_mcp_question_body.dart';
import 'package:casama_api/src/model/app_catalog.dart';
import 'package:casama_api/src/model/app_mention_ref.dart';
import 'package:casama_api/src/model/apple_sign_in_token_request.dart';
import 'package:casama_api/src/model/apple_sign_in_token_result.dart';
import 'package:casama_api/src/model/apply_computer_update_request.dart';
import 'package:casama_api/src/model/apply_skill_update_request.dart';
import 'package:casama_api/src/model/approval.dart';
import 'package:casama_api/src/model/approval_decision_request.dart';
import 'package:casama_api/src/model/approval_list.dart';
import 'package:casama_api/src/model/approval_requested_event.dart';
import 'package:casama_api/src/model/approval_requested_event_payload.dart';
import 'package:casama_api/src/model/approval_resolved_event.dart';
import 'package:casama_api/src/model/approval_resolved_event_payload.dart';
import 'package:casama_api/src/model/approve_link_sign_in_request.dart';
import 'package:casama_api/src/model/approved_link_sign_in.dart';
import 'package:casama_api/src/model/ask_device_permission_request.dart';
import 'package:casama_api/src/model/ask_device_permission_result.dart';
import 'package:casama_api/src/model/attach_integration_request.dart';
import 'package:casama_api/src/model/billing_settings.dart';
import 'package:casama_api/src/model/billing_summary.dart';
import 'package:casama_api/src/model/billing_summary_computer_hours.dart';
import 'package:casama_api/src/model/billing_summary_daily.dart';
import 'package:casama_api/src/model/billing_usage.dart';
import 'package:casama_api/src/model/billing_usage_item.dart';
import 'package:casama_api/src/model/block_mail_sender_request.dart';
import 'package:casama_api/src/model/block_request.dart';
import 'package:casama_api/src/model/blocked_person.dart';
import 'package:casama_api/src/model/blocked_person_list.dart';
import 'package:casama_api/src/model/bot.dart';
import 'package:casama_api/src/model/bot_a2a.dart';
import 'package:casama_api/src/model/bot_access.dart';
import 'package:casama_api/src/model/bot_access_entry.dart';
import 'package:casama_api/src/model/bot_budget.dart';
import 'package:casama_api/src/model/bot_checkins.dart';
import 'package:casama_api/src/model/bot_last_message.dart';
import 'package:casama_api/src/model/bot_link.dart';
import 'package:casama_api/src/model/bot_link_list.dart';
import 'package:casama_api/src/model/bot_list.dart';
import 'package:casama_api/src/model/bot_model_privacy.dart';
import 'package:casama_api/src/model/bot_page.dart';
import 'package:casama_api/src/model/bot_page_detail.dart';
import 'package:casama_api/src/model/bot_secret_request.dart';
import 'package:casama_api/src/model/bot_secret_request_list.dart';
import 'package:casama_api/src/model/bot_share_link.dart';
import 'package:casama_api/src/model/bot_template_file.dart';
import 'package:casama_api/src/model/bot_template_file_connections_inner.dart';
import 'package:casama_api/src/model/bot_template_file_memories_inner.dart';
import 'package:casama_api/src/model/bot_template_file_routines_inner.dart';
import 'package:casama_api/src/model/bot_template_file_skills_inner.dart';
import 'package:casama_api/src/model/bot_template_file_skills_inner_files_inner.dart';
import 'package:casama_api/src/model/browser_guard_sites.dart';
import 'package:casama_api/src/model/browser_tab_summary.dart';
import 'package:casama_api/src/model/browser_trigger_list.dart';
import 'package:casama_api/src/model/browser_trigger_list_items_inner.dart';
import 'package:casama_api/src/model/calendar_trigger_config.dart';
import 'package:casama_api/src/model/call_step_request.dart';
import 'package:casama_api/src/model/call_step_result.dart';
import 'package:casama_api/src/model/catalog_app.dart';
import 'package:casama_api/src/model/catalog_app_api_key.dart';
import 'package:casama_api/src/model/catalog_skill.dart';
import 'package:casama_api/src/model/channel.dart';
import 'package:casama_api/src/model/channel_event.dart';
import 'package:casama_api/src/model/channel_event_list.dart';
import 'package:casama_api/src/model/channel_list.dart';
import 'package:casama_api/src/model/chat_gpt_sign_in_complete_request.dart';
import 'package:casama_api/src/model/chat_gpt_sign_in_start.dart';
import 'package:casama_api/src/model/chat_gpt_sign_in_start_request.dart';
import 'package:casama_api/src/model/chat_starter.dart';
import 'package:casama_api/src/model/chat_starters.dart';
import 'package:casama_api/src/model/checkout_request.dart';
import 'package:casama_api/src/model/checkout_result.dart';
import 'package:casama_api/src/model/checkpoint.dart';
import 'package:casama_api/src/model/checkpoint_created_event.dart';
import 'package:casama_api/src/model/checkpoint_created_event_payload.dart';
import 'package:casama_api/src/model/checkpoint_list.dart';
import 'package:casama_api/src/model/claim_mail_address_request.dart';
import 'package:casama_api/src/model/clean_storage_result.dart';
import 'package:casama_api/src/model/cloud_models.dart';
import 'package:casama_api/src/model/coding_agent_info.dart';
import 'package:casama_api/src/model/coding_agent_list.dart';
import 'package:casama_api/src/model/coding_agent_test_result.dart';
import 'package:casama_api/src/model/computer.dart';
import 'package:casama_api/src/model/computer_bot_list.dart';
import 'package:casama_api/src/model/computer_bot_use.dart';
import 'package:casama_api/src/model/computer_device.dart';
import 'package:casama_api/src/model/computer_file_entry.dart';
import 'package:casama_api/src/model/computer_file_list.dart';
import 'package:casama_api/src/model/computer_history.dart';
import 'package:casama_api/src/model/computer_history_entry.dart';
import 'package:casama_api/src/model/computer_list.dart';
import 'package:casama_api/src/model/computer_operation.dart';
import 'package:casama_api/src/model/computer_process.dart';
import 'package:casama_api/src/model/computer_process_list.dart';
import 'package:casama_api/src/model/computer_size.dart';
import 'package:casama_api/src/model/computer_state_event.dart';
import 'package:casama_api/src/model/computer_state_event_payload.dart';
import 'package:casama_api/src/model/computer_storage.dart';
import 'package:casama_api/src/model/computer_usage.dart';
import 'package:casama_api/src/model/computer_usage_day.dart';
import 'package:casama_api/src/model/computer_vitals.dart';
import 'package:casama_api/src/model/connect_app_request.dart';
import 'package:casama_api/src/model/connect_app_response.dart';
import 'package:casama_api/src/model/connect_domain_request.dart';
import 'package:casama_api/src/model/connect_domain_result.dart';
import 'package:casama_api/src/model/connect_domain_result_claim.dart';
import 'package:casama_api/src/model/connect_flow_status.dart';
import 'package:casama_api/src/model/connection_settings.dart';
import 'package:casama_api/src/model/content_author.dart';
import 'package:casama_api/src/model/content_report.dart';
import 'package:casama_api/src/model/content_report_list.dart';
import 'package:casama_api/src/model/conversation.dart';
import 'package:casama_api/src/model/conversation_list.dart';
import 'package:casama_api/src/model/conversation_thread.dart';
import 'package:casama_api/src/model/create_action_rule_request.dart';
import 'package:casama_api/src/model/create_bot_link_request.dart';
import 'package:casama_api/src/model/create_bot_request.dart';
import 'package:casama_api/src/model/create_bot_share_request.dart';
import 'package:casama_api/src/model/create_channel_request.dart';
import 'package:casama_api/src/model/create_checkpoint_request.dart';
import 'package:casama_api/src/model/create_computer_request.dart';
import 'package:casama_api/src/model/create_conversation_request.dart';
import 'package:casama_api/src/model/create_credential_request.dart';
import 'package:casama_api/src/model/create_device_request_request.dart';
import 'package:casama_api/src/model/create_gallery_request.dart';
import 'package:casama_api/src/model/create_gallery_submission.dart';
import 'package:casama_api/src/model/create_highlight_request.dart';
import 'package:casama_api/src/model/create_integration_request.dart';
import 'package:casama_api/src/model/create_invite_campaign_request.dart';
import 'package:casama_api/src/model/create_invite_code_request.dart';
import 'package:casama_api/src/model/create_invite_link_request.dart';
import 'package:casama_api/src/model/create_invite_request.dart';
import 'package:casama_api/src/model/create_invites_request.dart';
import 'package:casama_api/src/model/create_knowledge_source_request.dart';
import 'package:casama_api/src/model/create_knowledge_source_request_documents_inner.dart';
import 'package:casama_api/src/model/create_knowledge_source_request_files_inner.dart';
import 'package:casama_api/src/model/create_link_key_request.dart';
import 'package:casama_api/src/model/create_local_device_request.dart';
import 'package:casama_api/src/model/create_mcp_key_request.dart';
import 'package:casama_api/src/model/create_organization_request.dart';
import 'package:casama_api/src/model/create_page_command_request.dart';
import 'package:casama_api/src/model/create_page_watcher_request.dart';
import 'package:casama_api/src/model/create_password_manager_request.dart';
import 'package:casama_api/src/model/create_project_request.dart';
import 'package:casama_api/src/model/create_report_request.dart';
import 'package:casama_api/src/model/create_routine_request.dart';
import 'package:casama_api/src/model/create_secret_request.dart';
import 'package:casama_api/src/model/create_task_comment_request.dart';
import 'package:casama_api/src/model/create_task_request.dart';
import 'package:casama_api/src/model/created_bot_link.dart';
import 'package:casama_api/src/model/created_invite_link.dart';
import 'package:casama_api/src/model/created_link_key.dart';
import 'package:casama_api/src/model/created_local_device.dart';
import 'package:casama_api/src/model/created_mcp_key.dart';
import 'package:casama_api/src/model/created_routine.dart';
import 'package:casama_api/src/model/creation.dart';
import 'package:casama_api/src/model/creation_detail.dart';
import 'package:casama_api/src/model/creation_list.dart';
import 'package:casama_api/src/model/credential.dart';
import 'package:casama_api/src/model/credential_list.dart';
import 'package:casama_api/src/model/credential_test_result.dart';
import 'package:casama_api/src/model/credit_entry.dart';
import 'package:casama_api/src/model/credit_pack.dart';
import 'package:casama_api/src/model/decide_join_request.dart';
import 'package:casama_api/src/model/delete_account_request.dart';
import 'package:casama_api/src/model/delete_mail_messages_request.dart';
import 'package:casama_api/src/model/delete_mail_messages_result.dart';
import 'package:casama_api/src/model/delete_result.dart';
import 'package:casama_api/src/model/deleted_call.dart';
import 'package:casama_api/src/model/deleted_channel.dart';
import 'package:casama_api/src/model/deleted_computer.dart';
import 'package:casama_api/src/model/deleted_conversation.dart';
import 'package:casama_api/src/model/deleted_conversations.dart';
import 'package:casama_api/src/model/deleted_device.dart';
import 'package:casama_api/src/model/deleted_highlight.dart';
import 'package:casama_api/src/model/deleted_id.dart';
import 'package:casama_api/src/model/deleted_knowledge_source.dart';
import 'package:casama_api/src/model/deleted_memory.dart';
import 'package:casama_api/src/model/deleted_message.dart';
import 'package:casama_api/src/model/deleted_page.dart';
import 'package:casama_api/src/model/deleted_page_command.dart';
import 'package:casama_api/src/model/deleted_password_manager.dart';
import 'package:casama_api/src/model/deleted_plugin.dart';
import 'package:casama_api/src/model/deleted_replay.dart';
import 'package:casama_api/src/model/deleted_routine.dart';
import 'package:casama_api/src/model/deleted_rule.dart';
import 'package:casama_api/src/model/deleted_teach.dart';
import 'package:casama_api/src/model/deleted_user_fact.dart';
import 'package:casama_api/src/model/deleted_watch_key.dart';
import 'package:casama_api/src/model/deleted_watch_keys.dart';
import 'package:casama_api/src/model/deleted_watcher.dart';
import 'package:casama_api/src/model/deleted_widget_key.dart';
import 'package:casama_api/src/model/device_access_requested_event.dart';
import 'package:casama_api/src/model/device_access_requested_event_payload.dart';
import 'package:casama_api/src/model/device_browser_access_requested_event.dart';
import 'package:casama_api/src/model/device_browser_access_requested_event_payload.dart';
import 'package:casama_api/src/model/device_data_used_event.dart';
import 'package:casama_api/src/model/device_data_used_event_payload.dart';
import 'package:casama_api/src/model/device_event_input.dart';
import 'package:casama_api/src/model/device_grant.dart';
import 'package:casama_api/src/model/device_kind_settings.dart';
import 'package:casama_api/src/model/device_permission_needed_event.dart';
import 'package:casama_api/src/model/device_permission_needed_event_payload.dart';
import 'package:casama_api/src/model/device_permissions.dart';
import 'package:casama_api/src/model/device_place.dart';
import 'package:casama_api/src/model/device_reading.dart';
import 'package:casama_api/src/model/device_reading_input.dart';
import 'package:casama_api/src/model/device_request.dart';
import 'package:casama_api/src/model/device_request_answer.dart';
import 'package:casama_api/src/model/device_request_result.dart';
import 'package:casama_api/src/model/device_source.dart';
import 'package:casama_api/src/model/device_trigger_config.dart';
import 'package:casama_api/src/model/directory_plugin.dart';
import 'package:casama_api/src/model/dismiss_suggestion_request.dart';
import 'package:casama_api/src/model/dns_record_input.dart';
import 'package:casama_api/src/model/dns_record_item.dart';
import 'package:casama_api/src/model/dns_record_list.dart';
import 'package:casama_api/src/model/dns_record_patch.dart';
import 'package:casama_api/src/model/domain.dart';
import 'package:casama_api/src/model/domain_checkout_request.dart';
import 'package:casama_api/src/model/domain_checkout_result.dart';
import 'package:casama_api/src/model/domain_contact.dart';
import 'package:casama_api/src/model/domain_contact_state.dart';
import 'package:casama_api/src/model/domain_event.dart';
import 'package:casama_api/src/model/domain_list.dart';
import 'package:casama_api/src/model/domain_order.dart';
import 'package:casama_api/src/model/domain_record.dart';
import 'package:casama_api/src/model/domain_search_list.dart';
import 'package:casama_api/src/model/domain_search_result.dart';
import 'package:casama_api/src/model/edit_message_request.dart';
import 'package:casama_api/src/model/email_copy_settings.dart';
import 'package:casama_api/src/model/email_preferences.dart';
import 'package:casama_api/src/model/encryption_status.dart';
import 'package:casama_api/src/model/export_pack_request.dart';
import 'package:casama_api/src/model/export_pack_request_look.dart';
import 'package:casama_api/src/model/file_search_result.dart';
import 'package:casama_api/src/model/for_you.dart';
import 'package:casama_api/src/model/for_you_approval.dart';
import 'package:casama_api/src/model/for_you_brief.dart';
import 'package:casama_api/src/model/fulfill_secret_request_body.dart';
import 'package:casama_api/src/model/gallery_access.dart';
import 'package:casama_api/src/model/gallery_access_diff.dart';
import 'package:casama_api/src/model/gallery_approval.dart';
import 'package:casama_api/src/model/gallery_approval_decision.dart';
import 'package:casama_api/src/model/gallery_approval_list.dart';
import 'package:casama_api/src/model/gallery_author.dart';
import 'package:casama_api/src/model/gallery_author_item.dart';
import 'package:casama_api/src/model/gallery_author_item_list.dart';
import 'package:casama_api/src/model/gallery_author_item_stats.dart';
import 'package:casama_api/src/model/gallery_author_list.dart';
import 'package:casama_api/src/model/gallery_author_profile.dart';
import 'package:casama_api/src/model/gallery_change.dart';
import 'package:casama_api/src/model/gallery_detail.dart';
import 'package:casama_api/src/model/gallery_input.dart';
import 'package:casama_api/src/model/gallery_install_request.dart';
import 'package:casama_api/src/model/gallery_install_result.dart';
import 'package:casama_api/src/model/gallery_install_result_installed.dart';
import 'package:casama_api/src/model/gallery_installed_item.dart';
import 'package:casama_api/src/model/gallery_installed_item_target.dart';
import 'package:casama_api/src/model/gallery_installed_list.dart';
import 'package:casama_api/src/model/gallery_item.dart';
import 'package:casama_api/src/model/gallery_item_tested.dart';
import 'package:casama_api/src/model/gallery_list.dart';
import 'package:casama_api/src/model/gallery_lists.dart';
import 'package:casama_api/src/model/gallery_lists_starters.dart';
import 'package:casama_api/src/model/gallery_missing.dart';
import 'package:casama_api/src/model/gallery_missing_apps_inner.dart';
import 'package:casama_api/src/model/gallery_needs.dart';
import 'package:casama_api/src/model/gallery_pack.dart';
import 'package:casama_api/src/model/gallery_pack_contents.dart';
import 'package:casama_api/src/model/gallery_pack_list.dart';
import 'package:casama_api/src/model/gallery_pack_set_items_inner.dart';
import 'package:casama_api/src/model/gallery_policy.dart';
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:casama_api/src/model/gallery_request.dart';
import 'package:casama_api/src/model/gallery_request_list.dart';
import 'package:casama_api/src/model/gallery_set.dart';
import 'package:casama_api/src/model/gallery_set_install_request.dart';
import 'package:casama_api/src/model/gallery_set_install_result.dart';
import 'package:casama_api/src/model/gallery_set_install_result_items_inner.dart';
import 'package:casama_api/src/model/gallery_set_list.dart';
import 'package:casama_api/src/model/gallery_stats.dart';
import 'package:casama_api/src/model/gallery_stats_list.dart';
import 'package:casama_api/src/model/gallery_submission.dart';
import 'package:casama_api/src/model/gallery_submission_list.dart';
import 'package:casama_api/src/model/gallery_update_request.dart';
import 'package:casama_api/src/model/gallery_update_result.dart';
import 'package:casama_api/src/model/git_hub_skill_preview.dart';
import 'package:casama_api/src/model/git_hub_skill_preview_request.dart';
import 'package:casama_api/src/model/git_sync_status.dart';
import 'package:casama_api/src/model/glance.dart';
import 'package:casama_api/src/model/glance_bot.dart';
import 'package:casama_api/src/model/glance_brief.dart';
import 'package:casama_api/src/model/glance_creation.dart';
import 'package:casama_api/src/model/glance_credits.dart';
import 'package:casama_api/src/model/glance_done.dart';
import 'package:casama_api/src/model/glance_flags.dart';
import 'package:casama_api/src/model/glance_need.dart';
import 'package:casama_api/src/model/glance_needs.dart';
import 'package:casama_api/src/model/glance_routine.dart';
import 'package:casama_api/src/model/glance_routine_choice.dart';
import 'package:casama_api/src/model/glance_run.dart';
import 'package:casama_api/src/model/glance_starter.dart';
import 'package:casama_api/src/model/glance_task.dart';
import 'package:casama_api/src/model/glance_tasks.dart';
import 'package:casama_api/src/model/glance_tasks_counts.dart';
import 'package:casama_api/src/model/group_chat_list.dart';
import 'package:casama_api/src/model/health.dart';
import 'package:casama_api/src/model/highlight.dart';
import 'package:casama_api/src/model/highlight_list.dart';
import 'package:casama_api/src/model/ice_server.dart';
import 'package:casama_api/src/model/import_bot_request.dart';
import 'package:casama_api/src/model/import_bot_response.dart';
import 'package:casama_api/src/model/import_bot_response_connections_to_add_inner.dart';
import 'package:casama_api/src/model/import_profile_photo_request.dart';
import 'package:casama_api/src/model/import_workspace_files_request.dart';
import 'package:casama_api/src/model/imported_memory_item.dart';
import 'package:casama_api/src/model/install_catalog_skill_request.dart';
import 'package:casama_api/src/model/install_git_hub_skill_request.dart';
import 'package:casama_api/src/model/install_pack_request.dart';
import 'package:casama_api/src/model/install_plugin_request.dart';
import 'package:casama_api/src/model/installed_plugin_server.dart';
import 'package:casama_api/src/model/installed_plugin_server_all_of_tools.dart';
import 'package:casama_api/src/model/installed_skill.dart';
import 'package:casama_api/src/model/integration.dart';
import 'package:casama_api/src/model/integration_device.dart';
import 'package:casama_api/src/model/integration_list.dart';
import 'package:casama_api/src/model/integration_test_result.dart';
import 'package:casama_api/src/model/integration_tools_inner.dart';
import 'package:casama_api/src/model/invite.dart';
import 'package:casama_api/src/model/invite_campaign.dart';
import 'package:casama_api/src/model/invite_campaign_list.dart';
import 'package:casama_api/src/model/invite_code_preview.dart';
import 'package:casama_api/src/model/invite_link.dart';
import 'package:casama_api/src/model/invite_link_list.dart';
import 'package:casama_api/src/model/invite_list.dart';
import 'package:casama_api/src/model/invite_preview.dart';
import 'package:casama_api/src/model/invite_preview_workspace.dart';
import 'package:casama_api/src/model/invite_redeemed.dart';
import 'package:casama_api/src/model/join_domains.dart';
import 'package:casama_api/src/model/join_request.dart';
import 'package:casama_api/src/model/join_request_body.dart';
import 'package:casama_api/src/model/join_request_list.dart';
import 'package:casama_api/src/model/join_result.dart';
import 'package:casama_api/src/model/join_waitlist_request.dart';
import 'package:casama_api/src/model/joinable_workspace.dart';
import 'package:casama_api/src/model/joinable_workspace_list.dart';
import 'package:casama_api/src/model/knowledge_source.dart';
import 'package:casama_api/src/model/knowledge_source_list.dart';
import 'package:casama_api/src/model/lease.dart';
import 'package:casama_api/src/model/lease_changed_event.dart';
import 'package:casama_api/src/model/lease_changed_event_payload.dart';
import 'package:casama_api/src/model/leave_waitlist_request.dart';
import 'package:casama_api/src/model/library_starter.dart';
import 'package:casama_api/src/model/limit_reset_audience.dart';
import 'package:casama_api/src/model/limit_reset_campaign.dart';
import 'package:casama_api/src/model/limit_reset_campaign_input.dart';
import 'package:casama_api/src/model/limit_reset_event.dart';
import 'package:casama_api/src/model/limit_reset_preview.dart';
import 'package:casama_api/src/model/limit_reset_settings.dart';
import 'package:casama_api/src/model/link_exchange.dart';
import 'package:casama_api/src/model/link_exchange_list.dart';
import 'package:casama_api/src/model/link_key.dart';
import 'package:casama_api/src/model/link_key_list.dart';
import 'package:casama_api/src/model/link_server.dart';
import 'package:casama_api/src/model/link_server_list.dart';
import 'package:casama_api/src/model/link_sign_in_request.dart';
import 'package:casama_api/src/model/list_device_grants200_response.dart';
import 'package:casama_api/src/model/list_device_permissions200_response.dart';
import 'package:casama_api/src/model/list_device_places200_response.dart';
import 'package:casama_api/src/model/list_device_readings200_response.dart';
import 'package:casama_api/src/model/list_device_requests200_response.dart';
import 'package:casama_api/src/model/list_device_sources200_response.dart';
import 'package:casama_api/src/model/local_capabilities.dart';
import 'package:casama_api/src/model/local_device.dart';
import 'package:casama_api/src/model/local_device_list.dart';
import 'package:casama_api/src/model/local_mcp_integration_list.dart';
import 'package:casama_api/src/model/local_mcp_server_info.dart';
import 'package:casama_api/src/model/local_mcp_sign_in_needed_event.dart';
import 'package:casama_api/src/model/local_mcp_sign_in_needed_event_payload.dart';
import 'package:casama_api/src/model/mail_address.dart';
import 'package:casama_api/src/model/mail_file.dart';
import 'package:casama_api/src/model/mail_message.dart';
import 'package:casama_api/src/model/mail_message_detail.dart';
import 'package:casama_api/src/model/mail_message_list.dart';
import 'package:casama_api/src/model/mail_name_availability.dart';
import 'package:casama_api/src/model/mark_teach_secret_request.dart';
import 'package:casama_api/src/model/mcp_auth_request_info.dart';
import 'package:casama_api/src/model/mcp_consent_request.dart';
import 'package:casama_api/src/model/mcp_consent_result.dart';
import 'package:casama_api/src/model/mcp_key.dart';
import 'package:casama_api/src/model/mcp_key_list.dart';
import 'package:casama_api/src/model/mcp_question.dart';
import 'package:casama_api/src/model/mcp_question_event.dart';
import 'package:casama_api/src/model/mcp_question_event_payload.dart';
import 'package:casama_api/src/model/mcp_question_resolved_event.dart';
import 'package:casama_api/src/model/mcp_question_resolved_event_payload.dart';
import 'package:casama_api/src/model/me.dart';
import 'package:casama_api/src/model/membership.dart';
import 'package:casama_api/src/model/memory.dart';
import 'package:casama_api/src/model/memory_backend.dart';
import 'package:casama_api/src/model/memory_import_prompt.dart';
import 'package:casama_api/src/model/memory_list.dart';
import 'package:casama_api/src/model/memory_written_event.dart';
import 'package:casama_api/src/model/memory_written_event_payload.dart';
import 'package:casama_api/src/model/message_attachment.dart';
import 'package:casama_api/src/model/message_completed_event.dart';
import 'package:casama_api/src/model/message_completed_event_payload.dart';
import 'package:casama_api/src/model/message_delta_event.dart';
import 'package:casama_api/src/model/message_delta_event_payload.dart';
import 'package:casama_api/src/model/message_reaction.dart';
import 'package:casama_api/src/model/message_reaction_list.dart';
import 'package:casama_api/src/model/message_reactions.dart';
import 'package:casama_api/src/model/message_trigger_config.dart';
import 'package:casama_api/src/model/model_choice.dart';
import 'package:casama_api/src/model/model_fallback_event.dart';
import 'package:casama_api/src/model/model_fallback_event_payload.dart';
import 'package:casama_api/src/model/model_option.dart';
import 'package:casama_api/src/model/model_option_list.dart';
import 'package:casama_api/src/model/model_policy.dart';
import 'package:casama_api/src/model/move_mail_address_request.dart';
import 'package:casama_api/src/model/newsletter_status.dart';
import 'package:casama_api/src/model/notice_event.dart';
import 'package:casama_api/src/model/notice_event_payload.dart';
import 'package:casama_api/src/model/ok.dart';
import 'package:casama_api/src/model/org_settings.dart';
import 'package:casama_api/src/model/organization.dart';
import 'package:casama_api/src/model/organization_list.dart';
import 'package:casama_api/src/model/organization_with_role.dart';
import 'package:casama_api/src/model/outbound_call.dart';
import 'package:casama_api/src/model/outbound_call_transcript_inner.dart';
import 'package:casama_api/src/model/own_coding_agent.dart';
import 'package:casama_api/src/model/own_coding_agent_entry.dart';
import 'package:casama_api/src/model/own_coding_agent_list.dart';
import 'package:casama_api/src/model/pack.dart';
import 'package:casama_api/src/model/pack_app_preview.dart';
import 'package:casama_api/src/model/pack_bot_preview.dart';
import 'package:casama_api/src/model/pack_bot_preview_knowledge_inner.dart';
import 'package:casama_api/src/model/pack_bot_preview_rules_inner.dart';
import 'package:casama_api/src/model/pack_export.dart';
import 'package:casama_api/src/model/pack_export_file.dart';
import 'package:casama_api/src/model/pack_file_input.dart';
import 'package:casama_api/src/model/pack_include_preview.dart';
import 'package:casama_api/src/model/pack_install_item.dart';
import 'package:casama_api/src/model/pack_install_result.dart';
import 'package:casama_api/src/model/pack_install_result_missing.dart';
import 'package:casama_api/src/model/pack_item.dart';
import 'package:casama_api/src/model/pack_item_ref.dart';
import 'package:casama_api/src/model/pack_kind_diff.dart';
import 'package:casama_api/src/model/pack_kind_diff_changed_inner.dart';
import 'package:casama_api/src/model/pack_list.dart';
import 'package:casama_api/src/model/pack_look_preview.dart';
import 'package:casama_api/src/model/pack_preview.dart';
import 'package:casama_api/src/model/pack_preview_installed.dart';
import 'package:casama_api/src/model/pack_reach.dart';
import 'package:casama_api/src/model/pack_routine_preview.dart';
import 'package:casama_api/src/model/pack_secret_finding.dart';
import 'package:casama_api/src/model/pack_share.dart';
import 'package:casama_api/src/model/pack_share_view.dart';
import 'package:casama_api/src/model/pack_skill_preview.dart';
import 'package:casama_api/src/model/pack_source.dart';
import 'package:casama_api/src/model/pack_update_preview.dart';
import 'package:casama_api/src/model/pack_update_preview_runs_per_week.dart';
import 'package:casama_api/src/model/page_command.dart';
import 'package:casama_api/src/model/page_command_list.dart';
import 'package:casama_api/src/model/page_history.dart';
import 'package:casama_api/src/model/page_history_conversations_inner.dart';
import 'package:casama_api/src/model/page_list.dart';
import 'package:casama_api/src/model/page_version.dart';
import 'package:casama_api/src/model/page_view_link.dart';
import 'package:casama_api/src/model/page_view_link_request.dart';
import 'package:casama_api/src/model/parse_memory_import_request.dart';
import 'package:casama_api/src/model/parsed_memory_import.dart';
import 'package:casama_api/src/model/password_manager.dart';
import 'package:casama_api/src/model/password_manager_list.dart';
import 'package:casama_api/src/model/password_manager_vault.dart';
import 'package:casama_api/src/model/password_manager_vault_list.dart';
import 'package:casama_api/src/model/paste_bot_import_request.dart';
import 'package:casama_api/src/model/paste_import_prompt.dart';
import 'package:casama_api/src/model/payment_request.dart';
import 'package:casama_api/src/model/payment_request_list.dart';
import 'package:casama_api/src/model/payment_settings.dart';
import 'package:casama_api/src/model/pending_invite.dart';
import 'package:casama_api/src/model/pending_invite_list.dart';
import 'package:casama_api/src/model/phone_call.dart';
import 'package:casama_api/src/model/phone_call_list.dart';
import 'package:casama_api/src/model/plan.dart';
import 'package:casama_api/src/model/plan_catalog.dart';
import 'package:casama_api/src/model/plugin.dart';
import 'package:casama_api/src/model/plugin_directory.dart';
import 'package:casama_api/src/model/plugin_list.dart';
import 'package:casama_api/src/model/plugin_pack_summary.dart';
import 'package:casama_api/src/model/plugin_preview.dart';
import 'package:casama_api/src/model/plugin_preview_skills_inner.dart';
import 'package:casama_api/src/model/plugin_runs_on.dart';
import 'package:casama_api/src/model/plugin_secret_info.dart';
import 'package:casama_api/src/model/plugin_server_info.dart';
import 'package:casama_api/src/model/plugin_setting_info.dart';
import 'package:casama_api/src/model/plugin_settings_inner.dart';
import 'package:casama_api/src/model/plugin_skills_inner.dart';
import 'package:casama_api/src/model/plugin_update_preview.dart';
import 'package:casama_api/src/model/portal_request.dart';
import 'package:casama_api/src/model/preview_pack_request.dart';
import 'package:casama_api/src/model/preview_plugin_request.dart';
import 'package:casama_api/src/model/problem.dart';
import 'package:casama_api/src/model/problem_errors_inner.dart';
import 'package:casama_api/src/model/profile_space.dart';
import 'package:casama_api/src/model/project.dart';
import 'package:casama_api/src/model/project_detail.dart';
import 'package:casama_api/src/model/project_list.dart';
import 'package:casama_api/src/model/project_milestone.dart';
import 'package:casama_api/src/model/project_run.dart';
import 'package:casama_api/src/model/provider_account.dart';
import 'package:casama_api/src/model/provider_account_list.dart';
import 'package:casama_api/src/model/provider_app.dart';
import 'package:casama_api/src/model/provider_app_list.dart';
import 'package:casama_api/src/model/provider_connect_request.dart';
import 'package:casama_api/src/model/provider_connect_response.dart';
import 'package:casama_api/src/model/public_config.dart';
import 'package:casama_api/src/model/public_config_key_providers.dart';
import 'package:casama_api/src/model/public_config_signup_gate.dart';
import 'package:casama_api/src/model/publish_site_request.dart';
import 'package:casama_api/src/model/purchase_request.dart';
import 'package:casama_api/src/model/reaction_summary.dart';
import 'package:casama_api/src/model/redeem_invite_request.dart';
import 'package:casama_api/src/model/redeem_referral_request.dart';
import 'package:casama_api/src/model/redeem_saved_limit_reset200_response.dart';
import 'package:casama_api/src/model/redeem_sign_in_code_request.dart';
import 'package:casama_api/src/model/redeemed_sign_in_code.dart';
import 'package:casama_api/src/model/redirect_url.dart';
import 'package:casama_api/src/model/referral.dart';
import 'package:casama_api/src/model/referral_invited_by.dart';
import 'package:casama_api/src/model/referral_invites.dart';
import 'package:casama_api/src/model/referral_preview.dart';
import 'package:casama_api/src/model/relay_analytics_request.dart';
import 'package:casama_api/src/model/relayed_analytics_event.dart';
import 'package:casama_api/src/model/release_lease_request.dart';
import 'package:casama_api/src/model/remote_access_status.dart';
import 'package:casama_api/src/model/remote_app_config.dart';
import 'package:casama_api/src/model/remote_app_config_crash_reporter.dart';
import 'package:casama_api/src/model/remote_app_config_maintenance.dart';
import 'package:casama_api/src/model/remote_app_config_min_versions.dart';
import 'package:casama_api/src/model/remote_app_config_update_urls.dart';
import 'package:casama_api/src/model/remove_pack200_response.dart';
import 'package:casama_api/src/model/removed_link_server.dart';
import 'package:casama_api/src/model/rename_two_step_factor_request.dart';
import 'package:casama_api/src/model/replaced_data_keys.dart';
import 'package:casama_api/src/model/replay.dart';
import 'package:casama_api/src/model/replay_from_teach_request.dart';
import 'package:casama_api/src/model/replay_list.dart';
import 'package:casama_api/src/model/replay_param_info.dart';
import 'package:casama_api/src/model/replay_steps_inner.dart';
import 'package:casama_api/src/model/report_device_events200_response.dart';
import 'package:casama_api/src/model/report_device_events_request.dart';
import 'package:casama_api/src/model/report_device_permissions_request.dart';
import 'package:casama_api/src/model/report_receipt.dart';
import 'package:casama_api/src/model/reported_creation.dart';
import 'package:casama_api/src/model/reported_creation_list.dart';
import 'package:casama_api/src/model/reset_computer_request.dart';
import 'package:casama_api/src/model/revert_page_request.dart';
import 'package:casama_api/src/model/review_report_request.dart';
import 'package:casama_api/src/model/revoked_key.dart';
import 'package:casama_api/src/model/revoked_link_key.dart';
import 'package:casama_api/src/model/routine.dart';
import 'package:casama_api/src/model/routine_idea.dart';
import 'package:casama_api/src/model/routine_idea_list.dart';
import 'package:casama_api/src/model/routine_list.dart';
import 'package:casama_api/src/model/run.dart';
import 'package:casama_api/src/model/run_cancelled_event.dart';
import 'package:casama_api/src/model/run_cancelled_event_payload.dart';
import 'package:casama_api/src/model/run_completed_event.dart';
import 'package:casama_api/src/model/run_completed_event_payload.dart';
import 'package:casama_api/src/model/run_error.dart';
import 'package:casama_api/src/model/run_event_envelope.dart';
import 'package:casama_api/src/model/run_events_page.dart';
import 'package:casama_api/src/model/run_failed_event.dart';
import 'package:casama_api/src/model/run_failed_event_payload.dart';
import 'package:casama_api/src/model/run_replay_request.dart';
import 'package:casama_api/src/model/run_replay_response.dart';
import 'package:casama_api/src/model/run_started.dart';
import 'package:casama_api/src/model/run_started_event.dart';
import 'package:casama_api/src/model/run_started_event_payload.dart';
import 'package:casama_api/src/model/run_usage.dart';
import 'package:casama_api/src/model/run_usage_items_inner.dart';
import 'package:casama_api/src/model/save_call_limits_request.dart';
import 'package:casama_api/src/model/save_credit_pack_request.dart';
import 'package:casama_api/src/model/save_device_place_request.dart';
import 'package:casama_api/src/model/save_device_source_request.dart';
import 'package:casama_api/src/model/save_device_source_request_kinds.dart';
import 'package:casama_api/src/model/save_imported_memories_request.dart';
import 'package:casama_api/src/model/save_model_catalog_request.dart';
import 'package:casama_api/src/model/save_plan_request.dart';
import 'package:casama_api/src/model/save_price_tables_request.dart';
import 'package:casama_api/src/model/save_teach_request.dart';
import 'package:casama_api/src/model/save_teach_response.dart';
import 'package:casama_api/src/model/saved_count.dart';
import 'package:casama_api/src/model/saved_imported_memories.dart';
import 'package:casama_api/src/model/saved_limit_reset.dart';
import 'package:casama_api/src/model/saved_turns.dart';
import 'package:casama_api/src/model/search_response.dart';
import 'package:casama_api/src/model/search_result.dart';
import 'package:casama_api/src/model/seats_request.dart';
import 'package:casama_api/src/model/secret.dart';
import 'package:casama_api/src/model/secret_list.dart';
import 'package:casama_api/src/model/secret_requested_event.dart';
import 'package:casama_api/src/model/secret_requested_event_payload.dart';
import 'package:casama_api/src/model/secret_resolved_event.dart';
import 'package:casama_api/src/model/secret_resolved_event_payload.dart';
import 'package:casama_api/src/model/secret_store_settings.dart';
import 'package:casama_api/src/model/send_message_request.dart';
import 'package:casama_api/src/model/send_message_response.dart';
import 'package:casama_api/src/model/server_capacity.dart';
import 'package:casama_api/src/model/server_capacity_alerts_inner.dart';
import 'package:casama_api/src/model/server_capacity_days_inner.dart';
import 'package:casama_api/src/model/server_capacity_latest.dart';
import 'package:casama_api/src/model/set_admin_bot_request.dart';
import 'package:casama_api/src/model/set_admin_pin_request.dart';
import 'package:casama_api/src/model/set_analytics_opt_out_request.dart';
import 'package:casama_api/src/model/set_bot_a2a_request.dart';
import 'package:casama_api/src/model/set_bot_access_request.dart';
import 'package:casama_api/src/model/set_bot_access_request_entries_inner.dart';
import 'package:casama_api/src/model/set_connection_settings_request.dart';
import 'package:casama_api/src/model/set_device_grant_request.dart';
import 'package:casama_api/src/model/set_encryption_request.dart';
import 'package:casama_api/src/model/set_git_sync_request.dart';
import 'package:casama_api/src/model/set_join_domain_request.dart';
import 'package:casama_api/src/model/set_local_mcp_servers_request.dart';
import 'package:casama_api/src/model/set_mail_address_status_request.dart';
import 'package:casama_api/src/model/set_memory_backend_request.dart';
import 'package:casama_api/src/model/set_newsletter_request.dart';
import 'package:casama_api/src/model/set_org_limits_request.dart';
import 'package:casama_api/src/model/set_own_coding_agents_request.dart';
import 'package:casama_api/src/model/set_payment_settings_request.dart';
import 'package:casama_api/src/model/set_payment_settings_request_cardholder.dart';
import 'package:casama_api/src/model/set_profile_photo_request.dart';
import 'package:casama_api/src/model/set_profile_space_request.dart';
import 'package:casama_api/src/model/set_reaction_request.dart';
import 'package:casama_api/src/model/set_remote_access_settings_request.dart';
import 'package:casama_api/src/model/set_secret_store_request.dart';
import 'package:casama_api/src/model/set_signup_gate_request.dart';
import 'package:casama_api/src/model/set_support_ticket_status.dart';
import 'package:casama_api/src/model/set_telephony_request.dart';
import 'package:casama_api/src/model/share_conversation_request.dart';
import 'package:casama_api/src/model/share_conversation_response.dart';
import 'package:casama_api/src/model/share_pack_request.dart';
import 'package:casama_api/src/model/sign_in_code.dart';
import 'package:casama_api/src/model/signup_challenge.dart';
import 'package:casama_api/src/model/signup_gate.dart';
import 'package:casama_api/src/model/signup_gate_state.dart';
import 'package:casama_api/src/model/site.dart';
import 'package:casama_api/src/model/site_address_check.dart';
import 'package:casama_api/src/model/site_host.dart';
import 'package:casama_api/src/model/site_list.dart';
import 'package:casama_api/src/model/site_report_request.dart';
import 'package:casama_api/src/model/site_report_result.dart';
import 'package:casama_api/src/model/sites_config.dart';
import 'package:casama_api/src/model/skill_catalog.dart';
import 'package:casama_api/src/model/skill_loaded_event.dart';
import 'package:casama_api/src/model/skill_loaded_event_payload.dart';
import 'package:casama_api/src/model/skill_preview_file.dart';
import 'package:casama_api/src/model/skill_proposal.dart';
import 'package:casama_api/src/model/skill_proposal_list.dart';
import 'package:casama_api/src/model/skill_stats.dart';
import 'package:casama_api/src/model/skill_stats_revisions_inner.dart';
import 'package:casama_api/src/model/skill_update_check.dart';
import 'package:casama_api/src/model/slack_install_link.dart';
import 'package:casama_api/src/model/snooze_device_permissions200_response.dart';
import 'package:casama_api/src/model/snooze_device_permissions_request.dart';
import 'package:casama_api/src/model/start_agent_import_request.dart';
import 'package:casama_api/src/model/start_agent_import_request_files_inner.dart';
import 'package:casama_api/src/model/start_setup_response.dart';
import 'package:casama_api/src/model/start_teach_request.dart';
import 'package:casama_api/src/model/start_welcome_request.dart';
import 'package:casama_api/src/model/stopped_process.dart';
import 'package:casama_api/src/model/storage_category.dart';
import 'package:casama_api/src/model/stream_session.dart';
import 'package:casama_api/src/model/stream_session_request.dart';
import 'package:casama_api/src/model/subrun_completed_event.dart';
import 'package:casama_api/src/model/subrun_completed_event_payload.dart';
import 'package:casama_api/src/model/subrun_started_event.dart';
import 'package:casama_api/src/model/subrun_started_event_payload.dart';
import 'package:casama_api/src/model/subscription.dart';
import 'package:casama_api/src/model/suggestion.dart';
import 'package:casama_api/src/model/suggestion_proposed_action.dart';
import 'package:casama_api/src/model/support_chat_reply.dart';
import 'package:casama_api/src/model/support_chat_reply_handoff.dart';
import 'package:casama_api/src/model/support_chat_request.dart';
import 'package:casama_api/src/model/support_config.dart';
import 'package:casama_api/src/model/support_message.dart';
import 'package:casama_api/src/model/support_place.dart';
import 'package:casama_api/src/model/support_source.dart';
import 'package:casama_api/src/model/support_ticket.dart';
import 'package:casama_api/src/model/support_ticket_list.dart';
import 'package:casama_api/src/model/support_ticket_request.dart';
import 'package:casama_api/src/model/support_ticket_row.dart';
import 'package:casama_api/src/model/support_web_chat_reply.dart';
import 'package:casama_api/src/model/support_web_chat_request.dart';
import 'package:casama_api/src/model/support_web_chat_request_messages_inner.dart';
import 'package:casama_api/src/model/support_web_config.dart';
import 'package:casama_api/src/model/support_web_session.dart';
import 'package:casama_api/src/model/support_web_session_request.dart';
import 'package:casama_api/src/model/support_web_stats.dart';
import 'package:casama_api/src/model/support_web_stats_gaps_inner.dart';
import 'package:casama_api/src/model/suspend_link_server_request.dart';
import 'package:casama_api/src/model/suspend_org_request.dart';
import 'package:casama_api/src/model/switch_branch_request.dart';
import 'package:casama_api/src/model/switch_branch_response.dart';
import 'package:casama_api/src/model/take_down_request.dart';
import 'package:casama_api/src/model/take_lease_request.dart';
import 'package:casama_api/src/model/take_over_call_request.dart';
import 'package:casama_api/src/model/takeover_request.dart';
import 'package:casama_api/src/model/takeover_request_list.dart';
import 'package:casama_api/src/model/takeover_requested_event.dart';
import 'package:casama_api/src/model/takeover_requested_event_payload.dart';
import 'package:casama_api/src/model/takeover_resolved_event.dart';
import 'package:casama_api/src/model/takeover_resolved_event_payload.dart';
import 'package:casama_api/src/model/task.dart';
import 'package:casama_api/src/model/task_comment.dart';
import 'package:casama_api/src/model/task_comment_list.dart';
import 'package:casama_api/src/model/task_list.dart';
import 'package:casama_api/src/model/teach_draft.dart';
import 'package:casama_api/src/model/teach_draft_inputs_inner.dart';
import 'package:casama_api/src/model/teach_session.dart';
import 'package:casama_api/src/model/teach_step.dart';
import 'package:casama_api/src/model/teach_target.dart';
import 'package:casama_api/src/model/telephony_settings.dart';
import 'package:casama_api/src/model/template.dart';
import 'package:casama_api/src/model/template_author.dart';
import 'package:casama_api/src/model/template_list.dart';
import 'package:casama_api/src/model/template_routines_inner.dart';
import 'package:casama_api/src/model/template_season.dart';
import 'package:casama_api/src/model/test_credential_request.dart';
import 'package:casama_api/src/model/test_own_coding_agent_request.dart';
import 'package:casama_api/src/model/text_starter.dart';
import 'package:casama_api/src/model/tool_completed_event.dart';
import 'package:casama_api/src/model/tool_completed_event_payload.dart';
import 'package:casama_api/src/model/tool_failed_event.dart';
import 'package:casama_api/src/model/tool_failed_event_payload.dart';
import 'package:casama_api/src/model/tool_output_event.dart';
import 'package:casama_api/src/model/tool_output_event_payload.dart';
import 'package:casama_api/src/model/tool_started_event.dart';
import 'package:casama_api/src/model/tool_started_event_payload.dart';
import 'package:casama_api/src/model/transcription.dart';
import 'package:casama_api/src/model/transfer_out_request.dart';
import 'package:casama_api/src/model/transfer_out_result.dart';
import 'package:casama_api/src/model/ui_action_part.dart';
import 'package:casama_api/src/model/ui_shown_event.dart';
import 'package:casama_api/src/model/ui_shown_event_payload.dart';
import 'package:casama_api/src/model/update_about_you_request.dart';
import 'package:casama_api/src/model/update_channel_request.dart';
import 'package:casama_api/src/model/update_computer_request.dart';
import 'package:casama_api/src/model/update_conversation_request.dart';
import 'package:casama_api/src/model/update_creation_request.dart';
import 'package:casama_api/src/model/update_credential_request.dart';
import 'package:casama_api/src/model/update_default_invite_request.dart';
import 'package:casama_api/src/model/update_domain_request.dart';
import 'package:casama_api/src/model/update_gallery_request.dart';
import 'package:casama_api/src/model/update_integration_request.dart';
import 'package:casama_api/src/model/update_invite_campaign_request.dart';
import 'package:casama_api/src/model/update_local_device_request.dart';
import 'package:casama_api/src/model/update_mail_address_request.dart';
import 'package:casama_api/src/model/update_memory_request.dart';
import 'package:casama_api/src/model/update_notice.dart';
import 'package:casama_api/src/model/update_org_settings_request.dart';
import 'package:casama_api/src/model/update_organization_request.dart';
import 'package:casama_api/src/model/update_pack_request.dart';
import 'package:casama_api/src/model/update_page_command_request.dart';
import 'package:casama_api/src/model/update_page_request.dart';
import 'package:casama_api/src/model/update_page_response.dart';
import 'package:casama_api/src/model/update_password_manager_request.dart';
import 'package:casama_api/src/model/update_plugin_request.dart';
import 'package:casama_api/src/model/update_plugin_settings_request.dart';
import 'package:casama_api/src/model/update_project_request.dart';
import 'package:casama_api/src/model/update_routine_request.dart';
import 'package:casama_api/src/model/update_task_request.dart';
import 'package:casama_api/src/model/update_user_fact_request.dart';
import 'package:casama_api/src/model/update_watcher_request.dart';
import 'package:casama_api/src/model/upload_device_readings200_response.dart';
import 'package:casama_api/src/model/upload_device_readings_request.dart';
import 'package:casama_api/src/model/upload_result.dart';
import 'package:casama_api/src/model/uploaded_media.dart';
import 'package:casama_api/src/model/usage_event.dart';
import 'package:casama_api/src/model/usage_event_payload.dart';
import 'package:casama_api/src/model/usage_report.dart';
import 'package:casama_api/src/model/usage_report_by_bot_inner.dart';
import 'package:casama_api/src/model/usage_report_by_day_inner.dart';
import 'package:casama_api/src/model/usage_report_by_kind_inner.dart';
import 'package:casama_api/src/model/usage_report_by_model_inner.dart';
import 'package:casama_api/src/model/usage_report_by_person_inner.dart';
import 'package:casama_api/src/model/usage_report_by_source_inner.dart';
import 'package:casama_api/src/model/user_fact.dart';
import 'package:casama_api/src/model/user_fact_list.dart';
import 'package:casama_api/src/model/vendor_reading.dart';
import 'package:casama_api/src/model/vendor_settings.dart';
import 'package:casama_api/src/model/voice_heartbeat.dart';
import 'package:casama_api/src/model/voice_heartbeat_request.dart';
import 'package:casama_api/src/model/voice_heartbeat_request_usage.dart';
import 'package:casama_api/src/model/voice_session.dart';
import 'package:casama_api/src/model/voice_session_limits.dart';
import 'package:casama_api/src/model/voice_session_request.dart';
import 'package:casama_api/src/model/voice_tool_request.dart';
import 'package:casama_api/src/model/voice_tool_result.dart';
import 'package:casama_api/src/model/voice_transcript_request.dart';
import 'package:casama_api/src/model/voice_transcript_request_turns_inner.dart';
import 'package:casama_api/src/model/voice_transcript_request_usage.dart';
import 'package:casama_api/src/model/voice_turns_request.dart';
import 'package:casama_api/src/model/voice_turns_request_turns_inner.dart';
import 'package:casama_api/src/model/waitlist_batch.dart';
import 'package:casama_api/src/model/waitlist_changed.dart';
import 'package:casama_api/src/model/waitlist_entry.dart';
import 'package:casama_api/src/model/waitlist_joined.dart';
import 'package:casama_api/src/model/waitlist_page.dart';
import 'package:casama_api/src/model/waitlist_proof.dart';
import 'package:casama_api/src/model/waitlist_stats.dart';
import 'package:casama_api/src/model/waitlist_stats_by_source_inner.dart';
import 'package:casama_api/src/model/wallpaper_download_request.dart';
import 'package:casama_api/src/model/wallpaper_photo.dart';
import 'package:casama_api/src/model/wallpaper_photo_list.dart';
import 'package:casama_api/src/model/watch_approval.dart';
import 'package:casama_api/src/model/watch_ask.dart';
import 'package:casama_api/src/model/watch_asked.dart';
import 'package:casama_api/src/model/watch_attachment.dart';
import 'package:casama_api/src/model/watch_audio.dart';
import 'package:casama_api/src/model/watch_bot_header.dart';
import 'package:casama_api/src/model/watch_chat.dart';
import 'package:casama_api/src/model/watch_code.dart';
import 'package:casama_api/src/model/watch_code_claim.dart';
import 'package:casama_api/src/model/watch_code_info.dart';
import 'package:casama_api/src/model/watch_code_request.dart';
import 'package:casama_api/src/model/watch_handoff.dart';
import 'package:casama_api/src/model/watch_handoff_sent.dart';
import 'package:casama_api/src/model/watch_key.dart';
import 'package:casama_api/src/model/watch_key_list.dart';
import 'package:casama_api/src/model/watch_key_register.dart';
import 'package:casama_api/src/model/watch_message.dart';
import 'package:casama_api/src/model/watch_prefs.dart';
import 'package:casama_api/src/model/watch_prefs_update.dart';
import 'package:casama_api/src/model/watch_run.dart';
import 'package:casama_api/src/model/watch_self.dart';
import 'package:casama_api/src/model/watch_self_features.dart';
import 'package:casama_api/src/model/watch_self_person.dart';
import 'package:casama_api/src/model/watch_self_saved.dart';
import 'package:casama_api/src/model/watch_self_update.dart';
import 'package:casama_api/src/model/watch_signed_out.dart';
import 'package:casama_api/src/model/watcher.dart';
import 'package:casama_api/src/model/watcher_list.dart';
import 'package:casama_api/src/model/welcome_chat.dart';
import 'package:casama_api/src/model/widget_key.dart';
import 'package:casama_api/src/model/widget_key_create.dart';
import 'package:casama_api/src/model/widget_key_created.dart';
import 'package:casama_api/src/model/widget_key_update.dart';
import 'package:casama_api/src/model/widget_push_token.dart';
import 'package:casama_api/src/model/widget_push_token_saved.dart';
import 'package:casama_api/src/model/workspace_badge.dart';
import 'package:casama_api/src/model/workspace_badge_list.dart';
import 'package:casama_api/src/model/workspace_files_export.dart';
import 'package:casama_api/src/model/workspace_files_export_files_inner.dart';
import 'package:casama_api/src/model/workspace_files_result.dart';
import 'package:casama_api/src/model/workspace_member.dart';
import 'package:casama_api/src/model/workspace_member_list.dart';
import 'package:casama_api/src/model/write_agent_import_files_request.dart';
import 'package:casama_api/src/model/write_agent_import_files_response.dart';

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
        case 'AboutYou':
          return AboutYou.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AbuseEvent':
          return AbuseEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AbuseEventList':
          return AbuseEventList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AcceptBotLinkRequest':
          return AcceptBotLinkRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AcceptSkillProposalRequest':
          return AcceptSkillProposalRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Accepted':
          return Accepted.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AcceptedSuggestion':
          return AcceptedSuggestion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AccountDeletion':
          return AccountDeletion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionAdminLimitResetCampaign200Response':
          return ActionAdminLimitResetCampaign200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionAdminLimitResetCampaignRequest':
          return ActionAdminLimitResetCampaignRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionAdminWorkspaceLimitResetRequest':
          return ActionAdminWorkspaceLimitResetRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionRule':
          return ActionRule.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionRuleList':
          return ActionRuleList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ActionRuleTarget':
          return ActionRuleTarget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddTeachStepRequest':
          return AddTeachStepRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddUserFactsRequest':
          return AddUserFactsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddUserFactsRequestItemsInner':
          return AddUserFactsRequestItemsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AddWaitlistEntriesRequest':
          return AddWaitlistEntriesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminBotSetting':
          return AdminBotSetting.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminBrowserGuard':
          return AdminBrowserGuard.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminCallLimits':
          return AdminCallLimits.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminCheck':
          return AdminCheck.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminCreditPack':
          return AdminCreditPack.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminDomain':
          return AdminDomain.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminDomainOrder':
          return AdminDomainOrder.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminDomains':
          return AdminDomains.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminDomainsCounts':
          return AdminDomainsCounts.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminLinkServer':
          return AdminLinkServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminLinkServerList':
          return AdminLinkServerList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMailAddress':
          return AdminMailAddress.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMailAddresses200Response':
          return AdminMailAddresses200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMailReservedNames':
          return AdminMailReservedNames.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMargin':
          return AdminMargin.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMarginByDayInner':
          return AdminMarginByDayInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMarginByKindInner':
          return AdminMarginByKindInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminMarginTopOrgsInner':
          return AdminMarginTopOrgsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminModelCatalog':
          return AdminModelCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminOrg':
          return AdminOrg.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminOrgList':
          return AdminOrgList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminOverview':
          return AdminOverview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminPasskeyCheckRequest':
          return AdminPasskeyCheckRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminPinCheckRequest':
          return AdminPinCheckRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminPinState':
          return AdminPinState.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminPlan':
          return AdminPlan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminPriceTables':
          return AdminPriceTables.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminPricing':
          return AdminPricing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminService':
          return AdminService.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminServiceList':
          return AdminServiceList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminUser':
          return AdminUser.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminUserList':
          return AdminUserList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminVendor':
          return AdminVendor.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdminVendorList':
          return AdminVendorList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AdmitWaitlistRequest':
          return AdmitWaitlistRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlan':
          return AgentImportPlan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlanLeftoversInner':
          return AgentImportPlanLeftoversInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlanSkippedInner':
          return AgentImportPlanSkippedInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AgentImportPlanSources':
          return AgentImportPlanSources.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Announcement':
          return Announcement.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AnswerMcpQuestionBody':
          return AnswerMcpQuestionBody.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppCatalog':
          return AppCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppMentionRef':
          return AppMentionRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppleSignInTokenRequest':
          return AppleSignInTokenRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AppleSignInTokenResult':
          return AppleSignInTokenResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApplyComputerUpdateRequest':
          return ApplyComputerUpdateRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'ApproveLinkSignInRequest':
          return ApproveLinkSignInRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ApprovedLinkSignIn':
          return ApprovedLinkSignIn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AskDevicePermissionRequest':
          return AskDevicePermissionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AskDevicePermissionResult':
          return AskDevicePermissionResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'AttachIntegrationRequest':
          return AttachIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Autonomy':
          
          
        case 'BillingSettings':
          return BillingSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingSource':
          
          
        case 'BillingSummary':
          return BillingSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingSummaryComputerHours':
          return BillingSummaryComputerHours.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingSummaryDaily':
          return BillingSummaryDaily.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingUsage':
          return BillingUsage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BillingUsageItem':
          return BillingUsageItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BlockMailSenderRequest':
          return BlockMailSenderRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BlockRequest':
          return BlockRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BlockedPerson':
          return BlockedPerson.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BlockedPersonList':
          return BlockedPersonList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Bot':
          return Bot.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotA2a':
          return BotA2a.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotAccess':
          return BotAccess.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotAccessEntry':
          return BotAccessEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotBudget':
          return BotBudget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotCheckins':
          return BotCheckins.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotLastMessage':
          return BotLastMessage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotLink':
          return BotLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotLinkList':
          return BotLinkList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotList':
          return BotList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotModelPrivacy':
          return BotModelPrivacy.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'BrowserGuardSites':
          return BrowserGuardSites.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BrowserTabSummary':
          return BrowserTabSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BrowserTriggerList':
          return BrowserTriggerList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BrowserTriggerListItemsInner':
          return BrowserTriggerListItemsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CalendarTriggerConfig':
          return CalendarTriggerConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CallStepRequest':
          return CallStepRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CallStepResult':
          return CallStepResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogApp':
          return CatalogApp.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogAppApiKey':
          return CatalogAppApiKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CatalogSkill':
          return CatalogSkill.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Channel':
          return Channel.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChannelEvent':
          return ChannelEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChannelEventList':
          return ChannelEventList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChannelKind':
          
          
        case 'ChannelList':
          return ChannelList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatGptSignInCompleteRequest':
          return ChatGptSignInCompleteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatGptSignInStart':
          return ChatGptSignInStart.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatGptSignInStartRequest':
          return ChatGptSignInStartRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatStarter':
          return ChatStarter.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ChatStarters':
          return ChatStarters.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckoutRequest':
          return CheckoutRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckoutResult':
          return CheckoutResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Checkpoint':
          return Checkpoint.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckpointCreatedEvent':
          return CheckpointCreatedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckpointCreatedEventPayload':
          return CheckpointCreatedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CheckpointList':
          return CheckpointList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ClaimMailAddressRequest':
          return ClaimMailAddressRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CleanStorageResult':
          return CleanStorageResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CloudModels':
          return CloudModels.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CodingAgentInfo':
          return CodingAgentInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CodingAgentList':
          return CodingAgentList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CodingAgentTestResult':
          return CodingAgentTestResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Computer':
          return Computer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerBotList':
          return ComputerBotList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerBotUse':
          return ComputerBotUse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerDevice':
          return ComputerDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerFileEntry':
          return ComputerFileEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerFileList':
          return ComputerFileList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerHistory':
          return ComputerHistory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerHistoryEntry':
          return ComputerHistoryEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerList':
          return ComputerList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerOperation':
          return ComputerOperation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerProcess':
          return ComputerProcess.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerProcessList':
          return ComputerProcessList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerSize':
          return ComputerSize.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerState':
          
          
        case 'ComputerStateEvent':
          return ComputerStateEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerStateEventPayload':
          return ComputerStateEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerStorage':
          return ComputerStorage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerUsage':
          return ComputerUsage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerUsageDay':
          return ComputerUsageDay.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ComputerVitals':
          return ComputerVitals.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectAppRequest':
          return ConnectAppRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectAppResponse':
          return ConnectAppResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectDomainRequest':
          return ConnectDomainRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectDomainResult':
          return ConnectDomainResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectDomainResultClaim':
          return ConnectDomainResultClaim.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectFlowStatus':
          return ConnectFlowStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConnectionSettings':
          return ConnectionSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ContentAuthor':
          return ContentAuthor.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ContentReport':
          return ContentReport.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ContentReportList':
          return ContentReportList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Conversation':
          return Conversation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConversationList':
          return ConversationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ConversationThread':
          return ConversationThread.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateActionRuleRequest':
          return CreateActionRuleRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateBotLinkRequest':
          return CreateBotLinkRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateBotRequest':
          return CreateBotRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateBotShareRequest':
          return CreateBotShareRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateChannelRequest':
          return CreateChannelRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateCheckpointRequest':
          return CreateCheckpointRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateComputerRequest':
          return CreateComputerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateConversationRequest':
          return CreateConversationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateCredentialRequest':
          return CreateCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateDeviceRequestRequest':
          return CreateDeviceRequestRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateGalleryRequest':
          return CreateGalleryRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateGallerySubmission':
          return CreateGallerySubmission.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateHighlightRequest':
          return CreateHighlightRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateIntegrationRequest':
          return CreateIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteCampaignRequest':
          return CreateInviteCampaignRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteCodeRequest':
          return CreateInviteCodeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteLinkRequest':
          return CreateInviteLinkRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteRequest':
          return CreateInviteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInvitesRequest':
          return CreateInvitesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateKnowledgeSourceRequest':
          return CreateKnowledgeSourceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateKnowledgeSourceRequestDocumentsInner':
          return CreateKnowledgeSourceRequestDocumentsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateKnowledgeSourceRequestFilesInner':
          return CreateKnowledgeSourceRequestFilesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateLinkKeyRequest':
          return CreateLinkKeyRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateLocalDeviceRequest':
          return CreateLocalDeviceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateMcpKeyRequest':
          return CreateMcpKeyRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateOrganizationRequest':
          return CreateOrganizationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatePageCommandRequest':
          return CreatePageCommandRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatePageWatcherRequest':
          return CreatePageWatcherRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatePasswordManagerRequest':
          return CreatePasswordManagerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateProjectRequest':
          return CreateProjectRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateReportRequest':
          return CreateReportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateRoutineRequest':
          return CreateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateSecretRequest':
          return CreateSecretRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateTaskCommentRequest':
          return CreateTaskCommentRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateTaskRequest':
          return CreateTaskRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedBotLink':
          return CreatedBotLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedInviteLink':
          return CreatedInviteLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedLinkKey':
          return CreatedLinkKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedLocalDevice':
          return CreatedLocalDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedMcpKey':
          return CreatedMcpKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedRoutine':
          return CreatedRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Creation':
          return Creation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreationDetail':
          return CreationDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreationKind':
          
          
        case 'CreationList':
          return CreationList.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'DecideJoinRequest':
          return DecideJoinRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteAccountRequest':
          return DeleteAccountRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteMailMessagesRequest':
          return DeleteMailMessagesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteMailMessagesResult':
          return DeleteMailMessagesResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteResult':
          return DeleteResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedCall':
          return DeletedCall.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedChannel':
          return DeletedChannel.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedComputer':
          return DeletedComputer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedConversation':
          return DeletedConversation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedConversations':
          return DeletedConversations.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedDevice':
          return DeletedDevice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedHighlight':
          return DeletedHighlight.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedId':
          return DeletedId.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedKnowledgeSource':
          return DeletedKnowledgeSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedMemory':
          return DeletedMemory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedMessage':
          return DeletedMessage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedPage':
          return DeletedPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedPageCommand':
          return DeletedPageCommand.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedPasswordManager':
          return DeletedPasswordManager.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedPlugin':
          return DeletedPlugin.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedReplay':
          return DeletedReplay.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedRoutine':
          return DeletedRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedRule':
          return DeletedRule.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedTeach':
          return DeletedTeach.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedUserFact':
          return DeletedUserFact.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedWatchKey':
          return DeletedWatchKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedWatchKeys':
          return DeletedWatchKeys.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedWatcher':
          return DeletedWatcher.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedWidgetKey':
          return DeletedWidgetKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceAccessRequestedEvent':
          return DeviceAccessRequestedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceAccessRequestedEventPayload':
          return DeviceAccessRequestedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceBrowserAccessRequestedEvent':
          return DeviceBrowserAccessRequestedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceBrowserAccessRequestedEventPayload':
          return DeviceBrowserAccessRequestedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceDataUsedEvent':
          return DeviceDataUsedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceDataUsedEventPayload':
          return DeviceDataUsedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceEventInput':
          return DeviceEventInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceGrant':
          return DeviceGrant.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceKind':
          
          
        case 'DeviceKindSettings':
          return DeviceKindSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DevicePermissionNeededEvent':
          return DevicePermissionNeededEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DevicePermissionNeededEventPayload':
          return DevicePermissionNeededEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DevicePermissionType':
          
          
        case 'DevicePermissions':
          return DevicePermissions.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DevicePlace':
          return DevicePlace.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceReading':
          return DeviceReading.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceReadingInput':
          return DeviceReadingInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceRequest':
          return DeviceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceRequestAnswer':
          return DeviceRequestAnswer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceRequestResult':
          return DeviceRequestResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceSource':
          return DeviceSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeviceTriggerConfig':
          return DeviceTriggerConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DirectoryPlugin':
          return DirectoryPlugin.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DismissSuggestionRequest':
          return DismissSuggestionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DnsRecordInput':
          return DnsRecordInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DnsRecordItem':
          return DnsRecordItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DnsRecordList':
          return DnsRecordList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DnsRecordPatch':
          return DnsRecordPatch.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Domain':
          return Domain.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainCheckoutRequest':
          return DomainCheckoutRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainCheckoutResult':
          return DomainCheckoutResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainContact':
          return DomainContact.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainContactState':
          return DomainContactState.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainEvent':
          return DomainEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainList':
          return DomainList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainOrder':
          return DomainOrder.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainRecord':
          return DomainRecord.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainSearchList':
          return DomainSearchList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DomainSearchResult':
          return DomainSearchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EditMessageRequest':
          return EditMessageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EmailCopySettings':
          return EmailCopySettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EmailPreferences':
          return EmailPreferences.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'EncryptionStatus':
          return EncryptionStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExportPackRequest':
          return ExportPackRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ExportPackRequestLook':
          return ExportPackRequestLook.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'GalleryAccess':
          return GalleryAccess.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAccessDiff':
          return GalleryAccessDiff.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAnyKind':
          
          
        case 'GalleryApproval':
          return GalleryApproval.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryApprovalDecision':
          return GalleryApprovalDecision.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryApprovalList':
          return GalleryApprovalList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAuthor':
          return GalleryAuthor.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAuthorItem':
          return GalleryAuthorItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAuthorItemList':
          return GalleryAuthorItemList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAuthorItemStats':
          return GalleryAuthorItemStats.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAuthorList':
          return GalleryAuthorList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryAuthorProfile':
          return GalleryAuthorProfile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryChange':
          return GalleryChange.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryDetail':
          return GalleryDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInput':
          return GalleryInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInstallRequest':
          return GalleryInstallRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInstallResult':
          return GalleryInstallResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInstallResultInstalled':
          return GalleryInstallResultInstalled.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInstalledItem':
          return GalleryInstalledItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInstalledItemTarget':
          return GalleryInstalledItemTarget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryInstalledList':
          return GalleryInstalledList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryItem':
          return GalleryItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryItemTested':
          return GalleryItemTested.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryKind':
          
          
        case 'GalleryList':
          return GalleryList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryLists':
          return GalleryLists.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryListsStarters':
          return GalleryListsStarters.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryMissing':
          return GalleryMissing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryMissingAppsInner':
          return GalleryMissingAppsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryNeeds':
          return GalleryNeeds.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryPack':
          return GalleryPack.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryPackContents':
          return GalleryPackContents.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryPackList':
          return GalleryPackList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryPackSetItemsInner':
          return GalleryPackSetItemsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryPolicy':
          return GalleryPolicy.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryRef':
          return GalleryRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryRequest':
          return GalleryRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryRequestList':
          return GalleryRequestList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySet':
          return GallerySet.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySetInstallRequest':
          return GallerySetInstallRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySetInstallResult':
          return GallerySetInstallResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySetInstallResultItemsInner':
          return GallerySetInstallResultItemsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySetList':
          return GallerySetList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryStats':
          return GalleryStats.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryStatsList':
          return GalleryStatsList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySubmission':
          return GallerySubmission.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GallerySubmissionKind':
          
          
        case 'GallerySubmissionList':
          return GallerySubmissionList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryUpdateRequest':
          return GalleryUpdateRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryUpdateResult':
          return GalleryUpdateResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GalleryWorkspaceKind':
          
          
        case 'GitHubSkillPreview':
          return GitHubSkillPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GitHubSkillPreviewRequest':
          return GitHubSkillPreviewRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GitSyncStatus':
          return GitSyncStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Glance':
          return Glance.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceBot':
          return GlanceBot.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceBrief':
          return GlanceBrief.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceCreation':
          return GlanceCreation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceCredits':
          return GlanceCredits.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceDone':
          return GlanceDone.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceFlags':
          return GlanceFlags.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceNeed':
          return GlanceNeed.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceNeeds':
          return GlanceNeeds.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceRoutine':
          return GlanceRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceRoutineChoice':
          return GlanceRoutineChoice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceRun':
          return GlanceRun.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceStarter':
          return GlanceStarter.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceTask':
          return GlanceTask.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceTasks':
          return GlanceTasks.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GlanceTasksCounts':
          return GlanceTasksCounts.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'GroupChatList':
          return GroupChatList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Health':
          return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Highlight':
          return Highlight.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'HighlightList':
          return HighlightList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IceServer':
          return IceServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportBotRequest':
          return ImportBotRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportBotResponse':
          return ImportBotResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportBotResponseConnectionsToAddInner':
          return ImportBotResponseConnectionsToAddInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportProfilePhotoRequest':
          return ImportProfilePhotoRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportWorkspaceFilesRequest':
          return ImportWorkspaceFilesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ImportedMemoryItem':
          return ImportedMemoryItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstallCatalogSkillRequest':
          return InstallCatalogSkillRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstallGitHubSkillRequest':
          return InstallGitHubSkillRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InstallPackRequest':
          return InstallPackRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'InviteCampaign':
          return InviteCampaign.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteCampaignList':
          return InviteCampaignList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteCodePreview':
          return InviteCodePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteLink':
          return InviteLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteLinkList':
          return InviteLinkList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteList':
          return InviteList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InvitePreview':
          return InvitePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InvitePreviewWorkspace':
          return InvitePreviewWorkspace.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteRedeemed':
          return InviteRedeemed.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteRole':
          
          
        case 'JoinDomains':
          return JoinDomains.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinRequest':
          return JoinRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinRequestBody':
          return JoinRequestBody.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinRequestList':
          return JoinRequestList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinResult':
          return JoinResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinWaitlistRequest':
          return JoinWaitlistRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinableWorkspace':
          return JoinableWorkspace.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'JoinableWorkspaceList':
          return JoinableWorkspaceList.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'LeaveWaitlistRequest':
          return LeaveWaitlistRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LibraryStarter':
          return LibraryStarter.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LimitResetAudience':
          return LimitResetAudience.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LimitResetCampaign':
          return LimitResetCampaign.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LimitResetCampaignInput':
          return LimitResetCampaignInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LimitResetEvent':
          return LimitResetEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LimitResetPreview':
          return LimitResetPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LimitResetSettings':
          return LimitResetSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkExchange':
          return LinkExchange.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkExchangeList':
          return LinkExchangeList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkKey':
          return LinkKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkKeyList':
          return LinkKeyList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkServer':
          return LinkServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkServerList':
          return LinkServerList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LinkSignInRequest':
          return LinkSignInRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListDeviceGrants200Response':
          return ListDeviceGrants200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListDevicePermissions200Response':
          return ListDevicePermissions200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListDevicePlaces200Response':
          return ListDevicePlaces200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListDeviceReadings200Response':
          return ListDeviceReadings200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListDeviceRequests200Response':
          return ListDeviceRequests200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ListDeviceSources200Response':
          return ListDeviceSources200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'LocalMcpSignInNeededEvent':
          return LocalMcpSignInNeededEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LocalMcpSignInNeededEventPayload':
          return LocalMcpSignInNeededEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MailAddress':
          return MailAddress.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MailFile':
          return MailFile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MailMessage':
          return MailMessage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MailMessageDetail':
          return MailMessageDetail.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MailMessageList':
          return MailMessageList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MailNameAvailability':
          return MailNameAvailability.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'McpQuestion':
          return McpQuestion.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpQuestionEvent':
          return McpQuestionEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpQuestionEventPayload':
          return McpQuestionEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpQuestionResolvedEvent':
          return McpQuestionResolvedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'McpQuestionResolvedEventPayload':
          return McpQuestionResolvedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Me':
          return Me.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Membership':
          return Membership.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Memory':
          return Memory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MemoryBackend':
          return MemoryBackend.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'MessageReaction':
          return MessageReaction.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageReactionList':
          return MessageReactionList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageReactions':
          return MessageReactions.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'MessageTriggerConfig':
          return MessageTriggerConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'MoveMailAddressRequest':
          return MoveMailAddressRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NewsletterStatus':
          return NewsletterStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NoticeEvent':
          return NoticeEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'NoticeEventPayload':
          return NoticeEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'OsPermissionState':
          
          
        case 'OutboundCall':
          return OutboundCall.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OutboundCallTranscriptInner':
          return OutboundCallTranscriptInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OwnCodingAgent':
          return OwnCodingAgent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OwnCodingAgentEntry':
          return OwnCodingAgentEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OwnCodingAgentList':
          return OwnCodingAgentList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Pack':
          return Pack.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackAppPreview':
          return PackAppPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackBotPreview':
          return PackBotPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackBotPreviewKnowledgeInner':
          return PackBotPreviewKnowledgeInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackBotPreviewRulesInner':
          return PackBotPreviewRulesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackExport':
          return PackExport.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackExportFile':
          return PackExportFile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackFileInput':
          return PackFileInput.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackIncludePreview':
          return PackIncludePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackInstallItem':
          return PackInstallItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackInstallResult':
          return PackInstallResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackInstallResultMissing':
          return PackInstallResultMissing.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackItem':
          return PackItem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackItemKind':
          
          
        case 'PackItemRef':
          return PackItemRef.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackKindDiff':
          return PackKindDiff.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackKindDiffChangedInner':
          return PackKindDiffChangedInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackList':
          return PackList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackLookPreview':
          return PackLookPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackPreview':
          return PackPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackPreviewInstalled':
          return PackPreviewInstalled.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackReach':
          return PackReach.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackRoutinePreview':
          return PackRoutinePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackSecretFinding':
          return PackSecretFinding.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackShare':
          return PackShare.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackShareView':
          return PackShareView.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackSkillPreview':
          return PackSkillPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackSource':
          return PackSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackUpdatePreview':
          return PackUpdatePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PackUpdatePreviewRunsPerWeek':
          return PackUpdatePreviewRunsPerWeek.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageCommand':
          return PageCommand.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageCommandList':
          return PageCommandList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageHistory':
          return PageHistory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PageHistoryConversationsInner':
          return PageHistoryConversationsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'PasswordManager':
          return PasswordManager.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PasswordManagerList':
          return PasswordManagerList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PasswordManagerVault':
          return PasswordManagerVault.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PasswordManagerVaultList':
          return PasswordManagerVaultList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PasteBotImportRequest':
          return PasteBotImportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PasteImportPrompt':
          return PasteImportPrompt.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PasteImportSource':
          
          
        case 'PaymentRequest':
          return PaymentRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentRequestList':
          return PaymentRequestList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PaymentSettings':
          return PaymentSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PendingInvite':
          return PendingInvite.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PendingInviteList':
          return PendingInviteList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PhoneCall':
          return PhoneCall.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PhoneCallList':
          return PhoneCallList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Plan':
          return Plan.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PlanCatalog':
          return PlanCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Plugin':
          return Plugin.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginDirectory':
          return PluginDirectory.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginList':
          return PluginList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginPackSummary':
          return PluginPackSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginPreview':
          return PluginPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginPreviewSkillsInner':
          return PluginPreviewSkillsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginRunsOn':
          return PluginRunsOn.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginSecretInfo':
          return PluginSecretInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginServerInfo':
          return PluginServerInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginSettingInfo':
          return PluginSettingInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginSettingsInner':
          return PluginSettingsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginSkillsInner':
          return PluginSkillsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PluginUpdatePreview':
          return PluginUpdatePreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PortalRequest':
          return PortalRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PreviewPackRequest':
          return PreviewPackRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PreviewPluginRequest':
          return PreviewPluginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Problem':
          return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProblemErrorsInner':
          return ProblemErrorsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProfileSpace':
          return ProfileSpace.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'PublicConfigKeyProviders':
          return PublicConfigKeyProviders.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublicConfigSignupGate':
          return PublicConfigSignupGate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PublishSiteRequest':
          return PublishSiteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'PurchaseRequest':
          return PurchaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReactionSummary':
          return ReactionSummary.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReasoningEffort':
          
          
        case 'RedeemInviteRequest':
          return RedeemInviteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RedeemReferralRequest':
          return RedeemReferralRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RedeemSavedLimitReset200Response':
          return RedeemSavedLimitReset200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RedeemSignInCodeRequest':
          return RedeemSignInCodeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RedeemedSignInCode':
          return RedeemedSignInCode.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RedirectUrl':
          return RedirectUrl.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Referral':
          return Referral.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReferralInvitedBy':
          return ReferralInvitedBy.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReferralInvites':
          return ReferralInvites.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReferralPreview':
          return ReferralPreview.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RelayAnalyticsRequest':
          return RelayAnalyticsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RelayedAnalyticsEvent':
          return RelayedAnalyticsEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReleaseLeaseRequest':
          return ReleaseLeaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemoteAccessStatus':
          return RemoteAccessStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemoteAppConfig':
          return RemoteAppConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemoteAppConfigCrashReporter':
          return RemoteAppConfigCrashReporter.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemoteAppConfigMaintenance':
          return RemoteAppConfigMaintenance.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemoteAppConfigMinVersions':
          return RemoteAppConfigMinVersions.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemoteAppConfigUpdateUrls':
          return RemoteAppConfigUpdateUrls.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemovePack200Response':
          return RemovePack200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RemovedLinkServer':
          return RemovedLinkServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RenameTwoStepFactorRequest':
          return RenameTwoStepFactorRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReplacedDataKeys':
          return ReplacedDataKeys.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Replay':
          return Replay.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReplayFromTeachRequest':
          return ReplayFromTeachRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReplayList':
          return ReplayList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReplayParamInfo':
          return ReplayParamInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReplayStepsInner':
          return ReplayStepsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportDeviceEvents200Response':
          return ReportDeviceEvents200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportDeviceEventsRequest':
          return ReportDeviceEventsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportDevicePermissionsRequest':
          return ReportDevicePermissionsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportReason':
          
          
        case 'ReportReceipt':
          return ReportReceipt.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportTarget':
          
          
        case 'ReportTargetKind':
          
          
        case 'ReportedCreation':
          return ReportedCreation.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReportedCreationList':
          return ReportedCreationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ResetComputerRequest':
          return ResetComputerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RevertPageRequest':
          return RevertPageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReviewReportRequest':
          return ReviewReportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RevokedKey':
          return RevokedKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RevokedLinkKey':
          return RevokedLinkKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Risk':
          
          
        case 'Routine':
          return Routine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RoutineIdea':
          return RoutineIdea.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RoutineIdeaList':
          return RoutineIdeaList.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'RunReplayRequest':
          return RunReplayRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunReplayResponse':
          return RunReplayResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStarted':
          return RunStarted.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStartedEvent':
          return RunStartedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStartedEventPayload':
          return RunStartedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunStatus':
          
          
        case 'RunUsage':
          return RunUsage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'RunUsageItemsInner':
          return RunUsageItemsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveCallLimitsRequest':
          return SaveCallLimitsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveCreditPackRequest':
          return SaveCreditPackRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveDevicePlaceRequest':
          return SaveDevicePlaceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveDeviceSourceRequest':
          return SaveDeviceSourceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveDeviceSourceRequestKinds':
          return SaveDeviceSourceRequestKinds.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveImportedMemoriesRequest':
          return SaveImportedMemoriesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveModelCatalogRequest':
          return SaveModelCatalogRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavePlanRequest':
          return SavePlanRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavePriceTablesRequest':
          return SavePriceTablesRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveTeachRequest':
          return SaveTeachRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SaveTeachResponse':
          return SaveTeachResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavedCount':
          return SavedCount.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavedImportedMemories':
          return SavedImportedMemories.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavedLimitReset':
          return SavedLimitReset.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SavedTurns':
          return SavedTurns.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchKind':
          
          
        case 'SearchResponse':
          return SearchResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SearchResult':
          return SearchResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SeatsRequest':
          return SeatsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'SecretStoreSettings':
          return SecretStoreSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendMessageRequest':
          return SendMessageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendMessageResponse':
          return SendMessageResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ServerCapacity':
          return ServerCapacity.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ServerCapacityAlertsInner':
          return ServerCapacityAlertsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ServerCapacityDaysInner':
          return ServerCapacityDaysInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ServerCapacityLatest':
          return ServerCapacityLatest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetAdminBotRequest':
          return SetAdminBotRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetAdminPinRequest':
          return SetAdminPinRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetAnalyticsOptOutRequest':
          return SetAnalyticsOptOutRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetBotA2aRequest':
          return SetBotA2aRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetBotAccessRequest':
          return SetBotAccessRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetBotAccessRequestEntriesInner':
          return SetBotAccessRequestEntriesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetConnectionSettingsRequest':
          return SetConnectionSettingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetDeviceGrantRequest':
          return SetDeviceGrantRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetEncryptionRequest':
          return SetEncryptionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetGitSyncRequest':
          return SetGitSyncRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetJoinDomainRequest':
          return SetJoinDomainRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetLocalMcpServersRequest':
          return SetLocalMcpServersRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetMailAddressStatusRequest':
          return SetMailAddressStatusRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetMemoryBackendRequest':
          return SetMemoryBackendRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetNewsletterRequest':
          return SetNewsletterRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetOrgLimitsRequest':
          return SetOrgLimitsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetOwnCodingAgentsRequest':
          return SetOwnCodingAgentsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetPaymentSettingsRequest':
          return SetPaymentSettingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetPaymentSettingsRequestCardholder':
          return SetPaymentSettingsRequestCardholder.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetProfilePhotoRequest':
          return SetProfilePhotoRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetProfileSpaceRequest':
          return SetProfileSpaceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetReactionRequest':
          return SetReactionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetRemoteAccessSettingsRequest':
          return SetRemoteAccessSettingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetSecretStoreRequest':
          return SetSecretStoreRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetSignupGateRequest':
          return SetSignupGateRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetSupportTicketStatus':
          return SetSupportTicketStatus.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SetTelephonyRequest':
          return SetTelephonyRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ShareConversationRequest':
          return ShareConversationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ShareConversationResponse':
          return ShareConversationResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SharePackRequest':
          return SharePackRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignInCode':
          return SignInCode.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupChallenge':
          return SignupChallenge.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupGate':
          return SignupGate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SignupGateState':
          return SignupGateState.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Site':
          return Site.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteAddressCheck':
          return SiteAddressCheck.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteHost':
          return SiteHost.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteKind':
          
          
        case 'SiteList':
          return SiteList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteReportRequest':
          return SiteReportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SiteReportResult':
          return SiteReportResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SitesConfig':
          return SitesConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillCatalog':
          return SkillCatalog.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillLoadedEvent':
          return SkillLoadedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillLoadedEventPayload':
          return SkillLoadedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillPreviewFile':
          return SkillPreviewFile.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillProposal':
          return SkillProposal.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillProposalList':
          return SkillProposalList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillStats':
          return SkillStats.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillStatsRevisionsInner':
          return SkillStatsRevisionsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SkillUpdateCheck':
          return SkillUpdateCheck.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SlackInstallLink':
          return SlackInstallLink.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SnoozeDevicePermissions200Response':
          return SnoozeDevicePermissions200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SnoozeDevicePermissionsRequest':
          return SnoozeDevicePermissionsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartAgentImportRequest':
          return StartAgentImportRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartAgentImportRequestFilesInner':
          return StartAgentImportRequestFilesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartSetupResponse':
          return StartSetupResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartTeachRequest':
          return StartTeachRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StartWelcomeRequest':
          return StartWelcomeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StoppedProcess':
          return StoppedProcess.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'StorageCategory':
          return StorageCategory.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'SupportChatReply':
          return SupportChatReply.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportChatReplyHandoff':
          return SupportChatReplyHandoff.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportChatRequest':
          return SupportChatRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportConfig':
          return SupportConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportMessage':
          return SupportMessage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportPlace':
          return SupportPlace.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportSource':
          return SupportSource.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportTicket':
          return SupportTicket.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportTicketList':
          return SupportTicketList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportTicketRequest':
          return SupportTicketRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportTicketRow':
          return SupportTicketRow.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportTopic':
          
          
        case 'SupportWebChatReply':
          return SupportWebChatReply.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebChatRequest':
          return SupportWebChatRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebChatRequestMessagesInner':
          return SupportWebChatRequestMessagesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebConfig':
          return SupportWebConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebSession':
          return SupportWebSession.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebSessionRequest':
          return SupportWebSessionRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebStats':
          return SupportWebStats.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SupportWebStatsGapsInner':
          return SupportWebStatsGapsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SuspendLinkServerRequest':
          return SuspendLinkServerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SuspendOrgRequest':
          return SuspendOrgRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SwitchBranchRequest':
          return SwitchBranchRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SwitchBranchResponse':
          return SwitchBranchResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeDownRequest':
          return TakeDownRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeLeaseRequest':
          return TakeLeaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TakeOverCallRequest':
          return TakeOverCallRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'TeachTarget':
          return TeachTarget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TelephonySettings':
          return TelephonySettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Template':
          return Template.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TemplateAuthor':
          return TemplateAuthor.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TemplateList':
          return TemplateList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TemplateRoutinesInner':
          return TemplateRoutinesInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TemplateSeason':
          return TemplateSeason.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TestCredentialRequest':
          return TestCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TestOwnCodingAgentRequest':
          return TestOwnCodingAgentRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TextStarter':
          return TextStarter.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'TransferOutRequest':
          return TransferOutRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'TransferOutResult':
          return TransferOutResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UiActionPart':
          return UiActionPart.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UiShownEvent':
          return UiShownEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UiShownEventPayload':
          return UiShownEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateAboutYouRequest':
          return UpdateAboutYouRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateChannelRequest':
          return UpdateChannelRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateComputerRequest':
          return UpdateComputerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateConversationRequest':
          return UpdateConversationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateCreationRequest':
          return UpdateCreationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateCredentialRequest':
          return UpdateCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateDefaultInviteRequest':
          return UpdateDefaultInviteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateDomainRequest':
          return UpdateDomainRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateGalleryRequest':
          return UpdateGalleryRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateIntegrationRequest':
          return UpdateIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateInviteCampaignRequest':
          return UpdateInviteCampaignRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateLocalDeviceRequest':
          return UpdateLocalDeviceRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateMailAddressRequest':
          return UpdateMailAddressRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateMemoryRequest':
          return UpdateMemoryRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateNotice':
          return UpdateNotice.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateOrgSettingsRequest':
          return UpdateOrgSettingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateOrganizationRequest':
          return UpdateOrganizationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePackRequest':
          return UpdatePackRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePageCommandRequest':
          return UpdatePageCommandRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePageRequest':
          return UpdatePageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePageResponse':
          return UpdatePageResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePasswordManagerRequest':
          return UpdatePasswordManagerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePluginRequest':
          return UpdatePluginRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdatePluginSettingsRequest':
          return UpdatePluginSettingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateProjectRequest':
          return UpdateProjectRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateRoutineRequest':
          return UpdateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateTaskRequest':
          return UpdateTaskRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateUserFactRequest':
          return UpdateUserFactRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateWatcherRequest':
          return UpdateWatcherRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UploadDeviceReadings200Response':
          return UploadDeviceReadings200Response.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UploadDeviceReadingsRequest':
          return UploadDeviceReadingsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UploadResult':
          return UploadResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UploadedMedia':
          return UploadedMedia.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'UsageReportByPersonInner':
          return UsageReportByPersonInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageReportBySourceInner':
          return UsageReportBySourceInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UsageSource':
          
          
        case 'UserFact':
          return UserFact.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UserFactList':
          return UserFactList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VendorReading':
          return VendorReading.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VendorSettings':
          return VendorSettings.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Visibility':
          
          
        case 'VoiceHeartbeat':
          return VoiceHeartbeat.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceHeartbeatRequest':
          return VoiceHeartbeatRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceHeartbeatRequestUsage':
          return VoiceHeartbeatRequestUsage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceSession':
          return VoiceSession.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceSessionLimits':
          return VoiceSessionLimits.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'VoiceTranscriptRequestUsage':
          return VoiceTranscriptRequestUsage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceTurnsRequest':
          return VoiceTurnsRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'VoiceTurnsRequestTurnsInner':
          return VoiceTurnsRequestTurnsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistBatch':
          return WaitlistBatch.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistChanged':
          return WaitlistChanged.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistEntry':
          return WaitlistEntry.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistJoined':
          return WaitlistJoined.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistPage':
          return WaitlistPage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistProof':
          return WaitlistProof.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistStats':
          return WaitlistStats.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WaitlistStatsBySourceInner':
          return WaitlistStatsBySourceInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WallpaperDownloadRequest':
          return WallpaperDownloadRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WallpaperPhoto':
          return WallpaperPhoto.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WallpaperPhotoList':
          return WallpaperPhotoList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchAllowLevel':
          
          
        case 'WatchApproval':
          return WatchApproval.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchAsk':
          return WatchAsk.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchAsked':
          return WatchAsked.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchAttachment':
          return WatchAttachment.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchAudio':
          return WatchAudio.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchBotHeader':
          return WatchBotHeader.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchChat':
          return WatchChat.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchCode':
          return WatchCode.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchCodeClaim':
          return WatchCodeClaim.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchCodeInfo':
          return WatchCodeInfo.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchCodeRequest':
          return WatchCodeRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchHandoff':
          return WatchHandoff.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchHandoffSent':
          return WatchHandoffSent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchKey':
          return WatchKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchKeyList':
          return WatchKeyList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchKeyRegister':
          return WatchKeyRegister.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchMessage':
          return WatchMessage.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchPlatform':
          
          
        case 'WatchPrefs':
          return WatchPrefs.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchPrefsUpdate':
          return WatchPrefsUpdate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchRisk':
          
          
        case 'WatchRun':
          return WatchRun.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSelf':
          return WatchSelf.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSelfFeatures':
          return WatchSelfFeatures.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSelfPerson':
          return WatchSelfPerson.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSelfSaved':
          return WatchSelfSaved.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSelfUpdate':
          return WatchSelfUpdate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSignedOut':
          return WatchSignedOut.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatchSurface':
          
          
        case 'Watcher':
          return Watcher.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WatcherList':
          return WatcherList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WelcomeChat':
          return WelcomeChat.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WidgetKey':
          return WidgetKey.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WidgetKeyCreate':
          return WidgetKeyCreate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WidgetKeyCreated':
          return WidgetKeyCreated.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WidgetKeyUpdate':
          return WidgetKeyUpdate.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WidgetPushToken':
          return WidgetPushToken.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WidgetPushTokenSaved':
          return WidgetPushTokenSaved.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'WorkspaceMember':
          return WorkspaceMember.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'WorkspaceMemberList':
          return WorkspaceMemberList.fromJson(value as Map<String, dynamic>) as ReturnType;
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