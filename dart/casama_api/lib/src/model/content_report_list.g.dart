// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_report_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ContentReportListCWProxy {
  ContentReportList items(List<ContentReport> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ContentReportList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContentReportList(...).copyWith(id: 12, name: "My name")
  /// ```
  ContentReportList call({List<ContentReport> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfContentReportList.copyWith(...)` or call `instanceOfContentReportList.copyWith.fieldName(value)` for a single field.
class _$ContentReportListCWProxyImpl implements _$ContentReportListCWProxy {
  const _$ContentReportListCWProxyImpl(this._value);

  final ContentReportList _value;

  @override
  ContentReportList items(List<ContentReport> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ContentReportList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContentReportList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ContentReportList call({Object? items = const $CopyWithPlaceholder()}) {
    return ContentReportList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ContentReport>,
    );
  }
}

extension $ContentReportListCopyWith on ContentReportList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfContentReportList.copyWith(...)` or `instanceOfContentReportList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ContentReportListCWProxy get copyWith =>
      _$ContentReportListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentReportList _$ContentReportListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ContentReportList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ContentReportList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => ContentReport.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ContentReportListToJson(ContentReportList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
