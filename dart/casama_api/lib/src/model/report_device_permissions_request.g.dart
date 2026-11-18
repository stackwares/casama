// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_device_permissions_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReportDevicePermissionsRequestCWProxy {
  ReportDevicePermissionsRequest permissions(
    Map<String, OsPermissionState> permissions,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportDevicePermissionsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportDevicePermissionsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ReportDevicePermissionsRequest call({
    Map<String, OsPermissionState> permissions,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReportDevicePermissionsRequest.copyWith(...)` or call `instanceOfReportDevicePermissionsRequest.copyWith.fieldName(value)` for a single field.
class _$ReportDevicePermissionsRequestCWProxyImpl
    implements _$ReportDevicePermissionsRequestCWProxy {
  const _$ReportDevicePermissionsRequestCWProxyImpl(this._value);

  final ReportDevicePermissionsRequest _value;

  @override
  ReportDevicePermissionsRequest permissions(
    Map<String, OsPermissionState> permissions,
  ) => call(permissions: permissions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportDevicePermissionsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportDevicePermissionsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReportDevicePermissionsRequest call({
    Object? permissions = const $CopyWithPlaceholder(),
  }) {
    return ReportDevicePermissionsRequest(
      permissions:
          permissions == const $CopyWithPlaceholder() || permissions == null
          ? _value.permissions
          // ignore: cast_nullable_to_non_nullable
          : permissions as Map<String, OsPermissionState>,
    );
  }
}

extension $ReportDevicePermissionsRequestCopyWith
    on ReportDevicePermissionsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReportDevicePermissionsRequest.copyWith(...)` or `instanceOfReportDevicePermissionsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReportDevicePermissionsRequestCWProxy get copyWith =>
      _$ReportDevicePermissionsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDevicePermissionsRequest _$ReportDevicePermissionsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReportDevicePermissionsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['permissions']);
  final val = ReportDevicePermissionsRequest(
    permissions: $checkedConvert(
      'permissions',
      (v) => (v as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, $enumDecode(_$OsPermissionStateEnumMap, e)),
      ),
    ),
  );
  return val;
});

Map<String, dynamic> _$ReportDevicePermissionsRequestToJson(
  ReportDevicePermissionsRequest instance,
) => <String, dynamic>{
  'permissions': instance.permissions.map(
    (k, e) => MapEntry(k, _$OsPermissionStateEnumMap[e]!),
  ),
};

const _$OsPermissionStateEnumMap = {
  OsPermissionState.granted: 'granted',
  OsPermissionState.limited: 'limited',
  OsPermissionState.denied: 'denied',
  OsPermissionState.notAsked: 'not_asked',
  OsPermissionState.restricted: 'restricted',
  OsPermissionState.unknown: 'unknown',
  OsPermissionState.unavailable: 'unavailable',
};
