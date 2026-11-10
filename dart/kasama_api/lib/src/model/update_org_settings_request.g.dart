// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_org_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateOrgSettingsRequestCWProxy {
  UpdateOrgSettingsRequest runEventRetentionDays(int? runEventRetentionDays);

  UpdateOrgSettingsRequest requireMfa(bool? requireMfa);

  UpdateOrgSettingsRequest mcpDecideApprovals(bool? mcpDecideApprovals);

  UpdateOrgSettingsRequest allowBotToBot(bool? allowBotToBot);

  UpdateOrgSettingsRequest llmTracing(bool? llmTracing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateOrgSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateOrgSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateOrgSettingsRequest call({
    int? runEventRetentionDays,
    bool? requireMfa,
    bool? mcpDecideApprovals,
    bool? allowBotToBot,
    bool? llmTracing,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateOrgSettingsRequest.copyWith(...)` or call `instanceOfUpdateOrgSettingsRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateOrgSettingsRequestCWProxyImpl
    implements _$UpdateOrgSettingsRequestCWProxy {
  const _$UpdateOrgSettingsRequestCWProxyImpl(this._value);

  final UpdateOrgSettingsRequest _value;

  @override
  UpdateOrgSettingsRequest runEventRetentionDays(int? runEventRetentionDays) =>
      call(runEventRetentionDays: runEventRetentionDays);

  @override
  UpdateOrgSettingsRequest requireMfa(bool? requireMfa) =>
      call(requireMfa: requireMfa);

  @override
  UpdateOrgSettingsRequest mcpDecideApprovals(bool? mcpDecideApprovals) =>
      call(mcpDecideApprovals: mcpDecideApprovals);

  @override
  UpdateOrgSettingsRequest allowBotToBot(bool? allowBotToBot) =>
      call(allowBotToBot: allowBotToBot);

  @override
  UpdateOrgSettingsRequest llmTracing(bool? llmTracing) =>
      call(llmTracing: llmTracing);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateOrgSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateOrgSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateOrgSettingsRequest call({
    Object? runEventRetentionDays = const $CopyWithPlaceholder(),
    Object? requireMfa = const $CopyWithPlaceholder(),
    Object? mcpDecideApprovals = const $CopyWithPlaceholder(),
    Object? allowBotToBot = const $CopyWithPlaceholder(),
    Object? llmTracing = const $CopyWithPlaceholder(),
  }) {
    return UpdateOrgSettingsRequest(
      runEventRetentionDays:
          runEventRetentionDays == const $CopyWithPlaceholder()
          ? _value.runEventRetentionDays
          // ignore: cast_nullable_to_non_nullable
          : runEventRetentionDays as int?,
      requireMfa: requireMfa == const $CopyWithPlaceholder()
          ? _value.requireMfa
          // ignore: cast_nullable_to_non_nullable
          : requireMfa as bool?,
      mcpDecideApprovals: mcpDecideApprovals == const $CopyWithPlaceholder()
          ? _value.mcpDecideApprovals
          // ignore: cast_nullable_to_non_nullable
          : mcpDecideApprovals as bool?,
      allowBotToBot: allowBotToBot == const $CopyWithPlaceholder()
          ? _value.allowBotToBot
          // ignore: cast_nullable_to_non_nullable
          : allowBotToBot as bool?,
      llmTracing: llmTracing == const $CopyWithPlaceholder()
          ? _value.llmTracing
          // ignore: cast_nullable_to_non_nullable
          : llmTracing as bool?,
    );
  }
}

extension $UpdateOrgSettingsRequestCopyWith on UpdateOrgSettingsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateOrgSettingsRequest.copyWith(...)` or `instanceOfUpdateOrgSettingsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateOrgSettingsRequestCWProxy get copyWith =>
      _$UpdateOrgSettingsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateOrgSettingsRequest _$UpdateOrgSettingsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateOrgSettingsRequest',
  json,
  ($checkedConvert) {
    final val = UpdateOrgSettingsRequest(
      runEventRetentionDays: $checkedConvert(
        'run_event_retention_days',
        (v) => (v as num?)?.toInt(),
      ),
      requireMfa: $checkedConvert('require_mfa', (v) => v as bool?),
      mcpDecideApprovals: $checkedConvert(
        'mcp_decide_approvals',
        (v) => v as bool?,
      ),
      allowBotToBot: $checkedConvert('allow_bot_to_bot', (v) => v as bool?),
      llmTracing: $checkedConvert('llm_tracing', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'runEventRetentionDays': 'run_event_retention_days',
    'requireMfa': 'require_mfa',
    'mcpDecideApprovals': 'mcp_decide_approvals',
    'allowBotToBot': 'allow_bot_to_bot',
    'llmTracing': 'llm_tracing',
  },
);

Map<String, dynamic> _$UpdateOrgSettingsRequestToJson(
  UpdateOrgSettingsRequest instance,
) => <String, dynamic>{
  'run_event_retention_days': ?instance.runEventRetentionDays,
  'require_mfa': ?instance.requireMfa,
  'mcp_decide_approvals': ?instance.mcpDecideApprovals,
  'allow_bot_to_bot': ?instance.allowBotToBot,
  'llm_tracing': ?instance.llmTracing,
};
