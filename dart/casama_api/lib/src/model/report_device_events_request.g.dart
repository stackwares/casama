// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_device_events_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReportDeviceEventsRequestCWProxy {
  ReportDeviceEventsRequest events(List<DeviceEventInput> events);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportDeviceEventsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportDeviceEventsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ReportDeviceEventsRequest call({List<DeviceEventInput> events});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReportDeviceEventsRequest.copyWith(...)` or call `instanceOfReportDeviceEventsRequest.copyWith.fieldName(value)` for a single field.
class _$ReportDeviceEventsRequestCWProxyImpl
    implements _$ReportDeviceEventsRequestCWProxy {
  const _$ReportDeviceEventsRequestCWProxyImpl(this._value);

  final ReportDeviceEventsRequest _value;

  @override
  ReportDeviceEventsRequest events(List<DeviceEventInput> events) =>
      call(events: events);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportDeviceEventsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportDeviceEventsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReportDeviceEventsRequest call({
    Object? events = const $CopyWithPlaceholder(),
  }) {
    return ReportDeviceEventsRequest(
      events: events == const $CopyWithPlaceholder() || events == null
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<DeviceEventInput>,
    );
  }
}

extension $ReportDeviceEventsRequestCopyWith on ReportDeviceEventsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReportDeviceEventsRequest.copyWith(...)` or `instanceOfReportDeviceEventsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReportDeviceEventsRequestCWProxy get copyWith =>
      _$ReportDeviceEventsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDeviceEventsRequest _$ReportDeviceEventsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReportDeviceEventsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['events']);
  final val = ReportDeviceEventsRequest(
    events: $checkedConvert(
      'events',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceEventInput.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ReportDeviceEventsRequestToJson(
  ReportDeviceEventsRequest instance,
) => <String, dynamic>{
  'events': instance.events.map((e) => e.toJson()).toList(),
};
