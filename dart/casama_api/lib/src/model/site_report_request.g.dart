// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_report_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteReportRequestCWProxy {
  SiteReportRequest address(String address);

  SiteReportRequest reason(String reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteReportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteReportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SiteReportRequest call({String address, String reason});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSiteReportRequest.copyWith(...)` or call `instanceOfSiteReportRequest.copyWith.fieldName(value)` for a single field.
class _$SiteReportRequestCWProxyImpl implements _$SiteReportRequestCWProxy {
  const _$SiteReportRequestCWProxyImpl(this._value);

  final SiteReportRequest _value;

  @override
  SiteReportRequest address(String address) => call(address: address);

  @override
  SiteReportRequest reason(String reason) => call(reason: reason);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteReportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteReportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SiteReportRequest call({
    Object? address = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
  }) {
    return SiteReportRequest(
      address: address == const $CopyWithPlaceholder() || address == null
          ? _value.address
          // ignore: cast_nullable_to_non_nullable
          : address as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
    );
  }
}

extension $SiteReportRequestCopyWith on SiteReportRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSiteReportRequest.copyWith(...)` or `instanceOfSiteReportRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteReportRequestCWProxy get copyWith =>
      _$SiteReportRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteReportRequest _$SiteReportRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteReportRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['address', 'reason']);
      final val = SiteReportRequest(
        address: $checkedConvert('address', (v) => v as String),
        reason: $checkedConvert('reason', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SiteReportRequestToJson(SiteReportRequest instance) =>
    <String, dynamic>{'address': instance.address, 'reason': instance.reason};
