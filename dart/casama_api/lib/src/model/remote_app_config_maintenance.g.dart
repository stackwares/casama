// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_app_config_maintenance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemoteAppConfigMaintenanceCWProxy {
  RemoteAppConfigMaintenance message(String message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigMaintenance(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigMaintenance(...).copyWith(id: 12, name: "My name")
  /// ```
  RemoteAppConfigMaintenance call({String message});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemoteAppConfigMaintenance.copyWith(...)` or call `instanceOfRemoteAppConfigMaintenance.copyWith.fieldName(value)` for a single field.
class _$RemoteAppConfigMaintenanceCWProxyImpl
    implements _$RemoteAppConfigMaintenanceCWProxy {
  const _$RemoteAppConfigMaintenanceCWProxyImpl(this._value);

  final RemoteAppConfigMaintenance _value;

  @override
  RemoteAppConfigMaintenance message(String message) => call(message: message);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigMaintenance(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigMaintenance(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemoteAppConfigMaintenance call({
    Object? message = const $CopyWithPlaceholder(),
  }) {
    return RemoteAppConfigMaintenance(
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
    );
  }
}

extension $RemoteAppConfigMaintenanceCopyWith on RemoteAppConfigMaintenance {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemoteAppConfigMaintenance.copyWith(...)` or `instanceOfRemoteAppConfigMaintenance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemoteAppConfigMaintenanceCWProxy get copyWith =>
      _$RemoteAppConfigMaintenanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAppConfigMaintenance _$RemoteAppConfigMaintenanceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RemoteAppConfigMaintenance', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['message']);
  final val = RemoteAppConfigMaintenance(
    message: $checkedConvert('message', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$RemoteAppConfigMaintenanceToJson(
  RemoteAppConfigMaintenance instance,
) => <String, dynamic>{'message': instance.message};
