// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationListCWProxy {
  IntegrationList items(List<Integration> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntegrationList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntegrationList(...).copyWith(id: 12, name: "My name")
  /// ````
  IntegrationList call({List<Integration> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfIntegrationList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfIntegrationList.copyWith.fieldName(...)`
class _$IntegrationListCWProxyImpl implements _$IntegrationListCWProxy {
  const _$IntegrationListCWProxyImpl(this._value);

  final IntegrationList _value;

  @override
  IntegrationList items(List<Integration> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `IntegrationList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// IntegrationList(...).copyWith(id: 12, name: "My name")
  /// ````
  IntegrationList call({Object? items = const $CopyWithPlaceholder()}) {
    return IntegrationList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Integration>,
    );
  }
}

extension $IntegrationListCopyWith on IntegrationList {
  /// Returns a callable class that can be used as follows: `instanceOfIntegrationList.copyWith(...)` or like so:`instanceOfIntegrationList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$IntegrationListCWProxy get copyWith => _$IntegrationListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntegrationList _$IntegrationListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IntegrationList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = IntegrationList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Integration.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$IntegrationListToJson(IntegrationList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
