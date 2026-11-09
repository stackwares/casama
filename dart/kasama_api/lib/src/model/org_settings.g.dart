// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrgSettingsCWProxy {
  OrgSettings runEventRetentionDays(int runEventRetentionDays);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrgSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrgSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  OrgSettings call({int runEventRetentionDays});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOrgSettings.copyWith(...)` or call `instanceOfOrgSettings.copyWith.fieldName(value)` for a single field.
class _$OrgSettingsCWProxyImpl implements _$OrgSettingsCWProxy {
  const _$OrgSettingsCWProxyImpl(this._value);

  final OrgSettings _value;

  @override
  OrgSettings runEventRetentionDays(int runEventRetentionDays) =>
      call(runEventRetentionDays: runEventRetentionDays);

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
  }) {
    return OrgSettings(
      runEventRetentionDays:
          runEventRetentionDays == const $CopyWithPlaceholder() ||
              runEventRetentionDays == null
          ? _value.runEventRetentionDays
          // ignore: cast_nullable_to_non_nullable
          : runEventRetentionDays as int,
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
    $checkKeys(json, requiredKeys: const ['run_event_retention_days']);
    final val = OrgSettings(
      runEventRetentionDays: $checkedConvert(
        'run_event_retention_days',
        (v) => (v as num).toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'runEventRetentionDays': 'run_event_retention_days'},
);

Map<String, dynamic> _$OrgSettingsToJson(OrgSettings instance) =>
    <String, dynamic>{
      'run_event_retention_days': instance.runEventRetentionDays,
    };
