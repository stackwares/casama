import 'package:kasama_api/src/model/accepted.dart';
import 'package:kasama_api/src/model/approval.dart';
import 'package:kasama_api/src/model/approval_decision_request.dart';
import 'package:kasama_api/src/model/approval_list.dart';
import 'package:kasama_api/src/model/approval_requested_event.dart';
import 'package:kasama_api/src/model/approval_requested_event_payload.dart';
import 'package:kasama_api/src/model/approval_resolved_event.dart';
import 'package:kasama_api/src/model/approval_resolved_event_payload.dart';
import 'package:kasama_api/src/model/attach_integration_request.dart';
import 'package:kasama_api/src/model/bot.dart';
import 'package:kasama_api/src/model/bot_budget.dart';
import 'package:kasama_api/src/model/bot_list.dart';
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
import 'package:kasama_api/src/model/conversation.dart';
import 'package:kasama_api/src/model/conversation_list.dart';
import 'package:kasama_api/src/model/create_bot_request.dart';
import 'package:kasama_api/src/model/create_checkpoint_request.dart';
import 'package:kasama_api/src/model/create_computer_request.dart';
import 'package:kasama_api/src/model/create_conversation_request.dart';
import 'package:kasama_api/src/model/create_credential_request.dart';
import 'package:kasama_api/src/model/create_integration_request.dart';
import 'package:kasama_api/src/model/create_invite_request.dart';
import 'package:kasama_api/src/model/create_organization_request.dart';
import 'package:kasama_api/src/model/create_routine_request.dart';
import 'package:kasama_api/src/model/create_secret_request.dart';
import 'package:kasama_api/src/model/created_routine.dart';
import 'package:kasama_api/src/model/credential.dart';
import 'package:kasama_api/src/model/credential_list.dart';
import 'package:kasama_api/src/model/credential_test_result.dart';
import 'package:kasama_api/src/model/delete_result.dart';
import 'package:kasama_api/src/model/deleted_computer.dart';
import 'package:kasama_api/src/model/deleted_id.dart';
import 'package:kasama_api/src/model/health.dart';
import 'package:kasama_api/src/model/ice_server.dart';
import 'package:kasama_api/src/model/integration.dart';
import 'package:kasama_api/src/model/integration_list.dart';
import 'package:kasama_api/src/model/integration_test_result.dart';
import 'package:kasama_api/src/model/integration_tools_inner.dart';
import 'package:kasama_api/src/model/invite.dart';
import 'package:kasama_api/src/model/lease.dart';
import 'package:kasama_api/src/model/lease_changed_event.dart';
import 'package:kasama_api/src/model/lease_changed_event_payload.dart';
import 'package:kasama_api/src/model/me.dart';
import 'package:kasama_api/src/model/membership.dart';
import 'package:kasama_api/src/model/memory.dart';
import 'package:kasama_api/src/model/memory_list.dart';
import 'package:kasama_api/src/model/memory_written_event.dart';
import 'package:kasama_api/src/model/memory_written_event_payload.dart';
import 'package:kasama_api/src/model/message_completed_event.dart';
import 'package:kasama_api/src/model/message_completed_event_payload.dart';
import 'package:kasama_api/src/model/message_delta_event.dart';
import 'package:kasama_api/src/model/message_delta_event_payload.dart';
import 'package:kasama_api/src/model/model_choice.dart';
import 'package:kasama_api/src/model/model_policy.dart';
import 'package:kasama_api/src/model/ok.dart';
import 'package:kasama_api/src/model/organization.dart';
import 'package:kasama_api/src/model/organization_list.dart';
import 'package:kasama_api/src/model/organization_with_role.dart';
import 'package:kasama_api/src/model/problem.dart';
import 'package:kasama_api/src/model/problem_errors_inner.dart';
import 'package:kasama_api/src/model/public_config.dart';
import 'package:kasama_api/src/model/release_lease_request.dart';
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
import 'package:kasama_api/src/model/secret.dart';
import 'package:kasama_api/src/model/secret_list.dart';
import 'package:kasama_api/src/model/send_message_request.dart';
import 'package:kasama_api/src/model/send_message_response.dart';
import 'package:kasama_api/src/model/skill_loaded_event.dart';
import 'package:kasama_api/src/model/skill_loaded_event_payload.dart';
import 'package:kasama_api/src/model/stream_session.dart';
import 'package:kasama_api/src/model/stream_session_request.dart';
import 'package:kasama_api/src/model/subrun_completed_event.dart';
import 'package:kasama_api/src/model/subrun_completed_event_payload.dart';
import 'package:kasama_api/src/model/subrun_started_event.dart';
import 'package:kasama_api/src/model/subrun_started_event_payload.dart';
import 'package:kasama_api/src/model/take_lease_request.dart';
import 'package:kasama_api/src/model/takeover_request.dart';
import 'package:kasama_api/src/model/takeover_request_list.dart';
import 'package:kasama_api/src/model/takeover_requested_event.dart';
import 'package:kasama_api/src/model/takeover_requested_event_payload.dart';
import 'package:kasama_api/src/model/takeover_resolved_event.dart';
import 'package:kasama_api/src/model/takeover_resolved_event_payload.dart';
import 'package:kasama_api/src/model/task.dart';
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
import 'package:kasama_api/src/model/update_computer_request.dart';
import 'package:kasama_api/src/model/update_routine_request.dart';
import 'package:kasama_api/src/model/upload_result.dart';
import 'package:kasama_api/src/model/usage_event.dart';
import 'package:kasama_api/src/model/usage_event_payload.dart';
import 'package:kasama_api/src/model/usage_report.dart';
import 'package:kasama_api/src/model/usage_report_by_bot_inner.dart';

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
        case 'Accepted':
          return Accepted.fromJson(value as Map<String, dynamic>) as ReturnType;
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
          
          
        case 'Bot':
          return Bot.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotBudget':
          return BotBudget.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'BotList':
          return BotList.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'CreateConversationRequest':
          return CreateConversationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateCredentialRequest':
          return CreateCredentialRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateIntegrationRequest':
          return CreateIntegrationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateInviteRequest':
          return CreateInviteRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateOrganizationRequest':
          return CreateOrganizationRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateRoutineRequest':
          return CreateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreateSecretRequest':
          return CreateSecretRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CreatedRoutine':
          return CreatedRoutine.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Credential':
          return Credential.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CredentialList':
          return CredentialList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'CredentialTestResult':
          return CredentialTestResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeleteResult':
          return DeleteResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedComputer':
          return DeletedComputer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'DeletedId':
          return DeletedId.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Health':
          return Health.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IceServer':
          return IceServer.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Integration':
          return Integration.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationKind':
          
          
        case 'IntegrationList':
          return IntegrationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationTestResult':
          return IntegrationTestResult.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'IntegrationToolsInner':
          return IntegrationToolsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Invite':
          return Invite.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'InviteRole':
          
          
        case 'Lease':
          return Lease.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LeaseChangedEvent':
          return LeaseChangedEvent.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'LeaseChangedEventPayload':
          return LeaseChangedEventPayload.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'ModelPolicy':
          return ModelPolicy.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Ok':
          return Ok.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OrgRole':
          
          
        case 'Organization':
          return Organization.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OrganizationList':
          return OrganizationList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'OrganizationWithRole':
          return OrganizationWithRole.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'Problem':
          return Problem.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProblemErrorsInner':
          return ProblemErrorsInner.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ProviderId':
          
          
        case 'PublicConfig':
          return PublicConfig.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'ReasoningEffort':
          
          
        case 'ReleaseLeaseRequest':
          return ReleaseLeaseRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
          
          
        case 'Secret':
          return Secret.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SecretList':
          return SecretList.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendMessageRequest':
          return SendMessageRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'SendMessageResponse':
          return SendMessageResponse.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'TaskList':
          return TaskList.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'UpdateComputerRequest':
          return UpdateComputerRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
        case 'UpdateRoutineRequest':
          return UpdateRoutineRequest.fromJson(value as Map<String, dynamic>) as ReturnType;
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
        case 'Visibility':
          
          
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