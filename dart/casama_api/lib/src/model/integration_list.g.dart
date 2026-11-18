// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$IntegrationListCWProxy {
  IntegrationList items(List<Integration> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationList(...).copyWith(id: 12, name: "My name")
  /// ```
  IntegrationList call({List<Integration> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfIntegrationList.copyWith(...)` or call `instanceOfIntegrationList.copyWith.fieldName(value)` for a single field.
class _$IntegrationListCWProxyImpl implements _$IntegrationListCWProxy {
  const _$IntegrationListCWProxyImpl(this._value);

  final IntegrationList _value;

  @override
  IntegrationList items(List<Integration> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `IntegrationList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// IntegrationList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  IntegrationList call({Object? items = const $CopyWithPlaceholder()}) {
    return IntegrationList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Integration>,
    );
  }
}

extension $IntegrationListCopyWith on IntegrationList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfIntegrationList.copyWith(...)` or `instanceOfIntegrationList.copyWith.fieldName(...)`.
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
