// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrgSettingsCWProxy {
  OrgSettings runEventRetentionDays(int runEventRetentionDays);

  OrgSettings requireMfa(bool requireMfa);

  OrgSettings mcpDecideApprovals(bool mcpDecideApprovals);

  OrgSettings allowBotToBot(bool allowBotToBot);

  OrgSettings a2aEnabled(bool a2aEnabled);

  OrgSettings llmTracing(bool llmTracing);

  OrgSettings analyticsOptOut(bool? analyticsOptOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrgSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrgSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  OrgSettings call({
    int runEventRetentionDays,
    bool requireMfa,
    bool mcpDecideApprovals,
    bool allowBotToBot,
    bool a2aEnabled,
    bool llmTracing,
    bool? analyticsOptOut,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOrgSettings.copyWith(...)` or call `instanceOfOrgSettings.copyWith.fieldName(value)` for a single field.
class _$OrgSettingsCWProxyImpl implements _$OrgSettingsCWProxy {
  const _$OrgSettingsCWProxyImpl(this._value);

  final OrgSettings _value;

  @override
  OrgSettings runEventRetentionDays(int runEventRetentionDays) =>
      call(runEventRetentionDays: runEventRetentionDays);

  @override
  OrgSettings requireMfa(bool requireMfa) => call(requireMfa: requireMfa);

  @override
  OrgSettings mcpDecideApprovals(bool mcpDecideApprovals) =>
      call(mcpDecideApprovals: mcpDecideApprovals);

  @override
  OrgSettings allowBotToBot(bool allowBotToBot) =>
      call(allowBotToBot: allowBotToBot);

  @override
  OrgSettings a2aEnabled(bool a2aEnabled) => call(a2aEnabled: a2aEnabled);

  @override
  OrgSettings llmTracing(bool llmTracing) => call(llmTracing: llmTracing);

  @override
  OrgSettings analyticsOptOut(bool? analyticsOptOut) =>
      call(analyticsOptOut: analyticsOptOut);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrgSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrgSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OrgSettings call({
    Object? runEventRetentionDays = const $CopyWithPlaceholder(),
    Object? requireMfa = const $CopyWithPlaceholder(),
    Object? mcpDecideApprovals = const $CopyWithPlaceholder(),
    Object? allowBotToBot = const $CopyWithPlaceholder(),
    Object? a2aEnabled = const $CopyWithPlaceholder(),
    Object? llmTracing = const $CopyWithPlaceholder(),
    Object? analyticsOptOut = const $CopyWithPlaceholder(),
  }) {
    return OrgSettings(
      runEventRetentionDays:
          runEventRetentionDays == const $CopyWithPlaceholder() ||
              runEventRetentionDays == null
          ? _value.runEventRetentionDays
          // ignore: cast_nullable_to_non_nullable
          : runEventRetentionDays as int,
      requireMfa:
          requireMfa == const $CopyWithPlaceholder() || requireMfa == null
          ? _value.requireMfa
          // ignore: cast_nullable_to_non_nullable
          : requireMfa as bool,
      mcpDecideApprovals:
          mcpDecideApprovals == const $CopyWithPlaceholder() ||
              mcpDecideApprovals == null
          ? _value.mcpDecideApprovals
          // ignore: cast_nullable_to_non_nullable
          : mcpDecideApprovals as bool,
      allowBotToBot:
          allowBotToBot == const $CopyWithPlaceholder() || allowBotToBot == null
          ? _value.allowBotToBot
          // ignore: cast_nullable_to_non_nullable
          : allowBotToBot as bool,
      a2aEnabled:
          a2aEnabled == const $CopyWithPlaceholder() || a2aEnabled == null
          ? _value.a2aEnabled
          // ignore: cast_nullable_to_non_nullable
          : a2aEnabled as bool,
      llmTracing:
          llmTracing == const $CopyWithPlaceholder() || llmTracing == null
          ? _value.llmTracing
          // ignore: cast_nullable_to_non_nullable
          : llmTracing as bool,
      analyticsOptOut: analyticsOptOut == const $CopyWithPlaceholder()
          ? _value.analyticsOptOut
          // ignore: cast_nullable_to_non_nullable
          : analyticsOptOut as bool?,
    );
  }
}

extension $OrgSettingsCopyWith on OrgSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOrgSettings.copyWith(...)` or `instanceOfOrgSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OrgSettingsCWProxy get copyWith => _$OrgSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrgSettings _$OrgSettingsFromJson(Map<String, dynamic> json) => $checkedCreate(
  'OrgSettings',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'run_event_retention_days',
        'require_mfa',
        'mcp_decide_approvals',
        'allow_bot_to_bot',
        'a2a_enabled',
        'llm_tracing',
      ],
    );
    final val = OrgSettings(
      runEventRetentionDays: $checkedConvert(
        'run_event_retention_days',
        (v) => (v as num).toInt(),
      ),
      requireMfa: $checkedConvert('require_mfa', (v) => v as bool),
      mcpDecideApprovals: $checkedConvert(
        'mcp_decide_approvals',
        (v) => v as bool,
      ),
      allowBotToBot: $checkedConvert('allow_bot_to_bot', (v) => v as bool),
      a2aEnabled: $checkedConvert('a2a_enabled', (v) => v as bool),
      llmTracing: $checkedConvert('llm_tracing', (v) => v as bool),
      analyticsOptOut: $checkedConvert('analytics_opt_out', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'runEventRetentionDays': 'run_event_retention_days',
    'requireMfa': 'require_mfa',
    'mcpDecideApprovals': 'mcp_decide_approvals',
    'allowBotToBot': 'allow_bot_to_bot',
    'a2aEnabled': 'a2a_enabled',
    'llmTracing': 'llm_tracing',
    'analyticsOptOut': 'analytics_opt_out',
  },
);

Map<String, dynamic> _$OrgSettingsToJson(OrgSettings instance) =>
    <String, dynamic>{
      'run_event_retention_days': instance.runEventRetentionDays,
      'require_mfa': instance.requireMfa,
      'mcp_decide_approvals': instance.mcpDecideApprovals,
      'allow_bot_to_bot': instance.allowBotToBot,
      'a2a_enabled': instance.a2aEnabled,
      'llm_tracing': instance.llmTracing,
      'analytics_opt_out': ?instance.analyticsOptOut,
    };
