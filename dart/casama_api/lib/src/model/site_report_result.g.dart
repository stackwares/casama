// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_report_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteReportResultCWProxy {
  SiteReportResult ok(bool ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteReportResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteReportResult(...).copyWith(id: 12, name: "My name")
  /// ```
  SiteReportResult call({bool ok});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSiteReportResult.copyWith(...)` or call `instanceOfSiteReportResult.copyWith.fieldName(value)` for a single field.
class _$SiteReportResultCWProxyImpl implements _$SiteReportResultCWProxy {
  const _$SiteReportResultCWProxyImpl(this._value);

  final SiteReportResult _value;

  @override
  SiteReportResult ok(bool ok) => call(ok: ok);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteReportResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteReportResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SiteReportResult call({Object? ok = const $CopyWithPlaceholder()}) {
    return SiteReportResult(
      ok: ok == const $CopyWithPlaceholder() || ok == null
          ? _value.ok
          // ignore: cast_nullable_to_non_nullable
          : ok as bool,
    );
  }
}

extension $SiteReportResultCopyWith on SiteReportResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSiteReportResult.copyWith(...)` or `instanceOfSiteReportResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteReportResultCWProxy get copyWith => _$SiteReportResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteReportResult _$SiteReportResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteReportResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ok']);
      final val = SiteReportResult(ok: $checkedConvert('ok', (v) => v as bool));
      return val;
    });

Map<String, dynamic> _$SiteReportResultToJson(SiteReportResult instance) =>
    <String, dynamic>{'ok': instance.ok};
