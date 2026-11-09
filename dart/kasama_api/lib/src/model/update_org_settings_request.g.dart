// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_org_settings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateOrgSettingsRequestCWProxy {
  UpdateOrgSettingsRequest runEventRetentionDays(int? runEventRetentionDays);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateOrgSettingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateOrgSettingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateOrgSettingsRequest call({int? runEventRetentionDays});
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
  }) {
    return UpdateOrgSettingsRequest(
      runEventRetentionDays:
          runEventRetentionDays == const $CopyWithPlaceholder()
          ? _value.runEventRetentionDays
          // ignore: cast_nullable_to_non_nullable
          : runEventRetentionDays as int?,
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
) => $checkedCreate('UpdateOrgSettingsRequest', json, ($checkedConvert) {
  final val = UpdateOrgSettingsRequest(
    runEventRetentionDays: $checkedConvert(
      'run_event_retention_days',
      (v) => (v as num?)?.toInt(),
    ),
  );
  return val;
}, fieldKeyMap: const {'runEventRetentionDays': 'run_event_retention_days'});

Map<String, dynamic> _$UpdateOrgSettingsRequestToJson(
  UpdateOrgSettingsRequest instance,
) => <String, dynamic>{
  'run_event_retention_days': ?instance.runEventRetentionDays,
};
