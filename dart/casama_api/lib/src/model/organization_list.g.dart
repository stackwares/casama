// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrganizationListCWProxy {
  OrganizationList items(List<OrganizationWithRole> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrganizationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrganizationList(...).copyWith(id: 12, name: "My name")
  /// ```
  OrganizationList call({List<OrganizationWithRole> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOrganizationList.copyWith(...)` or call `instanceOfOrganizationList.copyWith.fieldName(value)` for a single field.
class _$OrganizationListCWProxyImpl implements _$OrganizationListCWProxy {
  const _$OrganizationListCWProxyImpl(this._value);

  final OrganizationList _value;

  @override
  OrganizationList items(List<OrganizationWithRole> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OrganizationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OrganizationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OrganizationList call({Object? items = const $CopyWithPlaceholder()}) {
    return OrganizationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<OrganizationWithRole>,
    );
  }
}

extension $OrganizationListCopyWith on OrganizationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOrganizationList.copyWith(...)` or `instanceOfOrganizationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OrganizationListCWProxy get copyWith => _$OrganizationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrganizationList _$OrganizationListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrganizationList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = OrganizationList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => OrganizationWithRole.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OrganizationListToJson(OrganizationList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
