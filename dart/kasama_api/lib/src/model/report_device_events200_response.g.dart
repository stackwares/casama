// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_device_events200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReportDeviceEvents200ResponseCWProxy {
  ReportDeviceEvents200Response accepted(int accepted);

  ReportDeviceEvents200Response runs(int runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportDeviceEvents200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportDeviceEvents200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ReportDeviceEvents200Response call({int accepted, int runs});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReportDeviceEvents200Response.copyWith(...)` or call `instanceOfReportDeviceEvents200Response.copyWith.fieldName(value)` for a single field.
class _$ReportDeviceEvents200ResponseCWProxyImpl
    implements _$ReportDeviceEvents200ResponseCWProxy {
  const _$ReportDeviceEvents200ResponseCWProxyImpl(this._value);

  final ReportDeviceEvents200Response _value;

  @override
  ReportDeviceEvents200Response accepted(int accepted) =>
      call(accepted: accepted);

  @override
  ReportDeviceEvents200Response runs(int runs) => call(runs: runs);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportDeviceEvents200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportDeviceEvents200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReportDeviceEvents200Response call({
    Object? accepted = const $CopyWithPlaceholder(),
    Object? runs = const $CopyWithPlaceholder(),
  }) {
    return ReportDeviceEvents200Response(
      accepted: accepted == const $CopyWithPlaceholder() || accepted == null
          ? _value.accepted
          // ignore: cast_nullable_to_non_nullable
          : accepted as int,
      runs: runs == const $CopyWithPlaceholder() || runs == null
          ? _value.runs
          // ignore: cast_nullable_to_non_nullable
          : runs as int,
    );
  }
}

extension $ReportDeviceEvents200ResponseCopyWith
    on ReportDeviceEvents200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReportDeviceEvents200Response.copyWith(...)` or `instanceOfReportDeviceEvents200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReportDeviceEvents200ResponseCWProxy get copyWith =>
      _$ReportDeviceEvents200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDeviceEvents200Response _$ReportDeviceEvents200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReportDeviceEvents200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['accepted', 'runs']);
  final val = ReportDeviceEvents200Response(
    accepted: $checkedConvert('accepted', (v) => (v as num).toInt()),
    runs: $checkedConvert('runs', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ReportDeviceEvents200ResponseToJson(
  ReportDeviceEvents200Response instance,
) => <String, dynamic>{'accepted': instance.accepted, 'runs': instance.runs};
