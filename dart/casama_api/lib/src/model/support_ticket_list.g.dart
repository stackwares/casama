// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_ticket_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SupportTicketListCWProxy {
  SupportTicketList items(List<SupportTicketRow> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicketList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicketList(...).copyWith(id: 12, name: "My name")
  /// ```
  SupportTicketList call({List<SupportTicketRow> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSupportTicketList.copyWith(...)` or call `instanceOfSupportTicketList.copyWith.fieldName(value)` for a single field.
class _$SupportTicketListCWProxyImpl implements _$SupportTicketListCWProxy {
  const _$SupportTicketListCWProxyImpl(this._value);

  final SupportTicketList _value;

  @override
  SupportTicketList items(List<SupportTicketRow> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SupportTicketList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SupportTicketList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SupportTicketList call({Object? items = const $CopyWithPlaceholder()}) {
    return SupportTicketList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<SupportTicketRow>,
    );
  }
}

extension $SupportTicketListCopyWith on SupportTicketList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSupportTicketList.copyWith(...)` or `instanceOfSupportTicketList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SupportTicketListCWProxy get copyWith =>
      _$SupportTicketListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SupportTicketList _$SupportTicketListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SupportTicketList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SupportTicketList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => SupportTicketRow.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SupportTicketListToJson(SupportTicketList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
