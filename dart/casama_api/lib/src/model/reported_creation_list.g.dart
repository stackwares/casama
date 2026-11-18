// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reported_creation_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReportedCreationListCWProxy {
  ReportedCreationList items(List<ReportedCreation> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportedCreationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportedCreationList(...).copyWith(id: 12, name: "My name")
  /// ```
  ReportedCreationList call({List<ReportedCreation> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReportedCreationList.copyWith(...)` or call `instanceOfReportedCreationList.copyWith.fieldName(value)` for a single field.
class _$ReportedCreationListCWProxyImpl
    implements _$ReportedCreationListCWProxy {
  const _$ReportedCreationListCWProxyImpl(this._value);

  final ReportedCreationList _value;

  @override
  ReportedCreationList items(List<ReportedCreation> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportedCreationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportedCreationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReportedCreationList call({Object? items = const $CopyWithPlaceholder()}) {
    return ReportedCreationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<ReportedCreation>,
    );
  }
}

extension $ReportedCreationListCopyWith on ReportedCreationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReportedCreationList.copyWith(...)` or `instanceOfReportedCreationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReportedCreationListCWProxy get copyWith =>
      _$ReportedCreationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportedCreationList _$ReportedCreationListFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ReportedCreationList', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ReportedCreationList(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => ReportedCreation.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ReportedCreationListToJson(
  ReportedCreationList instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
