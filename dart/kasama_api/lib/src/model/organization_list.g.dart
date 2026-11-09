// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OrganizationListCWProxy {
  OrganizationList items(List<OrganizationWithRole> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrganizationList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrganizationList(...).copyWith(id: 12, name: "My name")
  /// ````
  OrganizationList call({List<OrganizationWithRole> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfOrganizationList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfOrganizationList.copyWith.fieldName(...)`
class _$OrganizationListCWProxyImpl implements _$OrganizationListCWProxy {
  const _$OrganizationListCWProxyImpl(this._value);

  final OrganizationList _value;

  @override
  OrganizationList items(List<OrganizationWithRole> items) =>
      this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `OrganizationList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// OrganizationList(...).copyWith(id: 12, name: "My name")
  /// ````
  OrganizationList call({Object? items = const $CopyWithPlaceholder()}) {
    return OrganizationList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<OrganizationWithRole>,
    );
  }
}

extension $OrganizationListCopyWith on OrganizationList {
  /// Returns a callable class that can be used as follows: `instanceOfOrganizationList.copyWith(...)` or like so:`instanceOfOrganizationList.copyWith.fieldName(...)`.
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
