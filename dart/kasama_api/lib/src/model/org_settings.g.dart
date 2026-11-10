// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrgSettingsCWProxy {
  OrgSettings runEventRetentionDays(int runEventRetentionDays);

  OrgSettings requireMfa(bool requireMfa);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrgSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrgSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  OrgSettings call({int runEventRetentionDays, bool requireMfa});
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
      requiredKeys: const ['run_event_retention_days', 'require_mfa'],
    );
    final val = OrgSettings(
      runEventRetentionDays: $checkedConvert(
        'run_event_retention_days',
        (v) => (v as num).toInt(),
      ),
      requireMfa: $checkedConvert('require_mfa', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'runEventRetentionDays': 'run_event_retention_days',
    'requireMfa': 'require_mfa',
  },
);

Map<String, dynamic> _$OrgSettingsToJson(OrgSettings instance) =>
    <String, dynamic>{
      'run_event_retention_days': instance.runEventRetentionDays,
      'require_mfa': instance.requireMfa,
    };
