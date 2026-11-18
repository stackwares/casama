// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_record_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DnsRecordListCWProxy {
  DnsRecordList items(List<DnsRecordItem> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordList(...).copyWith(id: 12, name: "My name")
  /// ```
  DnsRecordList call({List<DnsRecordItem> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDnsRecordList.copyWith(...)` or call `instanceOfDnsRecordList.copyWith.fieldName(value)` for a single field.
class _$DnsRecordListCWProxyImpl implements _$DnsRecordListCWProxy {
  const _$DnsRecordListCWProxyImpl(this._value);

  final DnsRecordList _value;

  @override
  DnsRecordList items(List<DnsRecordItem> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DnsRecordList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DnsRecordList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DnsRecordList call({Object? items = const $CopyWithPlaceholder()}) {
    return DnsRecordList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DnsRecordItem>,
    );
  }
}

extension $DnsRecordListCopyWith on DnsRecordList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDnsRecordList.copyWith(...)` or `instanceOfDnsRecordList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DnsRecordListCWProxy get copyWith => _$DnsRecordListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DnsRecordList _$DnsRecordListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DnsRecordList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = DnsRecordList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => DnsRecordItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DnsRecordListToJson(DnsRecordList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
