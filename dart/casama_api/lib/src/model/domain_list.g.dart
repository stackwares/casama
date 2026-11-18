// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainListCWProxy {
  DomainList items(List<Domain> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainList(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainList call({List<Domain> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainList.copyWith(...)` or call `instanceOfDomainList.copyWith.fieldName(value)` for a single field.
class _$DomainListCWProxyImpl implements _$DomainListCWProxy {
  const _$DomainListCWProxyImpl(this._value);

  final DomainList _value;

  @override
  DomainList items(List<Domain> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainList call({Object? items = const $CopyWithPlaceholder()}) {
    return DomainList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Domain>,
    );
  }
}

extension $DomainListCopyWith on DomainList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainList.copyWith(...)` or `instanceOfDomainList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainListCWProxy get copyWith => _$DomainListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainList _$DomainListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DomainList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = DomainList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Domain.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DomainListToJson(DomainList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
