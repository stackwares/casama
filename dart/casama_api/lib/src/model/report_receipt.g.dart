// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_receipt.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReportReceiptCWProxy {
  ReportReceipt id(String id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportReceipt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportReceipt(...).copyWith(id: 12, name: "My name")
  /// ```
  ReportReceipt call({String id});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReportReceipt.copyWith(...)` or call `instanceOfReportReceipt.copyWith.fieldName(value)` for a single field.
class _$ReportReceiptCWProxyImpl implements _$ReportReceiptCWProxy {
  const _$ReportReceiptCWProxyImpl(this._value);

  final ReportReceipt _value;

  @override
  ReportReceipt id(String id) => call(id: id);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportReceipt(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportReceipt(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReportReceipt call({Object? id = const $CopyWithPlaceholder()}) {
    return ReportReceipt(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
    );
  }
}

extension $ReportReceiptCopyWith on ReportReceipt {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReportReceipt.copyWith(...)` or `instanceOfReportReceipt.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReportReceiptCWProxy get copyWith => _$ReportReceiptCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportReceipt _$ReportReceiptFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReportReceipt', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id']);
      final val = ReportReceipt(id: $checkedConvert('id', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$ReportReceiptToJson(ReportReceipt instance) =>
    <String, dynamic>{'id': instance.id};
