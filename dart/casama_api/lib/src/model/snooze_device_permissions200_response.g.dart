// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snooze_device_permissions200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SnoozeDevicePermissions200ResponseCWProxy {
  SnoozeDevicePermissions200Response until(DateTime until);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SnoozeDevicePermissions200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SnoozeDevicePermissions200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  SnoozeDevicePermissions200Response call({DateTime until});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSnoozeDevicePermissions200Response.copyWith(...)` or call `instanceOfSnoozeDevicePermissions200Response.copyWith.fieldName(value)` for a single field.
class _$SnoozeDevicePermissions200ResponseCWProxyImpl
    implements _$SnoozeDevicePermissions200ResponseCWProxy {
  const _$SnoozeDevicePermissions200ResponseCWProxyImpl(this._value);

  final SnoozeDevicePermissions200Response _value;

  @override
  SnoozeDevicePermissions200Response until(DateTime until) =>
      call(until: until);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SnoozeDevicePermissions200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SnoozeDevicePermissions200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SnoozeDevicePermissions200Response call({
    Object? until = const $CopyWithPlaceholder(),
  }) {
    return SnoozeDevicePermissions200Response(
      until: until == const $CopyWithPlaceholder() || until == null
          ? _value.until
          // ignore: cast_nullable_to_non_nullable
          : until as DateTime,
    );
  }
}

extension $SnoozeDevicePermissions200ResponseCopyWith
    on SnoozeDevicePermissions200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSnoozeDevicePermissions200Response.copyWith(...)` or `instanceOfSnoozeDevicePermissions200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SnoozeDevicePermissions200ResponseCWProxy get copyWith =>
      _$SnoozeDevicePermissions200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnoozeDevicePermissions200Response _$SnoozeDevicePermissions200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SnoozeDevicePermissions200Response', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['until']);
  final val = SnoozeDevicePermissions200Response(
    until: $checkedConvert('until', (v) => DateTime.parse(v as String)),
  );
  return val;
});

Map<String, dynamic> _$SnoozeDevicePermissions200ResponseToJson(
  SnoozeDevicePermissions200Response instance,
) => <String, dynamic>{'until': instance.until.toIso8601String()};
