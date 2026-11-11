// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_device_readings200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadDeviceReadings200ResponseCWProxy {
  UploadDeviceReadings200Response stored(int stored);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadDeviceReadings200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadDeviceReadings200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  UploadDeviceReadings200Response call({int stored});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUploadDeviceReadings200Response.copyWith(...)` or call `instanceOfUploadDeviceReadings200Response.copyWith.fieldName(value)` for a single field.
class _$UploadDeviceReadings200ResponseCWProxyImpl
    implements _$UploadDeviceReadings200ResponseCWProxy {
  const _$UploadDeviceReadings200ResponseCWProxyImpl(this._value);

  final UploadDeviceReadings200Response _value;

  @override
  UploadDeviceReadings200Response stored(int stored) => call(stored: stored);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadDeviceReadings200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadDeviceReadings200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UploadDeviceReadings200Response call({
    Object? stored = const $CopyWithPlaceholder(),
  }) {
    return UploadDeviceReadings200Response(
      stored: stored == const $CopyWithPlaceholder() || stored == null
          ? _value.stored
          // ignore: cast_nullable_to_non_nullable
          : stored as int,
    );
  }
}

extension $UploadDeviceReadings200ResponseCopyWith
    on UploadDeviceReadings200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUploadDeviceReadings200Response.copyWith(...)` or `instanceOfUploadDeviceReadings200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadDeviceReadings200ResponseCWProxy get copyWith =>
      _$UploadDeviceReadings200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadDeviceReadings200Response _$UploadDeviceReadings200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UploadDeviceReadings200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['stored']);
  final val = UploadDeviceReadings200Response(
    stored: $checkedConvert('stored', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$UploadDeviceReadings200ResponseToJson(
  UploadDeviceReadings200Response instance,
) => <String, dynamic>{'stored': instance.stored};
