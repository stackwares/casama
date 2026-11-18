// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_org_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateOrgSettingsRequestCWProxy {
  UpdateOrgSettingsRequest runEventRetentionDays(int? runEventRetentionDays);

  UpdateOrgSettingsRequest requireMfa(bool? requireMfa);

  UpdateOrgSettingsRequest requireAppLock(bool? requireAppLock);

  UpdateOrgSettingsRequest mcpDecideApprovals(bool? mcpDecideApprovals);

  UpdateOrgSettingsRequest fullAccess(bool? fullAccess);

  UpdateOrgSettingsRequest allowBotToBot(bool? allowBotToBot);

  UpdateOrgSettingsRequest a2aEnabled(bool? a2aEnabled);

  UpdateOrgSettingsRequest llmTracing(bool? llmTracing);

  UpdateOrgSettingsRequest analyticsOptOut(bool? analyticsOptOut);

  UpdateOrgSettingsRequest chromeExtension(bool? chromeExtension);

  UpdateOrgSettingsRequest chromeAct(bool? chromeAct);

  UpdateOrgSettingsRequest chromeBlockedSites(List<String>? chromeBlockedSites);

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
    bool? requireAppLock,
    bool? mcpDecideApprovals,
    bool? fullAccess,
    bool? allowBotToBot,
    bool? a2aEnabled,
    bool? llmTracing,
    bool? analyticsOptOut,
    bool? chromeExtension,
    bool? chromeAct,
    List<String>? chromeBlockedSites,
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
  UpdateOrgSettingsRequest requireAppLock(bool? requireAppLock) =>
      call(requireAppLock: requireAppLock);

  @override
  UpdateOrgSettingsRequest mcpDecideApprovals(bool? mcpDecideApprovals) =>
      call(mcpDecideApprovals: mcpDecideApprovals);

  @override
  UpdateOrgSettingsRequest fullAccess(bool? fullAccess) =>
      call(fullAccess: fullAccess);

  @override
  UpdateOrgSettingsRequest allowBotToBot(bool? allowBotToBot) =>
      call(allowBotToBot: allowBotToBot);

  @override
  UpdateOrgSettingsRequest a2aEnabled(bool? a2aEnabled) =>
      call(a2aEnabled: a2aEnabled);

  @override
  UpdateOrgSettingsRequest llmTracing(bool? llmTracing) =>
      call(llmTracing: llmTracing);

  @override
  UpdateOrgSettingsRequest analyticsOptOut(bool? analyticsOptOut) =>
      call(analyticsOptOut: analyticsOptOut);

  @override
  UpdateOrgSettingsRequest chromeExtension(bool? chromeExtension) =>
      call(chromeExtension: chromeExtension);

  @override
  UpdateOrgSettingsRequest chromeAct(bool? chromeAct) =>
      call(chromeAct: chromeAct);

  @override
  UpdateOrgSettingsRequest chromeBlockedSites(
    List<String>? chromeBlockedSites,
  ) => call(chromeBlockedSites: chromeBlockedSites);

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
    Object? requireAppLock = const $CopyWithPlaceholder(),
    Object? mcpDecideApprovals = const $CopyWithPlaceholder(),
    Object? fullAccess = const $CopyWithPlaceholder(),
    Object? allowBotToBot = const $CopyWithPlaceholder(),
    Object? a2aEnabled = const $CopyWithPlaceholder(),
    Object? llmTracing = const $CopyWithPlaceholder(),
    Object? analyticsOptOut = const $CopyWithPlaceholder(),
    Object? chromeExtension = const $CopyWithPlaceholder(),
    Object? chromeAct = const $CopyWithPlaceholder(),
    Object? chromeBlockedSites = const $CopyWithPlaceholder(),
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
      requireAppLock: requireAppLock == const $CopyWithPlaceholder()
          ? _value.requireAppLock
          // ignore: cast_nullable_to_non_nullable
          : requireAppLock as bool?,
      mcpDecideApprovals: mcpDecideApprovals == const $CopyWithPlaceholder()
          ? _value.mcpDecideApprovals
          // ignore: cast_nullable_to_non_nullable
          : mcpDecideApprovals as bool?,
      fullAccess: fullAccess == const $CopyWithPlaceholder()
          ? _value.fullAccess
          // ignore: cast_nullable_to_non_nullable
          : fullAccess as bool?,
      allowBotToBot: allowBotToBot == const $CopyWithPlaceholder()
          ? _value.allowBotToBot
          // ignore: cast_nullable_to_non_nullable
          : allowBotToBot as bool?,
      a2aEnabled: a2aEnabled == const $CopyWithPlaceholder()
          ? _value.a2aEnabled
          // ignore: cast_nullable_to_non_nullable
          : a2aEnabled as bool?,
      llmTracing: llmTracing == const $CopyWithPlaceholder()
          ? _value.llmTracing
          // ignore: cast_nullable_to_non_nullable
          : llmTracing as bool?,
      analyticsOptOut: analyticsOptOut == const $CopyWithPlaceholder()
          ? _value.analyticsOptOut
          // ignore: cast_nullable_to_non_nullable
          : analyticsOptOut as bool?,
      chromeExtension: chromeExtension == const $CopyWithPlaceholder()
          ? _value.chromeExtension
          // ignore: cast_nullable_to_non_nullable
          : chromeExtension as bool?,
      chromeAct: chromeAct == const $CopyWithPlaceholder()
          ? _value.chromeAct
          // ignore: cast_nullable_to_non_nullable
          : chromeAct as bool?,
      chromeBlockedSites: chromeBlockedSites == const $CopyWithPlaceholder()
          ? _value.chromeBlockedSites
          // ignore: cast_nullable_to_non_nullable
          : chromeBlockedSites as List<String>?,
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
      requireAppLock: $checkedConvert('require_app_lock', (v) => v as bool?),
      mcpDecideApprovals: $checkedConvert(
        'mcp_decide_approvals',
        (v) => v as bool?,
      ),
      fullAccess: $checkedConvert('full_access', (v) => v as bool?),
      allowBotToBot: $checkedConvert('allow_bot_to_bot', (v) => v as bool?),
      a2aEnabled: $checkedConvert('a2a_enabled', (v) => v as bool?),
      llmTracing: $checkedConvert('llm_tracing', (v) => v as bool?),
      analyticsOptOut: $checkedConvert('analytics_opt_out', (v) => v as bool?),
      chromeExtension: $checkedConvert('chrome_extension', (v) => v as bool?),
      chromeAct: $checkedConvert('chrome_act', (v) => v as bool?),
      chromeBlockedSites: $checkedConvert(
        'chrome_blocked_sites',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'runEventRetentionDays': 'run_event_retention_days',
    'requireMfa': 'require_mfa',
    'requireAppLock': 'require_app_lock',
    'mcpDecideApprovals': 'mcp_decide_approvals',
    'fullAccess': 'full_access',
    'allowBotToBot': 'allow_bot_to_bot',
    'a2aEnabled': 'a2a_enabled',
    'llmTracing': 'llm_tracing',
    'analyticsOptOut': 'analytics_opt_out',
    'chromeExtension': 'chrome_extension',
    'chromeAct': 'chrome_act',
    'chromeBlockedSites': 'chrome_blocked_sites',
  },
);

Map<String, dynamic> _$UpdateOrgSettingsRequestToJson(
  UpdateOrgSettingsRequest instance,
) => <String, dynamic>{
  'run_event_retention_days': ?instance.runEventRetentionDays,
  'require_mfa': ?instance.requireMfa,
  'require_app_lock': ?instance.requireAppLock,
  'mcp_decide_approvals': ?instance.mcpDecideApprovals,
  'full_access': ?instance.fullAccess,
  'allow_bot_to_bot': ?instance.allowBotToBot,
  'a2a_enabled': ?instance.a2aEnabled,
  'llm_tracing': ?instance.llmTracing,
  'analytics_opt_out': ?instance.analyticsOptOut,
  'chrome_extension': ?instance.chromeExtension,
  'chrome_act': ?instance.chromeAct,
  'chrome_blocked_sites': ?instance.chromeBlockedSites,
};
