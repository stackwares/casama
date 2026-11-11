// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_device_readings_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadDeviceReadingsRequestCWProxy {
  UploadDeviceReadingsRequest readings(List<DeviceReadingInput> readings);

  UploadDeviceReadingsRequest requestId(String? requestId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadDeviceReadingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadDeviceReadingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UploadDeviceReadingsRequest call({
    List<DeviceReadingInput> readings,
    String? requestId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUploadDeviceReadingsRequest.copyWith(...)` or call `instanceOfUploadDeviceReadingsRequest.copyWith.fieldName(value)` for a single field.
class _$UploadDeviceReadingsRequestCWProxyImpl
    implements _$UploadDeviceReadingsRequestCWProxy {
  const _$UploadDeviceReadingsRequestCWProxyImpl(this._value);

  final UploadDeviceReadingsRequest _value;

  @override
  UploadDeviceReadingsRequest readings(List<DeviceReadingInput> readings) =>
      call(readings: readings);

  @override
  UploadDeviceReadingsRequest requestId(String? requestId) =>
      call(requestId: requestId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadDeviceReadingsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadDeviceReadingsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UploadDeviceReadingsRequest call({
    Object? readings = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
  }) {
    return UploadDeviceReadingsRequest(
      readings: readings == const $CopyWithPlaceholder() || readings == null
          ? _value.readings
          // ignore: cast_nullable_to_non_nullable
          : readings as List<DeviceReadingInput>,
      requestId: requestId == const $CopyWithPlaceholder()
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String?,
    );
  }
}

extension $UploadDeviceReadingsRequestCopyWith on UploadDeviceReadingsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUploadDeviceReadingsRequest.copyWith(...)` or `instanceOfUploadDeviceReadingsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadDeviceReadingsRequestCWProxy get copyWith =>
      _$UploadDeviceReadingsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadDeviceReadingsRequest _$UploadDeviceReadingsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UploadDeviceReadingsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['readings']);
  final val = UploadDeviceReadingsRequest(
    readings: $checkedConvert(
      'readings',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceReadingInput.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    requestId: $checkedConvert('request_id', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'requestId': 'request_id'});

Map<String, dynamic> _$UploadDeviceReadingsRequestToJson(
  UploadDeviceReadingsRequest instance,
) => <String, dynamic>{
  'readings': instance.readings.map((e) => e.toJson()).toList(),
  'request_id': ?instance.requestId,
};
